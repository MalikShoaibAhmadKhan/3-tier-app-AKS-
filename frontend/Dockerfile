# Use an official nginx image as a parent image
FROM nginx:stable-alpine

# Copy the static assets from the local build context to the nginx html directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 for nginx
EXPOSE 80
