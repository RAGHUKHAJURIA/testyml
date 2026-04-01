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
# It assumes a Dockerfile exists in the project root alongside this main.tf
# And that the ./dist directory (containing the build artifacts from CI) is available
resource "docker_image" "app_image" {
  name = "my-app:${var.image_tag}"
  build {
    context = "." # Assumes Dockerfile and 'dist' directory are in the current working directory
    # Optionally, specify a path to Dockerfile if not in the root:
    # dockerfile = "./path/to/Dockerfile"
  }
  # Trigger rebuild if the Dockerfile or its context changes
  # We use a filemd5 on the Dockerfile itself and a dummy file within dist
  # (or the dist directory's content hash) to detect changes.
  # For simplicity, we'll just check the Dockerfile and a sentinel file in dist.
  triggers = {
    dockerfile_hash = filemd5("${path.module}/Dockerfile")
    dist_hash       = filemd5("${path.module}/dist/index.html") # Or any key artifact, or a script to hash the dir
  }
}

# Docker Container for Staging Environment
resource "docker_container" "app_staging" {
  name  = "${var.app_name}-staging"
  image = docker_image.app_image.name

  ports {
    internal = var.container_port
    external = var.staging_host_port
  }

  env = [
    "ENVIRONMENT=staging",
    "APP_PORT=${var.container_port}"
  ]

  # Ensure the image is built before attempting to create the container
  depends_on = [docker_image.app_image]
}

# Docker Container for Production Environment
resource "docker_container" "app_production" {
  name  = "${var.app_name}-production"
  image = docker_image.app_image.name

  ports {
    internal = var.container_port
    external = var.production_host_port
  }

  env = [
    "ENVIRONMENT=production",
    "APP_PORT=${var.container_port}"
  ]

  # Ensure the image is built before attempting to create the container
  depends_on = [docker_image.app_image]
}

# Placeholder Dockerfile (assumes a static web app or Node.js app served by http-server)
# This Dockerfile should be created at the root of your project where main.tf resides.
# It assumes your CI/CD pipeline places build artifacts into the `./dist` directory.
# --- Dockerfile (create this file manually) ---
# # Use a small Node.js base image
# FROM node:18-alpine
#
# # Set the working directory inside the container
# WORKDIR /app
#
# # Copy the pre-built application artifacts from the host's 'dist' directory
# # This 'dist' directory is where the CI/CD pipeline placed the build output.
# COPY ./dist /app/html
#
# # Install a simple static file server (e.g., http-server)
# RUN npm install -g http-server
#
# # Expose the port the application will run on
# EXPOSE 8080
#
# # Command to run the application - serving static files from /app/html
# CMD ["http-server", "/app/html", "-p", "8080"]
# -----------------------------------------------------------------