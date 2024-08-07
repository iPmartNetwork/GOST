#!/bin/bash

if [ $(basename $(pwd)) == "GOST" ]; then
    ENV_MODE="development"
else
    ENV_MODE="production"
fi

GOST_LOCATION="/usr/local/bin/gost"
GOST_SERVICE="/etc/systemd/system/gost.service"
Gost_LOCATION="/usr/local/bin/gost"
INSTALLER="https://raw.githubusercontent.com/ipmartnetwork/GOST/master/Gost2installer.sh"

panic() {
    echo -e "${BIRed}Panic: $1${Plain}"
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

if [ ! -f $GOST_LOCATION ]; then
    warning "Gost is not installed"
fi

if [ "$1" == "help" ] || [ -z "$1" ]; then
    pair "Usage" "gost [command]"
    info ""
    info "Commands:"
    info "  info        ${Plain}Show current config info"
    info "  start       ${Plain}Start"
    info "  stop        ${Plain}Stop"
    info "  restart     ${Plain}Restart"
    info "  status      ${Plain}Show gost"
    info "  uninstall   ${Plain}Uninstall"
    info "  update      ${Plain}Update"
    info "  help        ${Plain}Show this help message"

    log
    exit 0
fi

if [ "$1" == "info" ]; then
    if [ ! -f $GOST_SERVICE ]; then
        panic "gost service file not found"
    fi

    info "Current config info:"
    service=$(cat $GOST_SERVICE)
    Hostname=$(echo $service | cut -d ':' -f 3 | cut -d '/' -f 2)
    Ports=$(echo $service | grep -Eo ':[0-9\.]+' | awk '!seen[$0]++' | sed ':a;N;$!ba;s/\n/ /g' | sed 's/[\:]*//g')

    # remove port 2249 from ports
    Ports=$(echo $Ports | sed 's/2249//g')

    pair "Hostname" "$Hostname"
    pair "Ports" "$Ports"

    log
    exit 0
fi

if [ "$1" == "start" ]; then
    if [ -f $GOST_SERVICE ]; then
        systemctl start gost.service
        systemctl daemon-reload
        success "gost started successfully"
    else
        panic "gost service file not found"
    fi

    log
    exit 0
fi

if [ "$1" == "stop" ]; then
    if [ -f $GOST_SERVICE ]; then
        systemctl stop gost.service
        systemctl daemon-reload
        success "gost stopped successfully"
    else
        panic "gost service file not found"
    fi

    log
    exit 0
fi

if [ "$1" == "restart" ]; then
    if [ -f $GOST_SERVICE ]; then
        systemctl restart gost.service
        systemctl daemon-reload
        success "gost restarted successfully"
    else
        panic "gost service file not found"
    fi

    log
    exit 0
fi

if [ "$1" == "status" ]; then
    if [ -f $GOST_SERVICE ]; then
        systemctl status gost.service
    else
        panic "gost service file not found"
    fi

    log
    exit 0
fi

if [ "$1" == "uninstall" ]; then
    if [ -f $GOST_SERVICE ]; then
        systemctl stop gost.service
        systemctl disable gost.service
        rm -f $GOST_SERVICE
        systemctl daemon-reload
    fi

    if [ -f $GOST_LOCATION ]; then
        rm -f $GOST_LOCATION
    fi

    if [ -f $Gost_LOCATION ]; then
        rm -f $Gost_LOCATION
    fi

    success "uninstalled successfully"
    log
    exit 0
fi

if [ "$1" == "update" ]; then
    service=$(cat $GOST_SERVICE)
    Hostname=$(echo $service | cut -d ':' -f 3 | cut -d '/' -f 2)
    Ports=$(echo $service | grep -Eo ':[0-9\.]+' | awk '!seen[$0]++' | sed ':a;N;$!ba;s/\n/ /g' | sed 's/[\:]*//g')

    # remove port 2249 from ports
    Ports=$(echo $Ports | sed 's/2249//g')

    if [ -f $GOST_SERVICE ]; then
        systemctl stop gost.service
        systemctl daemon-reload
    fi

    if [ -f $GOST_LOCATION ]; then
        rm -f $GOST_LOCATION
    fi

    if [ $ENV_MODE == "production" ]; then
        bash <(curl -Ls $INSTALLER) $Hostname $Ports
    else
        bash install.sh $Hostname $Ports
    fi

    log
    exit 0
fi
