# IELTS Creator — Infra

[IELTS Creator](https://github.com/h-fujiwara-dev/ielts-creater)を支えるAWSインフラ（VPC, ECS Fargate, S3, Cognito等）のTerraformコード。データベースは[Supabase](https://supabase.com/)（マネージドPostgreSQL）、フロントエンドは[Vercel](https://vercel.com/)でホスティングするため、RDS・フロントエンド用ECSサービスはこのリポジトリの対象外（[#00037](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/tickets/00037_インフラ構成の見直し（Vercel_Supabase化）とREADME構成図の追加.md)）。

プロジェクト全体の概要・業務/システム要件・アーキテクチャ（AWS構成図含む）は[ielts-createrリポジトリ docs/システム要件定義書.md 8章](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/docs/システム要件定義書.md#8-アーキテクチャ)を参照してください。フロントエンドは[ielts-creater-frontend](https://github.com/h-fujiwara-dev/ielts-creater-frontend)、バックエンドは[ielts-creater-backend](https://github.com/h-fujiwara-dev/ielts-creater-backend)にあります。

## 現在の状況

[ielts-creater #00044](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/tickets/00044_backendのAWSインフラ構築とSupabase接続.md)でdev環境、[#00050](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/tickets/00050_本番環境のAWSインフラ構築とCICDパイプライン整備.md)でprod環境のAWSインフラ（VPC/ECS Fargate/API Gateway/S3/ECR等）を構築済みです。ALBは使わず、コスト最適化のためAPI Gateway（HTTP API）+ VPC Link + Cloud Map（ECS Service Discovery）でECSタスクへ直接ルーティングする構成を採用しています（同様にNAT GatewayではなくNAT Instance、ECS ServiceはFargate Spotを使用。dev/prod共通の方針）。

ブランチはTerraformの環境分離に合わせて`develop`=dev環境、`prd`=prod環境に対応しています（詳細は[CLAUDE.md](./CLAUDE.md)のブランチ戦略節を参照）。

backendのprod環境への継続的デプロイは、GitHub Actions（backendリポジトリの`.github/workflows/deploy-prod.yml`）から実行する。長期のAWS資格情報はGitHub Secretsに置かず、OIDC federationで`ielts-creater-prod-github-actions-deploy`IAM Role（このリポジトリの`envs/prod`で定義）を一時的に引き受ける方式（backendリポジトリの`main`ブランチのワークフローのみ許可）。

## ディレクトリ構成

```text
terraform/
├── bootstrap/     # tfstate用バックエンド（S3 + DynamoDB）+ GitHub Actions用OIDC IDプロバイダ ※構築済み・ローカルstate
├── modules/
│   ├── cognito/     # Cognito User Pool・App Client ※構築済み
│   ├── network/     # VPC, Public/Private Subnet x2AZ, NAT Instance, Cloud Map namespace ※構築済み
│   ├── ecr/         # backendイメージ用ECRリポジトリ ※構築済み
│   ├── s3/          # Listening音声用S3バケット ※構築済み
│   ├── ecs/         # ECS Cluster(Fargate Spot)・Service・Task Definition・Cloud Map登録 ※構築済み
│   ├── api-gateway/ # HTTP API + VPC Link + Cloud Map private integration（ALBの代わり） ※構築済み
│   └── email-sender/ # Custom Email Sender Lambda（Cognito確認コードメールをResend経由で送信、#00057） ※構築済み
│                     # 対象外: rds（DBはSupabase）, フロントエンド用ecs_service（Vercelでホスティング）
└── envs/
    ├── dev/     # 上記モジュールを呼び出し ※構築済み
    └── prod/    # 上記モジュールに加え、backend CI/CD用のOIDC IAM Roleを定義 ※構築済み
```

## Cognito User Poolの構築手順（dev環境）

1. tfstateバックエンドを構築する（初回のみ、ローカルstateでapply）

   ```sh
   cd terraform/bootstrap
   cp terraform.tfvars.example terraform.tfvars  # state_bucket_nameを一意な値に変更
   terraform init
   terraform plan
   terraform apply
   ```

2. `envs/dev`をbootstrapのS3+DynamoDBに接続してCognitoを構築する

   ```sh
   cd ../envs/dev
   cp terraform.tfvars.example terraform.tfvars  # 必要に応じて値を調整
   terraform init \
     -backend-config="bucket=<bootstrap output: state_bucket_name>" \
     -backend-config="dynamodb_table=<bootstrap output: lock_table_name>" \
     -backend-config="region=<bootstrap output: aws_region>"
   terraform plan
   terraform apply
   ```

3. `terraform output`で取得した`user_pool_id` / `user_pool_client_id` / `user_pool_client_secret` / `issuer_url`を、backend（`ielts-creater-backend`）・frontend（`ielts-creater-frontend`）の環境変数に設定する

## backend AWSインフラの構築手順（dev環境）

Cognito構築後、network/ecr/s3/ecs/api-gatewayモジュールを2段階でapplyする（ECSタスク定義が参照するECRイメージを先にpushする必要があるため）。

1. `terraform.tfvars`にSupabase接続情報（`supabase_db_url`/`supabase_db_username`/`supabase_db_password`）とOpenAI APIキー（`openai_api_key`）を設定する（`terraform.tfvars.example`参照。Supabaseプロジェクトは事前にユーザーが作成しておく）

2. NAT Instance/ECR/S3のみ先行構築する

   ```sh
   cd terraform/envs/dev
   terraform init  # bootstrap outputsを-backend-configで渡す（前節参照）
   terraform apply -target=module.network -target=module.ecr -target=module.s3
   ```

3. `ielts-creater-backend`でbackendイメージをビルドし、上記で作成したECRへpushする

   ```sh
   cd ../ielts-creater-backend
   aws ecr get-login-password --region ap-northeast-1 | \
     docker login --username AWS --password-stdin <terraform output: ecr_repository_url の アカウントID.dkr.ecr.ap-northeast-1.amazonaws.com>
   docker build -t <ecr_repository_url>:latest .
   docker push <ecr_repository_url>:latest
   ```

4. 残り（ecs, api-gateway, Secrets Manager等）を含めて全体をapplyする

   ```sh
   cd ../ielts-creater-infra/terraform/envs/dev
   terraform apply
   ```

5. `terraform output api_endpoint`で取得したURLに対して疎通確認する

   ```sh
   curl https://<api_endpoint>/actuator/health
   ```

NAT Instance・ECS Fargate Spot・API Gateway（ALBの代わり）でdev環境の月額コストを抑えている（詳細は[ielts-creater #00044](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/tickets/00044_backendのAWSインフラ構築とSupabase接続.md)作業ログ参照）。動作確認後に不要であれば`terraform destroy`でリソースを落とせる。

## prod環境の構築手順

dev環境と同じ手順を`envs/prod`に対して行う（モジュール構成は共通）。差分は以下のとおり。

1. bootstrapは`envs/dev`と共用（同じS3+DynamoDB）。ただしbootstrapにGitHub Actions用のOIDC IDプロバイダを追加したため、既存のbootstrap環境では`cd terraform/bootstrap && terraform apply`を再実行してプロバイダを作成しておく（AWSアカウントに1つしか作れないため、既に存在する場合はこの手順は不要）
2. Supabaseは**dev用とは別にprod専用プロジェクト**を作成し、その接続情報を`envs/prod/terraform.tfvars`に設定する（データを完全分離するため）
3. `envs/prod/terraform.tfvars`の`callback_urls`/`logout_urls`/`cors_allowed_origins`は本番ドメイン（`band-eight.com`、[ielts-creater #00051](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/tickets/00051_frontendとbackendの本番環境への初回デプロイ.md)参照）を前提としたデフォルト値になっている
4. `terraform init`の`-backend-config`は同じbootstrap出力を使うが、`key`は`envs/prod/terraform.tfstate`（`versions.tf`で固定済み、stateはdevと分離される）
5. `terraform apply`完了後、`terraform output ecs_cluster_name` / `ecs_service_name` / `ecr_repository_url` / `github_actions_deploy_role_arn`をbackendリポジトリのCI/CDワークフロー（`.github/workflows/deploy-prod.yml`）の設定に反映する

## backend CI/CDのAWS認証（OIDC）

backendの`main`ブランチへのマージをトリガーに、GitHub Actionsが以下を行う（`ielts-creater-backend`の`.github/workflows/deploy-prod.yml`）。

1. `aws-actions/configure-aws-credentials`でOIDCトークンを使い`ielts-creater-prod-github-actions-deploy`IAM Role（`envs/prod`の`aws_iam_role.github_actions_deploy`）を一時的に引き受ける
2. Dockerイメージをビルドし、prod用ECRへpush
3. 新しいイメージタグでECSタスク定義の新リビジョンを登録し、ECSサービスを更新（`force-new-deployment`）

IAM Roleの信頼関係は`repo:h-fujiwara-dev/ielts-creater-backend:ref:refs/heads/main`のみを許可しており、他ブランチ・他リポジトリからは引き受けられない。長期のAWS Access Keyは一切使用しない。
