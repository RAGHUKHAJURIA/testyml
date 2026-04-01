terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# Resource for building the Docker image
resource "docker_image" "app_image" {
  count = var.mode == "image_only" || var.mode == "full" ? 1 : 0

  name = "${var.image_name}:latest" # Use a stable tag, rebuilds are handled by 'triggers' block

  build {
    context    = path.cwd # Dockerfile and build_context_path (dist) are relative to current working directory
    dockerfile = var.dockerfile_path
  }

  # Trigger a rebuild if the Dockerfile or the build context (dist directory) contents change
  triggers = {
    dockerfile_hash    = filemd5(var.dockerfile_path)
    build_context_hash = filemd5(pathexpand(var.build_context_path))
  }
}

# Resource for running the Docker container
resource "docker_container" "app_container" {
  count = var.mode == "container_only" || var.mode == "full" ? 1 : 0

  name  = var.container_name
  image = var.mode == "container_only" ? var.image_name : docker_image.app_image[0].name

  ports {
    internal = var.container_port
    external = var.host_port
  }

  # The dependency on docker_image.app_image is implicitly handled by referencing its name
  # in the `image` attribute. Terraform ensures the image is available before creating the container.
  # No explicit depends_on is strictly needed here and avoids issues with count = 0 resources.
}
