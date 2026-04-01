output "container_url" {
  description = "The URL to access the running Docker container, if deployed."
  value = var.mode == "container_only" || var.mode == "full" ? (
    # Check if the container resource was actually created (count > 0)
    length(docker_container.app_container) > 0 ? (
      "http://localhost:${docker_container.app_container[0].ports[0].external}"
    ) : (
      "Container not deployed or not running in this mode. Check 'var.mode'."
    )
  ) : (
    "Container not configured to be deployed in 'image_only' mode."
  )
}

output "docker_image_name" {
  description = "The name of the Docker image that was built or would be used."
  value = var.mode == "image_only" || var.mode == "full" ? (
    length(docker_image.app_image) > 0 ? docker_image.app_image[0].name : var.image_name # Fallback to var.image_name if image resource count is 0
  ) : var.image_name
}
