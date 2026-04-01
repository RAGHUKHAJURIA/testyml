provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1" # ACM certificates for CloudFront must be in us-east-1
}

# 1. AWS Route 53 Hosted Zone
# This resource assumes you manage the domain 'example.com' with Route 53.
# If you already have a hosted zone, you can use a `data` source instead:
# data "aws_route53_zone" "primary" {
#   name = var.domain_name
# }
resource "aws_route53_zone" "primary" {
  name    = var.domain_name
  comment = "Managed by Terraform for ${var.domain_name}"
}

# 2. AWS Certificate Manager (ACM) Certificate for CloudFront
# A wildcard certificate is provisioned in us-east-1 (required by CloudFront).
resource "aws_acm_certificate" "wildcard" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true # Allows new certificate to be created before old one is destroyed
  }
}

# DNS records for ACM certificate validation
resource "aws_route53_record" "wildcard_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

# Wait for ACM certificate validation to complete
resource "aws_acm_certificate_validation" "wildcard" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [for record in aws_route53_record.wildcard_validation : record.fqdn]
}

# 3. AWS S3 Buckets for Staging and Production Artifacts
# These buckets will store the static website content.

resource "aws_s3_bucket" "staging" {
  bucket = "${var.environment_names.staging}.${var.domain_name}"
  tags = {
    Environment = var.environment_names.staging
    Project     = var.project_name
  }
}

resource "aws_s3_bucket" "production" {
  bucket = var.domain_name # Commonly, the root domain for production
  tags = {
    Environment = var.environment_names.production
    Project     = var.project_name
  }
}

# S3 bucket ownership controls are recommended for CloudFront OAC
resource "aws_s3_bucket_ownership_controls" "staging_ownership" {
  bucket = aws_s3_bucket.staging.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_ownership_controls" "production_ownership" {
  bucket = aws_s3_bucket.production.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Block public access to S3 buckets (CloudFront OAC will provide secure access)
resource "aws_s3_bucket_public_access_block" "staging_block" {
  bucket = aws_s3_bucket.staging.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "production_block" {
  bucket = aws_s3_bucket.production.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Controls (OAC) for secure S3 bucket access
resource "aws_cloudfront_origin_access_control" "staging_oac" {
  name                              = "${var.project_name}-${var.environment_names.staging}-oac"
  description                       = "OAC for ${var.environment_names.staging} S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "production_oac" {
  name                              = "${var.project_name}-${var.environment_names.production}-oac"
  description                       = "OAC for ${var.environment_names.production} S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# IAM Policy Document to allow CloudFront OAC access to S3 buckets
data "aws_iam_policy_document" "staging_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.staging.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "cloudfront:SourceArn"
      values   = [aws_cloudfront_distribution.staging.arn]
    }
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.staging.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "cloudfront:SourceArn"
      values   = [aws_cloudfront_distribution.staging.arn]
    }
  }
}

data "aws_iam_policy_document" "production_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.production.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "cloudfront:SourceArn"
      values   = [aws_cloudfront_distribution.production.arn]
    }
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.production.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "cloudfront:SourceArn"
      values   = [aws_cloudfront_distribution.production.arn]
    }
  }
}

# Apply the generated bucket policies
resource "aws_s3_bucket_policy" "staging_policy" {
  bucket = aws_s3_bucket.staging.id
  policy = data.aws_iam_policy_document.staging_s3_policy.json
}

resource "aws_s3_bucket_policy" "production_policy" {
  bucket = aws_s3_bucket.production.id
  policy = data.aws_iam_policy_document.production_s3_policy.json
}

# 4. AWS CloudFront Distributions for Staging and Production
# These distribute content globally and provide HTTPS via the ACM certificate.

resource "aws_cloudfront_distribution" "staging" {
  origin {
    domain_name              = aws_s3_bucket.staging.bucket_regional_domain_name
    origin_id                = "s3_staging_origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.staging_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.environment_names.staging} environment (${var.environment_names.staging}.${var.domain_name})"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "s3_staging_origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = true
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
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate_validation.wildcard.certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  aliases = ["${var.environment_names.staging}.${var.domain_name}"]

  tags = {
    Environment = var.environment_names.staging
    Project     = var.project_name
  }
}

resource "aws_cloudfront_distribution" "production" {
  origin {
    domain_name              = aws_s3_bucket.production.bucket_regional_domain_name
    origin_id                = "s3_production_origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.production_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.environment_names.production} environment (${var.domain_name})"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "s3_production_origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = true
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
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate_validation.wildcard.certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  aliases = [var.domain_name, "www.${var.domain_name}"] # Assuming www subdomain is also used for production

  tags = {
    Environment = var.environment_names.production
    Project     = var.project_name
  }
}

# 5. AWS Route 53 Alias Records for CloudFront Distributions
# These map your custom domain names to the CloudFront distribution URLs.

resource "aws_route53_record" "staging_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "${var.environment_names.staging}.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.staging.domain_name
    zone_id                = aws_cloudfront_distribution.staging.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "production_alias_root" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.production.domain_name
    zone_id                = aws_cloudfront_distribution.production.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "production_alias_www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.production.domain_name
    zone_id                = aws_cloudfront_distribution.production.hosted_zone_id
    evaluate_target_health = false
  }
}
