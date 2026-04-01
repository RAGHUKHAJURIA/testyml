variable "docker_image_name" {
  description = "The name and tag for the Docker image (e.g., my-app:latest)."
  type        = string
  default     = "my-application:latest"
}

variable "docker_container_name" {
  description = "The name for the Docker container."
  type        = string
  default     = "my-application-container"
}

variable "container_port" {
  description = "The internal port on which the application inside the container listens."
  type        = number
  default     = 8080 # Common default for web applications
}

variable "host_port" {
  description = "The port on the host machine to map to the container's internal port."
  type        = number
  default     = 8080 # Example: map to the same port on the host
}

variable "dockerfile_context" {
  description = "The path to the build context directory for the Docker image. This directory should contain the Dockerfile and all files needed for the build (e.g., the './dist' folder created by CI). Relative to where 'terraform apply' is run."
  type        = string
  default     = "."
}

variable "dockerfile_name" {
  description = "The name of the Dockerfile within the 'dockerfile_context'."
  type        = string
  default     = "Dockerfile"
}
