terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

locals {
  # Calculate a hash of all files in the dist directory to trigger image rebuilds.
  # This assumes the 'dist' directory exists and contains build artifacts.
  # 'fileset' will return an empty list if the directory does not exist, or is empty.
  dist_files = fileset("${path.module}/dist", "**")

  # Combine the MD5 hashes of all files in 'dist' into a single hash.
  # If 'dist' is empty or non-existent, this will produce the MD5 of an empty string.
  dist_content_hash = md5(join("", [
    for f in local.dist_files : filemd5("${path.module}/dist/${f}")
  ]))

  # Calculate hash of Dockerfile itself for rebuild triggers
  dockerfile_hash = filemd5(var.dockerfile_path)
}

resource "docker_image" "app_image" {
  # Conditionally build the Docker image based on the 'mode' variable.
  count = (var.mode == "image_only" || var.mode == "full") ? 1 : 0

  name = "${var.image_name}:${var.image_tag}"

  build {
    context    = var.build_context
    dockerfile = var.dockerfile_path
    # Explicitly set platform for consistent builds, especially across different host architectures
    platform   = "linux/amd64"
  }

  # Triggers for rebuilding the image: changes in Dockerfile or 'dist' directory content.
  # This ensures the image is rebuilt if its source files change.
  triggers = {
    dockerfile_md5   = local.dockerfile_hash
    dist_content_md5 = local.dist_content_hash
  }

  # Ensure the image is removed when no longer needed by Terraform.
  # Useful for local development cleanup, use with caution in shared registries.
  force_remove = true
}

resource "docker_container" "app_container" {
  # Conditionally run the Docker container based on the 'mode' variable.
  count = (var.mode == "container_only" || var.mode == "full") ? 1 : 0

  name  = var.container_name
  # Conditionally use the built image or a pre-existing image based on 'mode'.
  image = var.mode == "container_only" ? "${var.image_name}:${var.image_tag}" : docker_image.app_image[0].name

  ports {
    internal = var.container_port
    external = var.host_port
  }

  # Implicit dependency on the Docker image is handled by the 'image' attribute.
  # The 'depends_on' meta-argument is added explicitly as per critical rule #7.
  # Terraform handles the case where docker_image.app_image's count is 0 gracefully,
  # making this dependency a no-op in such scenarios.
  depends_on = [
    docker_image.app_image
  ]
}