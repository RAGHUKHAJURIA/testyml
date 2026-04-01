variable "image_name" {
  description = "Name for the Docker image."
  type        = string
  default     = "static-web-app"
}

variable "image_tag" {
  description = "Tag for the Docker image."
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "The port exposed internally by the Docker container, as specified in the Dockerfile."
  type        = number
  default     = 8080
}

variable "host_port" {
  description = "The port on the host machine to map to the container's internal port."
  type        = number
  default     = 8080 # Default to the same as container_port for simplicity
}