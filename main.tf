terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# Resource to build the Docker image
resource "docker_image" "app_image" {
  count = var.mode == "image_only" || var.mode == "full" ? 1 : 0

  name = var.image_tag

  build {
    context    = var.build_context_path
    dockerfile = var.dockerfile_path
    tag        = [var.image_tag]
  }

  # Triggers to rebuild the image if Dockerfile or 'dist' directory contents change.
  # 'fileset' recursively finds all files in 'dist' and their MD5 hashes are joined
  # to form a single trigger value. This ensures that any change within 'dist' or
  # to the Dockerfile itself will cause a rebuild.
  triggers = {
    dockerfile_hash = filemd5("${var.build_context_path}/${var.dockerfile_path}")
    dist_content_hash = join("-", [for f in fileset("${var.build_context_path}/dist", "**") : filemd5("${var.build_context_path}/dist/${f}")])
  }
}

# Resource to run the Docker container
resource "docker_container" "app_container" {
  count = var.mode == "container_only" || var.mode == "full" ? 1 : 0

  name  = var.container_name
  image = var.mode == "container_only" ? var.image_name : docker_image.app_image[0].name

  ports {
    internal = var.container_port
    external = var.host_port
  }

  # Respects the CMD in the Dockerfile: CMD ["http-server", "/app/html", "-p", "8080"]
  # No explicit command needed unless overriding.

  # Link the container to the image build, if the image is built by Terraform.
  # The depends_on ensures the image is ready before the container attempts to use it.
  dynamic "depends_on" {
    for_each = var.mode == "full" ? [1] : []
    content {
      value = [docker_image.app_image[0].id]
    }
  }

  restart = "always"
}