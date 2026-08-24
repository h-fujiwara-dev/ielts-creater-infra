output "lambda_arn" {
  description = "Custom Email Sender LambdaのARN（cognitoモジュールのlambda_configに渡す）"
  value       = aws_lambda_function.custom_email_sender.arn
}

output "kms_key_arn" {
  description = "Custom Email Sender用KMSキーのARN（cognitoモジュールのlambda_configに渡す）"
  value       = aws_kms_key.custom_email_sender.arn
}
