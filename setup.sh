#!/bin/bash

# Install necessary dependencies
sudo apt-get update
sudo apt-get install -y docker.io nginx ss

# Move devopsfetch.sh to /usr/local/bin
sudo mv devopsfetch.sh /usr/local/bin/devopsfetch.sh
sudo chmod +x /usr/local/bin/devopsfetch.sh

# Create devopsfetch service file
SERVICE_FILE="/etc/systemd/system/devopsfetch.service"

sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Devopsfetch Monitoring Service
After=network.target

[Service]
ExecStart=/usr/local/bin/devopsfetch.sh -m
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable devopsfetch.service
sudo systemctl start devopsfetch.service

echo "Devopsfetch installed and service started."
