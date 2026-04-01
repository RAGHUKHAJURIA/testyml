terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  # For Linux/macOS, this is the default.
  # For Windows (WSL2), it typically works as is.
  # For Windows (Docker Desktop native), you might use "npipe:////./pipe/docker_engine"
  # For remote Docker daemon, specify "tcp://hostname:port"
  host = "unix:///var/run/docker.sock"
}

# Docker Image Resource
# Conditionally builds the Docker image based on the 'mode' variable.
resource "docker_image" "app_image" {
  count = (var.mode == "image_only" || var.mode == "full") ? 1 : 0

  name = "${var.app_name}:${var.app_image_tag}"
  build {
    context    = var.build_context
    dockerfile = "Dockerfile"
  }
  # Trigger rebuild if Dockerfile or build context changes
  triggers = {
    dir_checksum = filechecksum("${var.build_context}/Dockerfile")
    # If other files in build context should trigger a rebuild, add their checksums here
    # For instance, if './dist' changes, it should trigger a rebuild.
    # However, 'dist' is often part of the build context and its changes are detected by Docker build itself.
  }
}

# Docker Container Resource
# Conditionally runs the Docker container based on the 'mode' variable.
resource "docker_container" "app_container" {
  count = (var.mode == "container_only" || var.mode == "full") ? 1 : 0

  name  = "${var.app_name}-container"
  image = var.mode == "container_only" ? var.pre_built_image_full_name : docker_image.app_image[0].name
  
  ports {
    internal = var.container_port
    external = var.host_port
  }

  # Ensure the container is restarted if the Docker image changes
  # (only if we are building the image in this run)
  # This is implicitly handled by `docker_image.app_image[0].name` causing recreation
  # or if `pre_built_image_full_name` is updated and applied.
  restart = "on-failure"

  # Remove the container when Terraform destroys it.
  # This is good practice for development environments.
  rm = true

  # Health check (optional, but good practice)
  # healthcheck {
  #   test     = ["CMD", "curl", "-f", "http://localhost:${var.container_port}"]
  #   interval = "5s"
  #   timeout  = "3s"
  #   retries  = 3
  #   start_period = "5s"
  # }
}
