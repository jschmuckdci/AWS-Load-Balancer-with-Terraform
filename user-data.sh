#!/bin/bash
# Update the package repository
apt update -y
apt upgrade -y

# Install Nginx
apt install -y nginx

# Start Nginx service
systemctl start nginx

# Enable Nginx to start on boot
systemctl enable nginx

# Create a basic HTML page
echo "<h1>Welcome to Nginx on EC2</h1>" > /var/www/html/index.html
