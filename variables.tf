variable "mode" {
  description = "Deployment mode: 'image_only' (builds image), 'container_only' (runs existing image), or 'full' (builds and runs)."
  type        = string
  default     = "full"
  validation {
    condition     = contains(["image_only", "container_only", "full"], var.mode)
    error_message = "The 'mode' variable must be one of 'image_only', 'container_only', or 'full'."
  }
}

variable "image_name" {
  description = "Name of the Docker image to run when mode is 'container_only'."
  type        = string
  default     = "my-app:latest"
}

variable "image_tag" {
  description = "Tag for the Docker image to be built (e.g., 'my-app:latest')."
  type        = string
  default     = "my-app:latest"
}

variable "container_name" {
  description = "Name for the Docker container."
  type        = string
  default     = "my-app-container"
}

variable "container_port" {
  description = "The port the application listens on inside the container."
  type        = number
  default     = 8080 # Matches EXPOSE 8080 in Dockerfile
}

variable "host_port" {
  description = "The port on the host machine to map to the container's port."
  type        = number
  default     = 8080
}

variable "dockerfile_path" {
  description = "Path to the Dockerfile, relative to build_context_path."
  type        = string
  default     = "Dockerfile"
}

variable "build_context_path" {
  description = "Path to the Docker build context (e.g., '.' for current directory)."
  type        = string
  default     = "."
}
