#!/bin/bash

# Check if the user has root access
if [ "$EUID" -ne 0 ]; then
  echo $'\e[32mPlease run with root privileges.\e[0m'
  exit
fi

# Paths
HOST_PATH="/etc/hosts"
DNS_PATH="/etc/resolv.conf"

# Green, Yellow & Red Messages.
green_msg() {
    tput setaf 2
    echo "[*] ----- $1"
    tput sgr0
}

yellow_msg() {
    tput setaf 3
    echo "[*] ----- $1"
    tput sgr0
}

red_msg() {
    tput setaf 1
    echo "[*] ----- $1"
    tput sgr0
}

# Function to update system and install sqlite3
install_dependencies() {
    echo -e "${BLUE}Updating package list...${NC}"
    sudo apt update -y

    echo -e "${BLUE}Installing openssl...${NC}"
    sudo apt install -y openssl

    echo -e "${BLUE}Installing jq...${NC}"
    sudo apt install -y jq

    echo -e "${BLUE}Installing curl...${NC}"
    sudo apt install -y curl

    echo -e "${BLUE}Installing ufw...${NC}"
    sudo apt install -y ufw

    sudo apt -y install apt-transport-https locales apt-utils bash-completion libssl-dev socat

    sudo apt -y -q autoclean
    sudo apt -y clean
    sudo apt -q update
    sudo apt -y autoremove --purge
}
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Purple}This script must be run as root. Please run it with sudo.${NC}"
        exit 1
    fi
}

fix_etc_hosts(){
  echo
  yellow_msg "Fixing Hosts file."
  sleep 0.5

  cp $HOST_PATH /etc/hosts.bak
  yellow_msg "Default hosts file saved. Directory: /etc/hosts.bak"
  sleep 0.5

  # shellcheck disable=SC2046
  if ! grep -q $(hostname) $HOST_PATH; then
    echo "127.0.1.1 $(hostname)" | sudo tee -a $HOST_PATH > /dev/null
    green_msg "Hosts Fixed."
    echo
    sleep 0.5
  else
    green_msg "Hosts OK. No changes made."
    echo
    sleep 0.5
  fi
}

fix_dns(){
    echo
    yellow_msg "Fixing DNS Temporarily."
    sleep 0.5

    cp $DNS_PATH /etc/resolv.conf.bak
    yellow_msg "Default resolv.conf file saved. Directory: /etc/resolv.conf.bak"
    sleep 0.5

    sed -i '/nameserver/d' $DNS_PATH

    echo "nameserver 8.8.8.8" >> $DNS_PATH
    echo "nameserver 8.8.4.4" >> $DNS_PATH

    green_msg "DNS Fixed Temporarily."
    echo
    sleep 0.5
}

# Color codes
Purple='\033[0;35m'
Cyan='\033[0;36m'
cyan='\033[0;36m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
White='\033[0;96m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color 

    echo -e "${Purple}"
    cat << "EOF"
          
                 
══════════════════════════════════════════════════════════════════════════════════════
        ____                             _     _                                     
    ,   /    )                           /|   /                                  /   
-------/____/---_--_----__---)__--_/_---/-| -/-----__--_/_-----------__---)__---/-__-
  /   /        / /  ) /   ) /   ) /    /  | /    /___) /   | /| /  /   ) /   ) /(    
_/___/________/_/__/_(___(_/_____(_ __/___|/____(___ _(_ __|/_|/__(___/_/_____/___\__

══════════════════════════════════════════════════════════════════════════════════════
EOF
    echo -e "${NC}"

echo -e "\e[36mSpecial Thanks Masoud Gb\e[0m"

echo "═════════════════════════════════════════MENU══════════════════════════════════════════"



options=($'\e[36m1. \e[0mGost Tunnel By IP4'
         $'\e[36m2. \e[0mGost Tunnel By IP6'
         $'\e[36m3. \e[0mUninstall'
         $'\e[36m4. \e[0mExit')

# Print prompt and options with cyan color
printf "\e[33mPlease Choice Your Options:\e[0m\n"
printf "%s\n" "${options[@]}"

# Read user input with white color
read -p $'\e[97mYour choice: \e[0m' choice

# If option 1 or 2 is selected
if [ "$choice" -eq 1 ] || [ "$choice" -eq 2 ]; then

    if [ "$choice" -eq 1 ]; then
        read -p $'\e[97mPlease enter the destination Kharej IP: \e[0m' destination_ip
    elif [ "$choice" -eq 2 ]; then
        read -p $'\e[97mPlease enter the destination Kharej IPv6: \e[0m' destination_ip
    fi

    read -p $'\e[32mPlease choose one of the options below:\n\e[0m\e[32m1. \e[0mEnter Manually Ports\n\e[32m2. \e[0mEnter Range Ports\e[32m\nYour choice: \e[0m' port_option

    if [ "$port_option" -eq 1 ]; then
        read -p $'\e[97mPlease enter the desired ports (separated by commas): \e[0m' ports
    elif [ "$port_option" -eq 2 ]; then
        read -p $'\e[97mPlease enter the port range (e.g., 1,65535): \e[0m' port_range
        IFS=',' read -ra port_array <<< "$port_range"
        ports=$(IFS=,; echo "${port_array[*]}")
    else
        echo $'\e[31mInvalid option. Exiting...\e[0m'
        exit
    fi

    read -p $'\e[32mSelect the protocol:\n\e[0m\e[36m1. \e[0mBy "Tcp" Protocol \n\e[36m2. \e[0mBy "Udp" Protocol \n\e[36m3. \e[0mBy "Grpc" Protocol \e[32m\nYour choice: \e[0m' protocol_option

if [ "$protocol_option" -eq 1 ]; then
    protocol="tcp"
elif [ "$protocol_option" -eq 2 ]; then
    protocol="udp"
elif [ "$protocol_option" -eq 3 ]; then
    protocol="grpc"
else
    echo $'\e[31mInvalid protocol option. Exiting...\e[0m'
    exit
fi

    echo $'\e[32mYou chose option\e[0m' $choice
    echo $'\e[97mDestination IP:\e[0m' $destination_ip
    echo $'\e[97mPorts:\e[0m' $ports
    echo $'\e[97mProtocol:\e[0m' $protocol

    # Commands to install and configure Gost
    sudo apt install wget nano -y && \
echo $'\e[32mInstalling Gost version v3.0.0, please wait...\e[0m' && \
wget https://github.com/iPmartNetwork/GOST/releases/download/v3.0.0-nightly.20240715/gost_3.0.0.tar.gz && \
echo $'\e[32mGost downloaded successfully.\e[0m' && \
gunzip gost_3.0.0.tar.gz && \
sudo mv gost_3.0.0.tar.gz /usr/local/bin/gost && \
sudo chmod +x /usr/local/bin/gost && \
echo $'\e[32mGost installed successfully.\e[0m'

    # Create systemd service file without displaying content
    cat <<EOL | sudo tee /usr/lib/systemd/system/gost.service > /dev/null
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
EOL

    # Variable to store the ExecStart command
    exec_start_command="ExecStart=/usr/local/bin/gost"

    # Add lines for each port
    IFS=',' read -ra port_array <<< "$ports"
    for port in "${port_array[@]}"; do
        exec_start_command+=" -L=$protocol://:$port/[$destination_ip]:$port"
    done

    # Add the loop for adding additional IPs
    while true; do
        read -p $'\e[36mDo you want to add another destination IP? (y/n): \e[0m' add_another_ip
        if [ "$add_another_ip" == "n" ]; then
            break
        elif [ "$add_another_ip" == "y" ]; then
            read -p $'\e[97mPlease enter the new destination (Kharej) IP: \e[0m' new_destination_ip

            # Use the same protocol as the first choice by default
            new_protocol=$protocol

            read -p $'\e[32mPlease choose one of the options below:\n\e[0m\e[32m1. \e[0mEnter Manually Ports\n\e[32m2. \e[0mEnter Range Ports\e[32m\nYour choice: \e[0m' new_port_option

            if [ "$new_port_option" -eq 1 ]; then
                read -p $'\e[97mPlease enter the desired ports (separated by commas): \e[0m' new_ports
            elif [ "$new_port_option" -eq 2 ]; then
                read -p $'\e[97mPlease enter the port range (e.g., 1,65535): \e[0m' new_port_range
                IFS=',' read -ra new_port_array <<< "$new_port_range"
                new_ports=$(IFS=,; echo "${new_port_array[*]}")
            else
                echo $'\e[31mInvalid option. Exiting...\e[0m'
                exit
            fi

            echo $'\e[97mNew Destination IP:\e[0m' $new_destination_ip
            echo $'\e[97mNew Ports:\e[0m' $new_ports
            echo $'\e[97mNew Protocol:\e[0m' $new_protocol

            # Add lines for each port of the new destination IPs
            IFS=',' read -ra new_port_array <<< "$new_ports"
            for new_port in "${new_port_array[@]}"; do
                exec_start_command+=" -L=$new_protocol://:$new_port/[$new_destination_ip]:$new_port"
            done
        else
            echo $'\e[31mInvalid option. Exiting...\e[0m'
            exit
        fi
    done

    # Continue creating the systemd service file
    echo "$exec_start_command" | sudo tee -a /usr/lib/systemd/system/gost.service > /dev/null

    cat <<EOL | sudo tee -a /usr/lib/systemd/system/gost.service > /dev/null

[Install]
WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable gost.service
    sudo systemctl restart gost.service
    echo $'\e[32mGost configuration applied successfully.\e[0m'

# If option 3 is selected
elif [ "$choice" -eq 3 ]; then
    # Countdown for uninstallation in a single line
    echo $'\e[32mUninstalling Gost in 3 seconds... \e[0m' && sleep 1 && echo $'\e[32m2... \e[0m' && sleep 1 && echo $'\e[32m1... \e[0m' && sleep 1 && { sudo rm -f /usr/local/bin/gost && sudo rm -f /usr/lib/systemd/system/gost.service && echo $'\e[32mGost successfully uninstalled.\e[0m'; }

# If option 4 is selected
elif [ "$choice" -eq 4 ]; then
    echo $'\e[32mYou have exited the script.\e[0m'
    exit
fi
