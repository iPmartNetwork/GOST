#!/bin/bash

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
         $'\e[36m6. \e[0mUninstall'
         $'\e[36m0. \e[0mExit')

# Print prompt and options with cyan color
printf "\e[33mPlease Choice Your Options:\e[0m\n"
printf "%s\n" "${options[@]}"

# Read user input with white color
read -p $'\e[97mYour choice: \e[0m' choice

# If option 1 or 2 is selected
if [ "$choice" -eq 2 ] || [ "$choice" -eq 3 ]; then

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
        echo $'\e[31mInvalid option. Exit...\e[0m'
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
if [ "$gost_version_choice" -eq 2 ]; then
    echo $'\e[32mInstalling Gost version 3.0.0, please wait...\e[0m'
    wget -O /tmp/gost.tar.gz https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20240704/gost_3.0.0-nightly.20240704_linux_amd64.tar.gz
    tar -xvzf /tmp/gost.tar.gz -C /usr/local/bin/
    chmod +x /usr/local/bin/gost
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
    # Check if Gost is installed
    if command -v gost &>/dev/null; then
        echo $'\e[32mGost is installed. Checking configuration and status...\e[0m'
        
        # Check Gost configuration and status
        systemctl list-unit-files | grep -q "gost_"
        if [ $? -eq 0 ]; then
            echo $'\e[32mGost is configured and active.\e[0m'
            
            # Get and display used IPs and ports
            for service_file in /usr/lib/systemd/system/gost_*.service; do
                # Extract the IP, port, and protocol information using awk
                service_info=$(awk -F'[-=:/\\[\\]]+' '/ExecStart=/ {print $14,$15,$22,$20,$23}' "$service_file")

                # Split the extracted information into an array
                read -a info_array <<< "$service_info"

                # Display IP, port, and protocol information with corrected port range
                echo -e "\e[97mIP:\e[0m ${info_array[0]} \e[97mPort:\e[0m ${info_array[1]},... \e[97mProtocol:\e[0m ${info_array[2]}"

            done
        else
            echo $'\e[33mGost is installed, but not configured or active.\e[0m'
        fi
    else
        echo $'\e[33mGost Tunnel is not installed. \e[0m'
    fi

    read -n 1 -s -r -p $'\e[36m0. \e[0mBack to menu: \e[0m' choice

if [ "$choice" -eq 0 ]; then
    bash "$0"
fi

# If option 4 is selected
elif [ "$choice" -eq 4 ]; then
    echo $'\e[32mChoose Auto Restart option:\e[0m'
    echo $'\e[36m1. \e[0mEnable Auto Restart'
    echo $'\e[36m2. \e[0mDisable Auto Restart'

    # Read user input for Auto Restart option
    read -p $'\e[97mYour choice: \e[0m' auto_restart_option

    # Process user choice for Auto Restart
    case "$auto_restart_option" in
        1)
            # Logic to enable Auto Restart
            echo $'\e[32mAuto Restart Enabled.\e[0m'
            # Remove any existing scheduled restart using 'at' command
            sudo at -l | awk '{print $1}' | xargs -I {} atrm {}
            # Prompt the user for the restart time in hours
            read -p $'\e[97mEnter the restart time in hours: \e[0m' restart_time_hours

            # Convert hours to minutes
            restart_time_minutes=$((restart_time_hours * 60))

            # Write a script to restart Gost
            echo -e "#!/bin/bash\n\nsudo systemctl daemon-reload\nsudo systemctl restart gost_*.service" | sudo tee /usr/bin/auto_restart_cronjob.sh > /dev/null

            # Give execute permission to the script
            sudo chmod +x /usr/bin/auto_restart_cronjob.sh

            # Remove any existing cron job for Auto Restart
            crontab -l | grep -v '/usr/bin/auto_restart_cronjob.sh' | crontab -

            # Write a new cron job to execute the script at the specified intervals
            (crontab -l ; echo "0 */$restart_time_hours * * * /usr/bin/auto_restart_cronjob.sh") | crontab -

            echo $'\e[32mAuto Restart scheduled successfully.\e[0m'
            ;;
        2)
            # Logic to disable Auto Restart
            echo $'\e[32mAuto Restart Disabled.\e[0m'
            # Remove the script and cron job for Auto Restart
            sudo rm -f /usr/bin/auto_restart_cronjob.sh
            crontab -l | grep -v '/usr/bin/auto_restart_cronjob.sh' | crontab -

            echo $'\e[32mAuto Restart disabled successfully.\e[0m'
            ;;
        *)
            echo $'\e[31mInvalid choice. Exiting...\e[0m'
            exit
            ;;
    esac
 bash "$0"
fi

# If option 5 is selected
if [ "$choice" -eq 5 ]; then
    echo $'\e[32mChoose Auto Clear Cache option:\e[0m'
    echo $'\e[36m1. \e[0mEnable Auto Clear Cache'
    echo $'\e[36m2. \e[0mDisable Auto Clear Cache'

    # Read user input for Auto Clear Cache option
    read -p $'\e[97mYour choice: \e[0m' auto_clear_cache_option

    # Process user choice for Auto Clear Cache
    case "$auto_clear_cache_option" in
        1)
            # Enable Auto Clear Cache
            enable_auto_clear_cache() {
                echo $'\e[32mAuto Clear Cache Enabled.\e[0m'
                
                # Prompt user to choose the interval in days
                read -p $'\e[97mEnter the interval in days (e.g., 1 for daily, 7 for weekly): \e[0m' interval_days
                
                # Set up the cron job based on the interval
                cron_interval="0 0 */$interval_days * *"

                # Write a new cron job to execute the cache clearing commands at the specified interval
                (crontab -l 2>/dev/null; echo "$cron_interval sync; echo 1 > /proc/sys/vm/drop_caches && sync; echo 2 > /proc/sys/vm/drop_caches && sync; echo 3 > /proc/sys/vm/drop_caches") | crontab -

                echo $'\e[32mAuto Clear Cache scheduled successfully.\e[0m'
            }

            # Call the function to enable Auto Clear Cache
            enable_auto_clear_cache
            ;;
        2)
            # Disable Auto Clear Cache
            disable_auto_clear_cache() {
                echo $'\e[32mAuto Clear Cache Disabled.\e[0m'
                
                # Remove only the cron job related to auto clearing cache
                crontab -l | grep -v "drop_caches" | crontab -

                echo $'\e[32mAuto Clear Cache disabled successfully.\e[0m'
            }

            # Call the function to disable Auto Clear Cache
            disable_auto_clear_cache
            ;;
        *)
            echo $'\e[31mInvalid choice. Exiting...\e[0m'
            exit
            ;;
    esac
 bash "$0"
fi

# If option 6 is selected
elif [ "$choice" -eq 6 ]; then
    # Countdown for uninstallation in a single line
    echo $'\e[32mUninstalling Gost in 3 seconds... \e[0m' && sleep 1 && echo $'\e[32m2... \e[0m' && sleep 1 && echo $'\e[32m1... \e[0m' && sleep 1 && { sudo rm -f /usr/local/bin/gost && sudo rm -f /usr/lib/systemd/system/gost.service && echo $'\e[32mGost successfully uninstalled.\e[0m'; }

# If option 0 is selected
elif [ "$choice" -eq 0 ]; then
    echo $'\e[32mYou have exited the script.\e[0m'
    exit
fi
