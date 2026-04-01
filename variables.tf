variable "image_name" {
  description = "Name and tag for the Docker image to be built."
  type        = string
  default     = "my-static-web-app:latest"
}

variable "container_name" {
  description = "Name for the Docker container."
  type        = string
  default     = "static-web-app-container"
}

variable "container_port" {
  description = "The port exposed by the application inside the Docker container (as per Dockerfile EXPOSE)."
  type        = number
  default     = 8080
}

variable "host_port" {
  description = "The port on the host machine to map to the container's exposed port."
  type        = number
  default     = 8080 # Default to the same as container port, can be overridden
}

variable "dockerfile_path" {
  description = "Path to the Dockerfile relative to the build context."
  type        = string
  default     = "Dockerfile"
}

variable "build_context_path" {
  description = "Path to the Docker image build context (where Dockerfile and 'dist' directory reside), relative to the Terraform root module."
  type        = string
  default     = "."
}
