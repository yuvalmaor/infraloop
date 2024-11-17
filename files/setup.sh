#!/bin/bash

echo "Starting setup script..."

# Update package lists
echo "Updating package lists..."
sudo apt-get update

# Install Python3, pip and nginx
echo "Installing Python3, pip and nginx..."
sudo apt-get install -y python3 python3-pip nginx

# Install requests module
echo "Installing requests module..."
sudo pip3 install requests

# Create initial nginx configuration
echo "Configuring nginx..."
echo "progress" | sudo tee /var/www/html/index.html

# Restart nginx
sudo systemctl restart nginx

echo "Setup completed successfully!"