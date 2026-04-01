terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0" # Using a compatible version for the Docker provider
    }
  }
}

# Configure the Docker provider to connect to the local Docker daemon
# By default, it uses standard Docker daemon connection methods (e.g., unix socket, DOCKER_HOST env var).
provider "docker" {}

/**
 * Builds a Docker image locally based on a Dockerfile and context.
 * Assumes the Dockerfile and necessary application build artifacts (e.g., from ./dist)
 * are present in the 'dockerfile_context' directory when Terraform is applied.
 */
resource "docker_image" "app_image" {
  name = var.docker_image_name
  build {
    context    = var.dockerfile_context # Path to the directory containing the Dockerfile and build context
    dockerfile = var.dockerfile_name    # Name of the Dockerfile within the context
    # Optionally, specify a platform for multi-arch builds
    # platform = "linux/amd64"

    # Add build arguments if your Dockerfile uses them
    # build_args = {
    #   NODE_ENV = "production"
    # }
  }
  # Keep the image on disk even after Terraform refreshes or applies
  keep_locally = true

  # Optional: Trigger a rebuild if the source files change
  # This is a common pattern to ensure the image is updated when application code changes.
  # Requires `triggers` to watch for file changes in the build context.
  # triggers = { 
  #   dir_sha1 = filebase64sha256("${path.module}/${var.dockerfile_context}/Dockerfile") # Watch Dockerfile changes
  #   app_files_sha1 = filebase64sha256tree("${path.module}/${var.dockerfile_context}/dist") # Watch application artifact changes
  # }
}

/**
 * Runs a Docker container from the locally built image.
 * Maps a host port to an internal container port.
 */
resource "docker_container" "app_container" {
  name  = var.docker_container_name
  image = docker_image.app_image.name # Reference the image built by docker_image.app_image
  ports {
    internal = var.container_port # The port your application listens on inside the container
    external = var.host_port      # The port on the host machine to expose
  }
  
  # Always restart the container unless it is explicitly stopped
  restart = "unless-stopped"

  # Optional: Mount volumes for persistent data or configuration
  # volumes {
  #   container_path = "/app/config"
  #   host_path      = "${path.cwd}/config"
  #   read_only      = true
  # }

  # Optional: Set environment variables for the application
  # env = [
  #   "APP_ENV=production",
  #   "DATABASE_URL=postgres://user:pass@host:port/db"
  # ]
}
