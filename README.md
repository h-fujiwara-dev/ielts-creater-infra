# IELTS Creator — Infra

[IELTS Creator](https://github.com/h-fujiwara-dev/ielts-creater)を支えるAWSインフラ（VPC, ECS Fargate, RDS, S3, Cognito等）のTerraformコード。

プロジェクト全体の概要・業務/システム要件・アーキテクチャ（AWS構成図含む）は[ielts-createrリポジトリ docs/システム要件定義書.md 8章](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/docs/システム要件定義書.md#8-アーキテクチャ)を参照してください。フロントエンドは[ielts-creater-frontend](https://github.com/h-fujiwara-dev/ielts-creater-frontend)、バックエンドは[ielts-creater-backend](https://github.com/h-fujiwara-dev/ielts-creater-backend)にあります。

## 現在の状況

インフラ構築は[ロードマップ](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/docs/ロードマップ.md)上のPhase 3で着手予定です。Phase 1/2はAWSを使わずローカルで開発を進めます。以下は構築予定のディレクトリ構成です。

## 構築予定のディレクトリ構成

```text
terraform/
├── bootstrap/   # tfstate用バックエンド（S3 + DynamoDB）
├── modules/     # network, security, alb, ecs_cluster, ecs_service, rds, s3, cognito, ecr, iam, observability
└── envs/
    ├── dev/
    └── prod/
```
