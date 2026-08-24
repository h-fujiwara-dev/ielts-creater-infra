# CognitoのCustom Email SenderトリガーからResend経由でメールを送信する（#00057）。
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# npm依存関係のインストール・esbuildによるバンドルをterraform apply時に実行する。
# ソース/package.jsonのハッシュが変わった場合のみ再実行する
resource "null_resource" "build" {
  triggers = {
    src_hash     = filesha256("${path.module}/lambda/src/index.ts")
    package_hash = filesha256("${path.module}/lambda/package.json")
  }

  provisioner "local-exec" {
    command     = "npm ci && npm run build"
    working_dir = "${path.module}/lambda"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/dist"
  output_path = "${path.module}/lambda/dist.zip"

  depends_on = [null_resource.build]
}

resource "aws_kms_key" "custom_email_sender" {
  description             = "Cognito Custom Email Sender用（確認コードの暗号化、#00057）"
  deletion_window_in_days = 7

  # デフォルトのキーポリシー（アカウントrootへのkms:*委譲）だけではCognitoサービスが
  # このキーを使えず、確認コードの暗号化に失敗して結果的にLambdaが一度も呼ばれない
  # （Cognitoは失敗を利用者に見せず、確認コード自体を送らないだけになる）。
  # Cognito Custom Email Sender公式ドキュメント通りcognito-idp.amazonaws.comへの
  # 明示的な許可を追加する。
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid       = "EnableIamUserPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCognitoUseOfKey"
        Effect    = "Allow"
        Principal = { Service = "cognito-idp.amazonaws.com" }
        Action = [
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:DescribeKey",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_kms_alias" "custom_email_sender" {
  name          = "alias/ielts-creater-${var.environment}-cognito-email-sender"
  target_key_id = aws_kms_key.custom_email_sender.key_id
}

# Resend APIキー本体はvar.resend_api_key（tfvars、gitignore対象）からのみ注入する
resource "aws_secretsmanager_secret" "resend_api_key" {
  name = "ielts-creater-${var.environment}-resend-api-key"
}

resource "aws_secretsmanager_secret_version" "resend_api_key" {
  secret_id     = aws_secretsmanager_secret.resend_api_key.id
  secret_string = var.resend_api_key
}

resource "aws_iam_role" "lambda" {
  name = "ielts-creater-${var.environment}-cognito-email-sender"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Cognitoから渡される確認コード（暗号文）の復号に必要
resource "aws_iam_role_policy" "lambda_kms" {
  name = "kms-decrypt"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["kms:Decrypt", "kms:DescribeKey"]
      Resource = aws_kms_key.custom_email_sender.arn
    }]
  })
}

# Resend APIキーをLambda設定に平文で持たせず、実行時にSecrets Managerから取得する（ECSのvalueFromパターンに準じた設計）
resource "aws_iam_role_policy" "lambda_secrets" {
  name = "resend-api-key-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = aws_secretsmanager_secret.resend_api_key.arn
    }]
  })
}

resource "aws_lambda_function" "custom_email_sender" {
  function_name = "ielts-creater-${var.environment}-cognito-email-sender"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 10

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      RESEND_API_KEY_SECRET_ARN = aws_secretsmanager_secret.resend_api_key.arn
      RESEND_FROM_EMAIL         = var.resend_from_email
      KMS_KEY_ARN               = aws_kms_key.custom_email_sender.arn
    }
  }
}

resource "aws_lambda_permission" "cognito_invoke" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.custom_email_sender.function_name
  principal     = "cognito-idp.amazonaws.com"

  # cognitoモジュールのUser Pool ARNを直接参照すると、cognitoモジュール側もこのモジュールの
  # lambda_arn/kms_key_arnを参照するため循環依存になる。同一AWSアカウント・リージョン内の
  # User Pool全体に絞ったワイルドカードARNにすることで依存を切る（本プロジェクトでは対象環境に
  # User Poolが1つのみのため実質的な絞り込み効果は変わらない）
  source_arn = "arn:aws:cognito-idp:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userpool/*"
}
