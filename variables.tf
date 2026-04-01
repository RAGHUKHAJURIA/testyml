variable "mode" {
  description = "Determines whether to build the image, run the container, or both."
  type        = string
  default     = "full" # Default to full build and run for local development
  validation {
    condition     = contains(["image_only", "container_only", "full"], var.mode)
    error_message = "The 'mode' variable must be one of: 'image_only', 'container_only', 'full'."
  }
}

variable "image_tag" {
  description = "The tag for the Docker image. If mode is 'container_only', this is the source image to pull. If mode is 'image_only' or 'full', this is the tag for the locally built image."
  type        = string
  default     = "my-app:latest" # For local builds, or a fallback for container_only
  # Note: The CD pipeline will override this with 'ghcr.io/repository:sha' for deployments.
}

variable "container_name" {
  description = "The name for the Docker container."
  type        = string
  default     = "my-app"
}

variable "container_port" {
  description = "The internal port exposed by the Docker container (from Dockerfile EXPOSE)."
  type        = number
  default     = 8080 # Matches Dockerfile
}

variable "host_port" {
  description = "The port on the host machine to map to the container_port."
  type        = number
  default     = 8080
}

variable "dockerfile_path" {
  description = "The path to the Dockerfile to use for building the image."
  type        = string
  default     = "./Dockerfile"
}

variable "build_context_path" {
  description = "The build context path for the Docker image (e.g., '.' for current directory)."
  type        = string
  default     = "."
}
