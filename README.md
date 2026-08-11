# IELTS Creator — Infra

[IELTS Creator](https://github.com/h-fujiwara-dev/ielts-creater)を支えるAWSインフラ（VPC, ECS Fargate, RDS, S3, Cognito等）のTerraformコード。

プロジェクト全体の概要・業務/システム要件・アーキテクチャ（AWS構成図含む）は[ielts-createrリポジトリ docs/システム要件定義書.md 8章](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/docs/システム要件定義書.md#8-アーキテクチャ)を参照してください。フロントエンドは[ielts-creater-frontend](https://github.com/h-fujiwara-dev/ielts-creater-frontend)、バックエンドは[ielts-creater-backend](https://github.com/h-fujiwara-dev/ielts-creater-backend)にあります。

## 現在の状況

インフラ構築は[ロードマップ](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/docs/ロードマップ.md)上のPhase 3で着手予定です。Phase 1/2はAWSを使わずローカルで開発を進めますが、Cognito認証本実装（[ielts-createrリポジトリ #00034](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/tickets/00034_Cognito認証の本実装.md)）に伴い、tfstateバックエンドとCognito User Poolのみ前倒しで構築済みです。それ以外（network, ecs, rds等）は引き続きPhase 3で構築します。

## ディレクトリ構成

```text
terraform/
├── bootstrap/   # tfstate用バックエンド（S3 + DynamoDB）※構築済み・ローカルstate
├── modules/
│   └── cognito/ # Cognito User Pool・App Client ※構築済み
│                # 未構築: network, security, alb, ecs_cluster, ecs_service, rds, s3, ecr, iam, observability
└── envs/
    ├── dev/     # cognitoモジュールを呼び出し ※構築済み
    └── prod/    # 未構築
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
