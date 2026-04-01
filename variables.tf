variable "aws_region" {
  description = "The AWS region to deploy most resources in. CloudFront and ACM certs are global/us-east-1."
  type        = string
  default     = "eu-west-1" # Set a common default, e.g., 'us-east-1', 'eu-west-1', etc.
}

variable "project_name" {
  description = "A unique name for the project, used for tagging and resource naming conventions."
  type        = string
  default     = "MyWebApp"
}

variable "domain_name" {
  description = "The primary domain name for the application (e.g., example.com). IMPORTANT: Replace with your actual domain."
  type        = string
  default     = "example.com" # CHANGE THIS TO YOUR ACTUAL DOMAIN
}

variable "environment_names" {
  description = "Map of environment names to use for resource naming (e.g., staging.example.com)."
  type = object({
    staging    = string
    production = string
  })
  default = {
    staging    = "staging"
    production = "production" # This will be associated with the root domain or www subdomain
  }
}
