#!/bin/bash

# Color codes
Purple='\033[0;35m'
Cyan='\033[0;36m'
YELLOW='\033[0;33m'
White='\033[0;96m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if the user has root access
if [ "$EUID" -ne 0 ]; then
  echo $'\e[32mPlease run with root privileges.\e[0m'
  exit
fi

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
         $'\e[36m3. \e[0mGost Status'
         $'\e[36m4. \e[0mAuto Restart Gost'
         $'\e[36m5. \e[0mAuto Clear Cache'
         $'\e[36m6. \e[0mInstall BBR'
         $'\e[36m7. \e[0mUninstall'
         $'\e[36m0. \e[0mExit')

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
        read -p $'\e[36mPlease enter the desired ports (separated by commas): \e[0m' ports
    elif [ "$port_option" -eq 2 ]; then
        read -p $'\e[36mPlease enter the port range (e.g., 23,65535): \e[0m' port_range

        IFS=',' read -ra port_array <<< "$port_range"
        if [ "${port_array[0]}" -lt 23 -o "${port_array[1]}" -gt 65535 ]; then
            echo $'\e[33mInvalid port range. Please enter a valid range starting from 23 and up to 65535.\e[0m'
            exit
        fi
        ports=$(seq -s, "${port_array[0]}" "${port_array[1]}")
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
    echo $'\e[32mInstalling Gost latest version, please wait...\e[0m' && \
    wget https://github.com/ginuerzh/gost/releases/latest/download/gost-linux-amd64.gz && \
    echo $'\e[32mGost downloaded successfully.\e[0m' && \
    gunzip gost-linux-amd64.gz && \
    sudo mv gost-linux-amd64 /usr/local/bin/gost && \
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
            read -p $'\e[97mPlease enter the new destination Kharej IP: \e[0m' new_destination_ip

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
            echo $'\e[31
