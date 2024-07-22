#!/bin/bash

# Install dependencies
apt-get update
apt-get install -y docker.io nginx procps

# Enable and start services
systemctl enable nginx
systemctl start nginx

# Ensure the devopsfetch script is executable
chmod +x /usr/local/bin/devopsfetch.sh
