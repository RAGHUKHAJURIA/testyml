variable "mode" {
  description = "Deployment mode: 'image_only' (builds image), 'container_only' (runs existing image), or 'full' (builds and runs)."
  type        = string
  default     = "full"

  validation {
    condition     = contains(["image_only", "container_only", "full"], var.mode)
    error_message = "The 'mode' variable must be 'image_only', 'container_only', or 'full'."
  }
}

variable "image_name" {
  description = "The base name of the Docker image to build or use. If mode is 'container_only', this image must already exist (e.g., 'my-app:latest')."
  type        = string
  default     = "my-app"
}

variable "container_name" {
  description = "The name for the Docker container."
  type        = string
  default     = "my-app-container"
}

variable "container_port" {
  description = "The port exposed by the application inside the Docker container (matches Dockerfile EXPOSE)."
  type        = number
  default     = 8080
}

variable "host_port" {
  description = "The port on the host machine to map to the container's exposed port."
  type        = number
  default     = 8080
}

variable "dockerfile_path" {
  description = "The path to the Dockerfile relative to the Terraform root module."
  type        = string
  default     = "./Dockerfile"
}

variable "build_context_path" {
  description = "The path to the build context directory (e.g., './dist') relative to the Docker build context (usually the project root). Used for triggering image rebuilds."
  type        = string
  default     = "./dist"
}
