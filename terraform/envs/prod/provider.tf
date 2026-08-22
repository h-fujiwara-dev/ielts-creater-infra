provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ielts-creater"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

# Cognito Hosted UIのカスタムドメインはCloudFront経由のため、ACM証明書はUser Poolの
# リージョンに関わらずus-east-1に作成する必要がある（AWSの既知の制約）
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "ielts-creater"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
