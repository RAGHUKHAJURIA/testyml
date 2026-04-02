variable "mode" {
  description = "Execution mode: 'image_only' to build the Docker image, 'container_only' to run a pre-built image, or 'full' to build and run the image and container."
  type        = string
  default     = "full"
  validation {
    condition     = contains(["image_only", "container_only", "full"], var.mode)
    error_message = "The 'mode' variable must be one of 'image_only', 'container_only', or 'full'."
  }
}

variable "image_name" {
  description = "The base name for the Docker image (e.g., 'my-dockerized-app')."
  type        = string
  default     = "my-dockerized-app"
}

variable "image_tag" {
  description = "The tag for the Docker image (e.g., 'latest' or 'local')."
  type        = string
  default     = "local"
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
  description = "The port on the host machine to map to the container's exposed port (e.g., 8080)."
  type        = number
  default     = 8080
}

variable "build_context" {
  description = "The path to the build context for the Docker image. Default is '.' (current directory)."
  type        = string
  default     = "."
}

variable "dockerfile_path" {
  description = "The path to the Dockerfile within the build context. Default is 'Dockerfile'."
  type        = string
  default     = "Dockerfile"
}
