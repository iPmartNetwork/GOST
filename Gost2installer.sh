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

if [ $(basename $(pwd)) == "GOST-Tunnel" ]; then
    ENV_MODE="development"
else
    ENV_MODE="production"
fi

GOST_VERSION="2.11.5"
GOST_GITHUB="https://github.com/ginuerzh/gost/releases/download"
GOST_LOCATION="/usr/local/bin/gost"
GOST_SERVICE="/etc/systemd/system/gost.service"

GTCTL_GITHUB="https://raw.githubusercontent.com/ipmartnetwork/GOST/master/Gost2.sh"
GTCTL_LOCATION="/usr/local/bin/gost"
INSTALLER_FILE="Gost2installer.sh"


panic() {
    echo -e "${BIRed}Panic: $1${Plain}"

    if [ $ENV_MODE == "production" ]; then
        if [ -f $INSTALLER_FILE ]; then
            rm -f $INSTALLER_FILE
        fi
    fi

    exit 1
}

error() {
    echo -e "${BIRed}$1${Plain}"
}

warning() {
    echo -e "${BIYellow}$1${Plain}"
}

log() {
    echo -e "${IWhite}$1${Plain}"
}

info() {
    echo -e "${BIBlue}$1${Plain}"
}

success() {
    echo -e "${BIGreen}$1${Plain}"
}

pair() {
    echo -e "${BIBlue}$1: ${IWhite}$2${Plain}"
}

input() {
    echo -e -n "${BIWhite}$1${Plain}"
    read $2
}

if [ $ENV_MODE == "development" ]; then
    warning "Running in development mode"
    log
fi

if [ ! -f /etc/os-release ]; then
    panic "This script must be run on a supported OS"
fi

if [ "$EUID" -ne 0 ]; then
    panic "This script must be run as root"
fi

case $(uname -m) in
x86_64 | x64 | amd64)
    arhc="amd64"
    ;;
armv8 | arm64 | aarch64)
    arhc="armv8"
    ;;
*)
    panic "This script must be run on a supported CPU architecture"
    ;;
esac

os_release=""

if [ -f /etc/os-release ]; then
    source /etc/os-release
    os_release=$ID
elif [ -f /usr/lib/os-release ]; then
    source /usr/lib/os-release
    os_release=$ID
else
    panic "This script must be run on a supported OS"
fi

os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

case $os_release in
ubuntu)
    if [ $os_version -lt 20 ]; then
        panic "This script must be run on a Ubuntu 20.04 or higher"
    fi
    ;;
centos)
    if [ $os_version -lt 8 ]; then
        panic "This script must be run on a CentOS 8 or higher"
    fi
    ;;
fedora)
    if [ $os_version -lt 36 ]; then
        panic "This script must be run on a Fedora 36 or higher"
    fi
    ;;
debian)
    if [ $os_version -lt 10 ]; then
        panic "This script must be run on a Debian 10 or higher"
    fi
    ;;
arch)

    os_release="arch"
    ;;
*)
    panic "This script must be run on a supported OS"
    ;;
esac

log
pair "OS" "$os_release $os_version"
pair "CPU Arch" $arhc
log

log "Installing dependencies ..."

case $os_release in
centos | fedora)
    yum install -y -q wget curl gzip tar
    ;;
arch)
    pacman -S --noconfirm --needed wget curl gzip tar
    ;;
*)
    apt install -y -qq wget curl gzip tar
    ;;
esac

success "Dependencies installed successfully"
log

if [ -f $GOST_LOCATION ]; then
    warning "gost is already installed"

    if [ ! -x $GOST_LOCATION ]; then
        rm -f $GOST_LOCATION
        panic "gost binary is not executable"
    fi

    curr_version=$(gost -V | awk '{print $2}')
    if [ $curr_version != $GOST_VERSION ]; then
        panic "gost version mismatch. [Expected: $GOST_VERSION, Found: $curr_version]]"
    fi

    log
else

    log "Downloading gost ..."
    package_name="gost-linux-$arhc-$GOST_VERSION.gz"
    package_url="$GOST_GITHUB/v$GOST_VERSION/$package_name"

    wget -qO- $package_name $package_url | gzip -d >$GOST_LOCATION
    chmod +x $GOST_LOCATION
    rm -f $package_name

    if [ ! -f $GOST_LOCATION ]; then
        panic "gost installation failed"
    fi

    success "gost installed successfully"
    log
fi

log "Installing Gost Tunnel Control (gost) ..."

log "Downloading gost ..."

if [ $ENV_MODE == "production" ]; then
    wget -qO $GTCTL_LOCATION $GTCTL_GITHUB
    chmod +x $GTCTL_LOCATION
else
    cp gtctl.sh $GTCTL_LOCATION
    chmod +x $GTCTL_LOCATION
fi

if [ ! -f $GTCTL_LOCATION ]; then
    panic "gtctl installation failed"
fi

success "gtctl installed successfully"
log

while true; do

    if [ ! -z $1 ]; then
        hostname=$1
    else
        input "Etern your targeted Hostname: " hostname
    fi

    if [ -z $hostname ]; then
        error "Hostname cannot be empty"
        log

        if [ ! -z $1 ]; then
            exit 1
        fi

        continue
    fi

    if ! ping -c 1 $hostname &>/dev/null; then
        panic "Host is unreachable"
    fi

    ping_ms=$(ping -c 1 $hostname | awk -F '/' 'END {print $5}')

    pair "Hostname" $hostname
    pair "Ping" "$ping_ms ms"
    log

    break
done

while true; do

    if [ ! -z $2 ]; then
        ports=""
        for port in $@; do
            if ! [[ $port =~ ^[0-9]+$ ]]; then
                continue
            fi

            if [ ! -z "$ports" ]; then
                ports+=" "
            fi

            ports+="$port"
        done
    else
        input "Enter the ports to forward (Fasele beyne port ha): " ports
    fi

    if [ -z "$ports" ]; then
        error "Ports cannot be empty"
        log

        if [ ! -z $2 ]; then
            exit 1
        fi

        continue
    fi

    if [ ! -z $2 ]; then
        pair "Ports" "$ports"
        log
    fi

    break
done

log "Creating systemd service ..."

gost_args=""
for port in $ports; do
    if [ ! -z "$gost_args" ]; then
        gost_args+=" "
    fi

    gost_args+="-L=tcp://:$port/$hostname:$port"
done

##  -F forward+ssh://$hostname:2249

systemctl stop gost.service &>/dev/null
systemctl disable gost.service &>/dev/null
systemctl daemon-reload &>/dev/null

cat >$GOST_SERVICE <<EOF
[Unit]
Description=Gost Tunnel
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5
ExecStart=$GOST_LOCATION $gost_args

[Install]
WantedBy=multi-user.target
EOF

log "Enabling and starting gost service ..."
systemctl daemon-reload
systemctl enable gost.service
systemctl start gost.service

success "gost service started successfully"
log

log
$GTCTL_LOCATION help
log

if [ $ENV_MODE == "production" ]; then
    if [ -f $INSTALLER_FILE ]; then
        rm -f $INSTALLER_FILE
    fi
fi
