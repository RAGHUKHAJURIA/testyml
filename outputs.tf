output "container_url" {
  description = "The URL to access the running Docker container, if applicable."
  value       = length(docker_container.app_container) > 0 ? "http://localhost:${docker_container.app_container[0].ports[0].external}" : "Container not running in this mode."
}

output "image_name_built" {
  description = "The full name of the Docker image that was built, if applicable."
  value       = length(docker_image.app_image) > 0 ? docker_image.app_image[0].name : "Image not built in this mode."
}
