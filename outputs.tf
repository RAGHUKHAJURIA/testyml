output "container_url" {
  description = "The URL to access the running Docker container, if provisioned."
  # Conditionally output the URL or a descriptive message if the container is not running.
  # Use 'length()' to check if the resource has any instances to avoid compiler errors.
  value       = length(docker_container.app_container) > 0 ? "http://localhost:${docker_container.app_container[0].ports[0].external}" : "Docker container not provisioned or running in this mode."
  sensitive   = false
}

output "docker_image_id" {
  description = "The ID of the built Docker image, if built."
  value       = length(docker_image.app_image) > 0 ? docker_image.app_image[0].image_id : "Docker image not built in this mode."
  sensitive   = false
}

output "docker_image_name" {
  description = "The full name (name:tag) of the Docker image, if built."
  value       = length(docker_image.app_image) > 0 ? docker_image.app_image[0].name : "Docker image not built in this mode."
  sensitive   = false
}
