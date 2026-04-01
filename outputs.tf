output "container_id" {
  description = "The ID of the running Docker container."
  value       = docker_container.app_container.id
}

output "container_name" {
  description = "The name of the running Docker container."
  value       = docker_container.app_container.name
}

output "container_ip_address" {
  description = "The IP address of the Docker container within the Docker network."
  value       = docker_container.app_container.ip_address
}

output "host_url" {
  description = "The URL to access the application on the host machine."
  value       = "http://localhost:${docker_container.app_container.ports[0].external}"
}
