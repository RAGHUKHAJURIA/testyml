variable "app_name" {
  description = "The name of the application."
  type        = string
  default     = "my-app"
}

variable "image_tag" {
  description = "Tag for the Docker image."
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "The internal port the application listens on inside the Docker container."
  type        = number
  default     = 8080
}

variable "staging_host_port" {
  description = "The host port to map to the staging container's internal port."
  type        = number
  default     = 8081 # Common practice to use different ports for local environments
}

variable "production_host_port" {
  description = "The host port to map to the production container's internal port."
  type        = number
  default     = 8080 # Standard HTTP port locally
}
