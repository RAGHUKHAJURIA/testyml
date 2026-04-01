output "staging_url" {
  description = "The public URL of the staging environment."
  value       = "https://staging.${var.domain_name}"
}

output "production_url" {
  description = "The public URL of the production environment."
  value       = "https://${var.domain_name}"
}

output "staging_cloudfront_domain" {
  description = "The domain name of the staging CloudFront distribution."
  value       = aws_cloudfront_distribution.staging.domain_name
}

output "production_cloudfront_domain" {
  description = "The domain name of the production CloudFront distribution."
  value       = aws_cloudfront_distribution.production.domain_name
}

output "s3_staging_bucket_name" {
  description = "The name of the S3 bucket for staging content."
  value       = aws_s3_bucket.staging.id
}

output "s3_production_bucket_name" {
  description = "The name of the S3 bucket for production content."
  value       = aws_s3_bucket.production.id
}

output "route53_zone_id" {
  description = "The ID of the Route 53 Hosted Zone for the primary domain."
  value       = aws_route53_zone.primary.zone_id
}

output "route53_name_servers" {
  description = "The name servers for the Route 53 Hosted Zone. These must be configured with your domain registrar."
  value       = aws_route53_zone.primary.name_servers
}
