variable "mode" {
  description = "Determines whether to build the Docker image ('image_only'), run a pre-existing container ('container_only'), or perform both ('full')."
  type        = string
  default     = "full"
  validation {
    condition     = contains(["image_only", "container_only", "full"], var.mode)
    error_message = "The 'mode' variable must be one of 'image_only', 'container_only', or 'full'."
  }
}

variable "image_name" {
  description = "The name of the Docker image to build, or to use if mode is 'container_only'."
  type        = string
  default     = "my-dockerized-app:latest"
}

variable "container_name" {
  description = "The name for the Docker container."
  type        = string
  default     = "my-dockerized-app-container"
}

variable "container_port" {
  description = "The port exposed by the application inside the Docker container (e.g., 8080)."
  type        = number
  default     = 8080
}

variable "host_port" {
  description = "The host port to bind to the container's exposed port. Defaults to the same as container_port."
  type        = number
  default     = 8080
}

variable "dockerfile_path" {
  description = "The path to the Dockerfile relative to the build context."
  type        = string
  default     = "Dockerfile"
}

variable "build_context_path" {
  description = "The path to the build context directory for Docker (e.g., where Dockerfile and source code reside)."
  type        = string
  default     = "."
}
