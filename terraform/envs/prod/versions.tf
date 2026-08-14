terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # bootstrap（terraform/bootstrap）で作成したS3+DynamoDBを使うリモートバックエンド。
  # bucket/dynamodb_table/regionはアカウント固有のためコード上にハードコードせず、
  # 以下のように -backend-config で渡す（README参照）:
  #   terraform init \
  #     -backend-config="bucket=<bootstrap output: state_bucket_name>" \
  #     -backend-config="dynamodb_table=<bootstrap output: lock_table_name>" \
  #     -backend-config="region=<bootstrap output: aws_region>"
  backend "s3" {
    key     = "envs/prod/terraform.tfstate"
    encrypt = true
  }
}
