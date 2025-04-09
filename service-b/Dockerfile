# Use an official Node.js runtime as a parent image
FROM node:18-alpine

# Install security updates for vulnerable packages
RUN apk update && \
    apk upgrade --no-cache \
    libexpat \
    libxml2 \
    libxslt \
    xz-libs && \
    rm -rf /var/cache/apk/*

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Update package.json to explicitly override the cross-spawn dependency
RUN npm pkg set overrides.cross-spawn="^7.0.5"

# Install app dependencies
RUN npm install

# Bundle app source
COPY . .

# Expose the port the app runs on
EXPOSE 3002

# Define the command to run the app
CMD [ "node", "server.js" ]
