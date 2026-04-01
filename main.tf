terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  # Assumes Docker daemon is running locally and accessible via default socket.
  # For Windows, you might need: host = "tcp://localhost:2375"
  # For macOS/Linux, unix:///var/run/docker.sock is usually the default.
}

# Resource to build the Docker image if mode is 'image_only' or 'full'
resource "docker_image" "app_image" {
  count = var.mode == "image_only" || var.mode == "full" ? 1 : 0

  # Use the image_tag variable for naming the locally built image
  name = var.image_tag

  build {
    path       = var.build_context_path
    dockerfile = var.dockerfile_path

    # Triggers rebuilds if Dockerfile or the 'dist' directory content changes.
    # Using filemd5() for robust change detection.
    # The 'dist' directory is expected to be present by the CI pipeline before Terraform runs.
    triggers = {
      dockerfile_md5 = filemd5(var.dockerfile_path)
      # Note: If the 'dist' directory is not guaranteed to exist when running in 'image_only' or 'full' mode
      # without a preceding build step, filemd5() on a non-existent directory will cause an error.
      # The CI/CD context explicitly states `npm run build` which creates './dist'.
      dist_md5       = filemd5("${path.module}/dist")
    }
  }

  # Always pull latest updates of base images during build if they exist
  force_remove = true
}

# Resource to run the Docker container if mode is 'container_only' or 'full'
resource "docker_container" "app_container" {
  count = var.mode == "container_only" || var.mode == "full" ? 1 : 0

  name = var.container_name

  # Conditionally use the pre-built image (from var.image_tag) or the locally built image.
  image = var.mode == "container_only" ? var.image_tag : docker_image.app_image[0].name

  ports {
    internal = var.container_port # Internal port as exposed in Dockerfile
    external = var.host_port      # Port on the host machine
  }

  # Automatically remove the container when it exits
  rm = true

  # Ensure the container starts after the image is built in 'full' mode.
  # Terraform implicitly handles dependencies when one resource's attribute
  # refers to another (e.g., image = docker_image.app_image[0].name).
  # An explicit depends_on is added for clarity and to satisfy the rule for the resource block.
  # If docker_image.app_image has count=0, it resolves to an empty list, which is valid for depends_on.
  depends_on = [
    docker_image.app_image # Depend on the entire resource block, even if count is 0
  ]

  # Gracefully stop the container before destroying it
  destroy_grace_duration = "10s"
}
