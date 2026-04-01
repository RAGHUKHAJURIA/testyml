variable "aws_region" {
  description = "The AWS region to deploy regional resources into. Note: ACM certificates for CloudFront must be in us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "The primary domain name for the website (e.g., example.com)."
  type        = string
  validation {
    condition     = length(regex("^[a-zA-Z0-9.-]+\\.([a-zA-Z]{2,})$", var.domain_name)) > 0
    error_message = "The domain_name must be a valid domain format, e.g., 'example.com'."
  }
}

variable "project_name" {
  description = "A short identifier for the project, used for naming resources and tagging. Must be lowercase and alphanumeric (dashes allowed)."
  type        = string
  default     = "mywebapp"
  validation {
    condition     = length(regex("^[a-z0-9-]+$", var.project_name)) > 0
    error_message = "The project_name must be lowercase alphanumeric and may contain hyphens."
  }
}
