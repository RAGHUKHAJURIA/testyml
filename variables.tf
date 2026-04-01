# (Keep your existing content in variables.tf)

variable "image_tag" {
  description = "Docker image tag to deploy (e.g., ghcr.io/org/repo:sha-hash or ghcr.io/org/repo:latest)."
  type        = string
}