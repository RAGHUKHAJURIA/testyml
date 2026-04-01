output "container_url" {
  description = "The URL to access the deployed Docker container."
  value       = try(
    "http://localhost:${docker_container.app_container[0].ports[0].external}",
    "Container not deployed in this mode (mode: ${var.mode})"
  )
  # The sensitive flag can be used if the URL contains sensitive information, though unlikely for localhost.
  # sensitive = true
}

output "image_name" {
  description = "The full name of the Docker image that was built or would be used."
  value = var.mode == "container_only" ? var.pre_built_image_full_name : try(
    docker_image.app_image[0].name,
    "Image not built in this mode (mode: ${var.mode})"
  )
}
