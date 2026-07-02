# Values the deploy pipeline needs (surface them as CI variables / secrets).

output "bucket_name" {
  description = "S3 origin bucket to sync the built site into."
  value       = aws_s3_bucket.site.bucket
}

output "distribution_id" {
  description = "CloudFront distribution id (for cache invalidation)."
  value       = aws_cloudfront_distribution.site.id
}

output "distribution_domain_name" {
  description = "CloudFront domain; point the DNS alias here if managing DNS externally."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "deploy_role_arn" {
  description = "IAM role ARN for GitHub Actions to assume via OIDC."
  value       = aws_iam_role.deploy.arn
}

output "site_url" {
  description = "Public URL once DNS + cert are in place."
  value       = "https://${var.domain_name}/"
}
