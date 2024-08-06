#!/bin/bash

# Variables
GO_URL="https://golang.org/dl/go1.16.5.linux-amd64.tar.gz"
INSTALL_DIR="/usr/local"
SERVICE_NAME="ssh_tunnel"
CRON_JOB="/etc/cron.d/ssh_tunnel"

# Download and Install Go
wget $GO_URL -O /tmp/go.tar.gz
tar -C $INSTALL_DIR -xzf /tmp/go.tar.gz
export PATH=$INSTALL_DIR/go/bin:$PATH

# Create SSH Tunnel Function
setup_ssh_tunnel() {
  read -p "Enter remote server IP: " REMOTE_IP
  read -p "Enter remote server port: " REMOTE_PORT
  read -p "Enter local port range start: " PORT_START
  read -p "Enter local port range end: " PORT_END
  
  # Ensure port range is valid
  if ((PORT_START < 23 || PORT_END > 65535 || PORT_START > PORT_END)); then
    echo "Invalid port range. Please enter a range between 23 and 65535."
    exit 1
  fi
  
  # SSH Tunnel Command
  ssh -f -N -L $PORT_START-$PORT_END:$REMOTE_IP:$REMOTE_PORT user@$REMOTE_IP
}

setup_ssh_tunnel
# Create Systemd Service File
echo "[Unit]
Description=SSH Tunnel Service
After=network.target

[Service]
ExecStart=/usr/bin/ssh -f -N -L $PORT_START-$PORT_END:$REMOTE_IP:$REMOTE_PORT user@$REMOTE_IP
Restart=always

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/$SERVICE_NAME.service

# Enable and Start Service
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

# Create Cron Job
echo "0 * * * * root /usr/bin/ssh -f -N -L $PORT_START-$PORT_END:$REMOTE_IP:$REMOTE_PORT user@$REMOTE_IP" > $CRON_JOB

# Apply Cron Job
crontab $CRON_JOB
