output "staging_container_id" {
  description = "The ID of the local Docker staging container."
  value       = docker_container.app_staging.id
}

output "staging_container_name" {
  description = "The name of the local Docker staging container."
  value       = docker_container.app_staging.name
}

output "staging_access_url" {
  description = "URL to access the staging application locally."
  value       = "http://localhost:${var.staging_host_port}"
}

output "production_container_id" {
  description = "The ID of the local Docker production container.""
  value       = docker_container.app_production.id
}

output "production_container_name" {
  description = "The name of the local Docker production container."
  value       = docker_container.app_production.name
}

output "production_access_url" {
  description = "URL to access the production application locally."
  value       = "http://localhost:${var.production_host_port}"
}
