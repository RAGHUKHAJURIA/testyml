output "container_url" {
  description = "The URL to access the deployed Docker container locally."
  # Uses try() to prevent compiler errors if the container resource is not created (count = 0).
  # Avoids explicit .ip_address as per critical rule.
  value = try(
    format("http://localhost:%d", docker_container.app_container[0].ports[0].external),
    "Container not running. Set 'mode' to 'container_only' or 'full' to run the container."
  )
  sensitive = false
}

output "image_id" {
  description = "The ID of the built Docker image."
  # Uses try() to prevent compiler errors if the image resource is not created (count = 0).
  value       = try(docker_image.app_image[0].image_id, "Image not built. Set 'mode' to 'image_only' or 'full' to build the image.")
  sensitive   = false
}
