# Use an official nginx image as a parent image
FROM nginx:stable-alpine

# Install security updates for vulnerable packages
RUN apk update && \
    apk upgrade --no-cache \
    libexpat \
    libxml2 \
    libxslt \
    xz-libs && \
    rm -rf /var/cache/apk/*

# Copy the static assets from the local build context to the nginx html directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 for nginx
EXPOSE 80
