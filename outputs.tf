output "container_url" {
  description = "URL to access the running Docker container locally."
  value       = "http://localhost:${docker_container.static_web_container.ports[0].external}"
}

output "image_id" {
  description = "The ID of the built Docker image."
  value       = docker_image.static_web_app.id
}