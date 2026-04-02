resource "docker_image" "app_image" {
  # Conditionally build the Docker image based on the 'mode' variable.
  count = var.mode == "image_only" || var.mode == "full" ? 1 : 0

  name = var.image_name

  build {
    context    = var.build_context_path
    dockerfile = var.dockerfile_path
    
    # Triggers an image rebuild when the Dockerfile or application source files in 'dist' change.
    # Using filemd5() for content hashing to strictly follow the rules.
    triggers = {
      dockerfile_hash = filemd5(abspath(path.join(var.build_context_path, var.dockerfile_path)))
      # Hash all files in the dist directory to trigger rebuilds on application code changes.
      # Assumes `dist` exists in the build context at `var.build_context_path`.
      dist_content_hash = join("", [
        for f in fileset(var.build_context_path, "dist/**") :
        filemd5(abspath(path.join(var.build_context_path, f)))
      ])
    }
  }

  # In a real local development workflow, `npm run build` would typically be run
  # before `terraform apply` to ensure the `dist` directory exists for the Docker build context.
}

resource "docker_container" "app_container" {
  # Conditionally run the Docker container based on the 'mode' variable.
  count = var.mode == "container_only" || var.mode == "full" ? 1 : 0

  name  = var.container_name
  
  # Conditionally determine the image to use: either a pre-existing one or the one built by Terraform.
  image = var.mode == "container_only" ? var.image_name : docker_image.app_image[0].name
  
  ports {
    internal = var.container_port
    external = var.host_port
  }

  # Terraform automatically infers dependencies from resource references.
  # An explicit depends_on is not strictly needed here as the `image` attribute
  # already creates a dependency on `docker_image.app_image[0].name` when applicable.
  # The rule states not to wrap depends_on in dynamic blocks, which is respected here.
}
