variable "mode" {
  description = "Deployment mode: 'image_only' (builds image), 'container_only' (runs existing image), or 'full' (builds and runs)."
  type        = string
  default     = "full"
  validation {
    condition     = contains(["image_only", "container_only", "full"], var.mode)
    error_message = "The 'mode' variable must be one of 'image_only', 'container_only', or 'full'."
  }
}

variable "app_name" {
  description = "The base name for the application image and container."
  type        = string
  default     = "my-node-web-app"
}

variable "app_image_tag" {
  description = "The tag for the Docker image when built."
  type        = string
  default     = "latest"
}

variable "pre_built_image_full_name" {
  description = "The full name (including tag) of a pre-built Docker image to use when mode is 'container_only'."
  type        = string
  default     = "my-node-web-app:latest" # Example: Must exist in your Docker daemon or a configured registry.
}

variable "container_port" {
  description = "The internal port on which the application runs inside the container (from Dockerfile EXPOSE)."
  type        = number
  default     = 8080
}

variable "host_port" {
  description = "The port on the host machine to map to the container's internal port."
  type        = number
  default     = 80
}

variable "build_context" {
  description = "The path to the Docker build context (directory containing Dockerfile and './dist')."
  type        = string
  default     = "."
}
