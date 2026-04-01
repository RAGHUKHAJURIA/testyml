terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # The S3 backend configuration. For the *initial* `terraform apply` to create
  # the backend S3 bucket and DynamoDB table defined below, this 'backend' block
  # should be temporarily commented out. After the initial apply creates them,
  # uncomment this block and run `terraform init -migrate-state` to migrate
  # your state to the remote backend. Subsequent operations can then use this.
  backend "s3" {
    bucket         = "tf-state-${var.project_name}-${data.aws_caller_identity.current.account_id}"
    key            = "static-website/terraform.tfstate"
    region         = var.aws_region
    encrypt        = true
    dynamodb_table = "tf-state-lock-${var.project_name}"
  }
}

# Main AWS Provider configuration for regional resources
provider "aws" {
  region = var.aws_region
}

# AWS Provider configuration specifically for us-east-1, required for ACM certificates used with CloudFront
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# Random ID for unique bucket names, preventing conflicts
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# =====================================
# Terraform State Management Backend Resources
# These resources facilitate storing Terraform state in S3 and locking it with DynamoDB.
# =====================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = "tf-state-${var.project_name}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-terraform-state"
    Environment = "Infrastructure"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "tf-state-lock-${var.project_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-terraform-state-lock"
    Environment = "Infrastructure"
  }
}

# =====================================
# Domain & Certificate Management
# =====================================

# Route 53 Hosted Zone for the primary domain
# Assumes you already own and have configured the domain's NS records to point to AWS Route 53.
resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

# ACM Certificate for the primary domain and a wildcard subdomain
# CloudFront requires certificates to be provisioned in us-east-1 (N. Virginia).
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  provider                  = aws.us-east-1 # Explicitly use us-east-1 provider

  lifecycle {
    create_before_destroy = true
  }
}

# DNS Validation records for the ACM certificate using Route 53
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      type    = dvo.resource_record_type
      records = [dvo.resource_record_value]
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id
  ttl             = 60
  records         = each.value.records
}

# ACM Certificate Validation to confirm ownership of the domain
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
  provider                = aws.us-east-1 # Explicitly use us-east-1 provider
}

# =====================================
# Staging Environment Resources
# =====================================

# S3 Bucket for Staging Static Website Content
resource "aws_s3_bucket" "staging" {
  bucket = "${var.project_name}-staging-content-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-staging-content"
    Environment = "Staging"
  }
}

# Block all public access to the S3 bucket to prevent direct access
resource "aws_s3_bucket_public_access_block" "staging" {
  bucket                  = aws_s3_bucket.staging.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin Access Control (OAC) for CloudFront to securely access the S3 bucket
resource "aws_cloudfront_origin_access_control" "staging" {
  name                              = "${var.project_name}-staging-oac"
  description                       = "OAC for ${var.project_name} staging bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# S3 Bucket Policy to allow CloudFront OAC to read objects from the bucket
data "aws_iam_policy_document" "staging_oac_s3_policy" {
  statement {
    sid       = "AllowCloudFrontOAC"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.staging.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_origin_access_control.staging.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "staging" {
  bucket = aws_s3_bucket.staging.id
  policy = data.aws_iam_policy_document.staging_oac_s3_policy.json
}

# CloudFront Distribution for Staging Environment
resource "aws_cloudfront_distribution" "staging" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name} staging website"
  price_class         = "PriceClass_100" # For lower cost, restrict to US and Europe
  retain_on_delete    = false # Set to true to prevent accidental deletion, but keep false for development cleanup

  origin {
    domain_name              = aws_s3_bucket.staging.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.staging.id
    origin_access_control_id = aws_cloudfront_origin_access_control.staging.id
  }

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.staging.id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true
    default_ttl            = 3600
    max_ttl                = 86400
    min_ttl                = 0

    forwarded_values {
      query_string = false
      headers      = [] # Forward no headers by default for aggressive caching
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.main.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = ["staging.${var.domain_name}"]

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  tags = {
    Name        = "${var.project_name}-staging-cdn"
    Environment = "Staging"
  }
}

# Route 53 A Record for Staging Domain, pointing to CloudFront
resource "aws_route53_record" "staging" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "staging.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.staging.domain_name
    zone_id                = aws_cloudfront_distribution.staging.hosted_zone_id
    evaluate_target_health = false
  }
}

# =====================================
# Production Environment Resources
# =====================================

# S3 Bucket for Production Static Website Content
resource "aws_s3_bucket" "production" {
  bucket = "${var.project_name}-production-content-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-production-content"
    Environment = "Production"
  }
}

# Block all public access to the S3 bucket to prevent direct access
resource "aws_s3_bucket_public_access_block" "production" {
  bucket                  = aws_s3_bucket.production.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin Access Control (OAC) for CloudFront to securely access the S3 bucket
resource "aws_cloudfront_origin_access_control" "production" {
  name                              = "${var.project_name}-production-oac"
  description                       = "OAC for ${var.project_name} production bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# S3 Bucket Policy to allow CloudFront OAC to read objects from the bucket
data "aws_iam_policy_document" "production_oac_s3_policy" {
  statement {
    sid       = "AllowCloudFrontOAC"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.production.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_origin_access_control.production.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "production" {
  bucket = aws_s3_bucket.production.id
  policy = data.aws_iam_policy_document.production_oac_s3_policy.json
}

# CloudFront Distribution for Production Environment
resource "aws_cloudfront_distribution" "production" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name} production website"
  price_class         = "PriceClass_100"
  retain_on_delete    = false

  origin {
    domain_name              = aws_s3_bucket.production.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.production.id
    origin_access_control_id = aws_cloudfront_origin_access_control.production.id
  }

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.production.id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true
    default_ttl            = 3600
    max_ttl                = 86400
    min_ttl                = 0

    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.main.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = [var.domain_name, "www.${var.domain_name}"] # Base domain and www

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  tags = {
    Name        = "${var.project_name}-production-cdn"
    Environment = "Production"
  }
}

# Route 53 A Records for Production Domains, pointing to CloudFront
resource "aws_route53_record" "production_www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.production.domain_name
    zone_id                = aws_cloudfront_distribution.production.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "production_root" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.production.domain_name
    zone_id                = aws_cloudfront_distribution.production.hosted_zone_id
    evaluate_target_health = false
  }
}
