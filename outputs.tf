output "container_url" {
  description = "URL to access the deployed Docker container."
  value       = length(docker_container.app_container) > 0 ? "http://localhost:${docker_container.app_container[0].ports[0].external}" : "Container not deployed (mode not 'container_only' or 'full')."
  sensitive   = false
}

output "docker_image_id" {
  description = "ID of the built Docker image."
  value       = length(docker_image.app_image) > 0 ? docker_image.app_image[0].image_id : "Docker image not built (mode not 'image_only' or 'full')."
  sensitive   = false
}
