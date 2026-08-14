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
