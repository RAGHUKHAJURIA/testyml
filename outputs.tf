output "staging_website_url" {
  description = "The public URL of the staging website via CloudFront."
  value       = "https://${aws_cloudfront_distribution.staging.aliases[0]}"
}

output "production_website_url" {
  description = "The public URL of the production website via CloudFront."
  value       = "https://${aws_cloudfront_distribution.production.aliases[0]}" # This would be https://example.com
}

output "staging_bucket_name" {
  description = "The name of the S3 bucket for the staging environment."
  value       = aws_s3_bucket.staging.id
}

output "production_bucket_name" {
  description = "The name of the S3 bucket for the production environment."
  value       = aws_s3_bucket.production.id
}

output "route53_name_servers" {
  description = "The name servers for the Route 53 hosted zone. These must be updated with your domain registrar to delegate DNS management to AWS."
  value       = aws_route53_zone.primary.name_servers
}

output "cloudfront_staging_domain_name" {
  description = "The CloudFront distribution domain name for the staging environment."
  value       = aws_cloudfront_distribution.staging.domain_name
}

output "cloudfront_production_domain_name" {
  description = "The CloudFront distribution domain name for the production environment."
  value       = aws_cloudfront_distribution.production.domain_name
}
