# Use a small Node.js base image. This example assumes your 'dist' directory contains web artifacts.
# If your project is Python-based and builds an artifact, you would use a Python base image
# and adapt the subsequent steps to run your Python application.
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy the pre-built application artifacts from the host's './dist' directory
# This './dist' directory is where the CI/CD pipeline places the build output.
# Ensure this 'dist' directory exists at the root of your project when running `terraform apply`.
COPY ./dist /app/html

# Install a simple static file server (e.g., http-server) to serve the artifacts.
# This is a common pattern for frontend applications or static sites.
# For a backend application, you'd install its dependencies and run its main script.
RUN npm install -g http-server

# Expose the port the application will run on inside the container.
# This should match the `container_port` variable in Terraform.
EXPOSE 8080

# Command to run the application.
# For this example, it serves static files from /app/html on port 8080.
CMD ["http-server", "/app/html", "-p", "8080"]