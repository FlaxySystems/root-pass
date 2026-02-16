#!/bin/bash

# ==========================================
#        FlaxySystems VPS Toolkit v5
# ==========================================

LOG_FILE="/var/log/flaxy-toolkit.log"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# Root Check
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Please run as root (sudo -i first)${RESET}"
    exit 1
fi

# Logging
exec > >(tee -a $LOG_FILE) 2>&1

pause() {
    echo ""
    read -p "Press Enter to continue..."
}

restart_ssh() {
    if sshd -t 2>/dev/null; then
        systemctl restart ssh 2>/dev/null || systemctl restart sshd
        echo -e "${GREEN}SSH Restarted Successfully${RESET}"
    else
        echo -e "${RED}SSH Config Error! Fix manually before restart.${RESET}"
    fi
}

enable_root() {
    echo -e "${YELLOW}Enabling Root SSH Login...${RESET}"

    sed -i '/^PermitRootLogin/d' /etc/ssh/sshd_config
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

    sed -i '/^PasswordAuthentication/d' /etc/ssh/sshd_config
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

    echo -e "${YELLOW}Set / Change Root Password:${RESET}"
    passwd root

    restart_ssh

    echo -e "${GREEN}Root SSH Enabled & Password Set Successfully${RESET}"
    pause
}

disable_root() {
    sed -i '/^PermitRootLogin/d' /etc/ssh/sshd_config
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    restart_ssh
    echo -e "${GREEN}Root SSH Disabled${RESET}"
    pause
}

create_user() {
    read -p "Enter new username: " USERNAME
    adduser $USERNAME
    usermod -aG sudo $USERNAME
    echo -e "${GREEN}User $USERNAME created with sudo access${RESET}"
    pause
}

remove_user() {
    read -p "Enter username to remove: " USERNAME
    deluser --remove-home $USERNAME
    echo -e "${GREEN}User $USERNAME removed${RESET}"
    pause
}

secure_ssh() {
    sed -i '/^PasswordAuthentication/d' /etc/ssh/sshd_config
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    restart_ssh
    echo -e "${GREEN}Password login disabled (Key Only Mode)${RESET}"
    pause
}

update_server() {
    apt update && apt upgrade -y
    echo -e "${GREEN}Server Updated Successfully${RESET}"
    pause
}

check_ports() {
    echo -e "${CYAN}Open Ports:${RESET}"
    ss -tulpn
    pause
}

system_info() {
    clear
    echo -e "${CYAN}========= System Information =========${RESET}"
    echo "Hostname : $(hostname)"
    echo "Uptime   : $(uptime -p)"
    echo "Kernel   : $(uname -r)"
    echo "CPU      : $(lscpu | awk -F: '/Model name/ {print $2}')"
    echo ""
    echo "RAM Usage:"
    free -h
    echo ""
    echo "Disk Usage:"
    df -h | grep '^/dev/'
    echo ""
    echo "Public IP:"
    curl -s ifconfig.me
    echo ""
    pause
}

ram_checker() {
    clear
    echo -e "${CYAN}========= RAM Detailed Info =========${RESET}"

    TOTAL_RAM=$(free -h | awk '/Mem:/ {print $2}')
    USED_RAM=$(free -h | awk '/Mem:/ {print $3}')
    FREE_RAM=$(free -h | awk '/Mem:/ {print $4}')

    VIRT_TYPE=$(systemd-detect-virt)

    if [ "$VIRT_TYPE" != "none" ]; then
        RAM_TYPE="Virtualized RAM ($VIRT_TYPE)"
        RAM_SPEED="Not Available"
    else
        if ! command -v dmidecode &> /dev/null; then
            apt update -y >/dev/null 2>&1
            apt install dmidecode -y >/dev/null 2>&1
        fi
        RAM_TYPE=$(dmidecode -t memory | awk -F: '/^\s*Type: DDR/ {print $2; exit}' | xargs)
        RAM_SPEED=$(dmidecode -t memory | awk -F: '/Speed:/ && $2 !~ /Unknown/ {print $2; exit}' | xargs)
    fi

    SLOT_COUNT=$(dmidecode -t memory 2>/dev/null | grep -c "Memory Device")

    echo ""
    echo "Virtualization : $VIRT_TYPE"
    echo "Total RAM      : $TOTAL_RAM"
    echo "Used RAM       : $USED_RAM"
    echo "Free RAM       : $FREE_RAM"

    if [ -z "$RAM_TYPE" ]; then
        echo "RAM Type       : Unable to detect"
    else
        echo "RAM Type       : $RAM_TYPE"
    fi

    if [ -z "$RAM_SPEED" ]; then
        echo "RAM Speed      : Not Available"
    else
        echo "RAM Speed      : $RAM_SPEED"
    fi

    echo "Memory Slots   : $SLOT_COUNT"
    pause
}

menu() {
    clear
    echo -e "${CYAN}"
    echo "========================================="
    echo "        FlaxySystems VPS Toolkit        "
    echo "========================================="
    echo -e "${RESET}"
    echo "1) Enable Root SSH (with Password)"
    echo "2) Disable Root SSH"
    echo "3) Create Sudo User"
    echo "4) Remove User"
    echo "5) Secure SSH (Key Only)"
    echo "6) System Information"
    echo "7) RAM Checker (Advanced)"
    echo "8) Check Open Ports"
    echo "9) Update Server"
    echo "10) Exit"
    echo ""
}

while true; do
    menu
    read -p "Select option [1-10]: " choice
    case $choice in
        1) enable_root ;;
        2) disable_root ;;
        3) create_user ;;
        4) remove_user ;;
        5) secure_ssh ;;
        6) system_info ;;
        7) ram_checker ;;
        8) check_ports ;;
        9) update_server ;;
        10) exit 0 ;;
        *) echo -e "${RED}Invalid Option!${RESET}"; sleep 1 ;;
    esac
done
