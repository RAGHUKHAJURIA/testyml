terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "app_image" {
  name = var.image_name
  build {
    context    = var.build_context_path
    dockerfile = var.dockerfile_path
    # Optionally, specify build arguments or platform if needed for your environment
    # build_args = {
    #   NODE_ENV = "production"
    # }
    # platform = "linux/amd64"
  }
  # Trigger a rebuild if the Dockerfile or context files change
  triggers = {
    dir_checksum = filebase64sha256("${path.module}/${var.build_context_path}/Dockerfile")
    # You might want to include a hash of the 'dist' directory as well
    # dist_checksum = filebase64sha256("${path.module}/${var.build_context_path}/dist/index.html") # Or a more robust way to hash the directory
  }
}

resource "docker_container" "app_container" {
  name  = var.container_name
  image = docker_image.app_image.name

  ports {
    internal = var.container_port
    external = var.host_port
  }

  # Ensure the container is removed on `terraform destroy`
  rm = true

  # Set a restart policy, e.g., "no", "on-failure", "unless-stopped", "always"
  restart = "unless-stopped"

  # Optional: Add a health check to ensure the application is running inside the container
  # healthcheck {
  #   test = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:${var.container_port} || exit 1"]
  #   interval = "10s"
  #   timeout = "5s"
  #   retries = 5
  #   start_period = "5s"
  # }
}
