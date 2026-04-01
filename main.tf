terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "static_web_app" {
  name = "${var.image_name}:${var.image_tag}"
  build {
    context    = "." # Assumes Dockerfile and 'dist' directory are in the same location as Terraform files
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "static_web_container" {
  name  = "static-web-app-container"
  image = docker_image.static_web_app.name
  ports {
    internal = var.container_port
    external = var.host_port
  }
  restart = "on-failure" # Ensures the container restarts if it crashes

  # Health check example (uncomment if you want to include a basic health check):
  # healthcheck {
  #   test     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/ || exit 1"]
  #   interval = "5s"
  #   timeout  = "3s"
  #   retries  = 3
  #   start_period = "5s"
  # }
}