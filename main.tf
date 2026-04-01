# Update your existing main.tf to use the 'image_full_tag' variable for your container definition.
# For example, if you are deploying to AWS ECS, you would update an 'aws_ecs_task_definition' resource.

# Example modification (adjust to your specific resource, e.g., Kubernetes Deployment, other container service):

# Find your container definition resource, e.g.:
resource "aws_ecs_task_definition" "my_app_task" {
  # ... existing attributes ...

  # Update the 'image' field within your container_definitions JSON:
  container_definitions = jsonencode([
    {
      name  = "my-dockerized-app",
      image = var.image_full_tag, # <-- Use the variable here
      cpu   = 256,
      memory= 512,
      essential = true,
      portMappings = [
        {
          containerPort = 8080, # Matches Dockerfile EXPOSE
          hostPort      = 8080,
          protocol      = "tcp"
        }
      ],
      # ... other container configurations from your existing setup ...
    }
  ])

  # ... other task definition settings ...
}

# Existing main.tf content would be here:
# ...
