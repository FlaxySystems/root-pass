#!/bin/bash

LOG_FILE="/var/log/flaxy-root-tool.log"
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Run as root!${RESET}"
    exit 1
fi

exec > >(tee -a $LOG_FILE) 2>&1

pause() {
    read -p "Press Enter to continue..."
}

enable_root() {
    sed -i '/^PermitRootLogin/d' /etc/ssh/sshd_config
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    sshd -t && systemctl restart ssh 2>/dev/null || systemctl restart sshd
    echo -e "${GREEN}Root SSH Enabled${RESET}"
    pause
}

disable_root() {
    sed -i '/^PermitRootLogin/d' /etc/ssh/sshd_config
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    sshd -t && systemctl restart ssh 2>/dev/null || systemctl restart sshd
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

system_info() {
    echo -e "${CYAN}System Information:${RESET}"
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime -p)"
    echo "RAM Usage:"
    free -h
    echo "CPU Info:"
    lscpu | grep "Model name"
    echo "Public IP:"
    curl -s ifconfig.me
    pause
}

secure_ssh() {
    sed -i '/^PasswordAuthentication/d' /etc/ssh/sshd_config
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    sshd -t && systemctl restart ssh 2>/dev/null || systemctl restart sshd
    echo -e "${GREEN}Password login disabled (Key only login active)${RESET}"
    pause
}

update_server() {
    apt update && apt upgrade -y
    echo -e "${GREEN}Server Updated Successfully${RESET}"
    pause
}

check_ports() {
    ss -tulpn
    pause
}

menu() {
    clear
    echo -e "${CYAN}"
    echo "====================================="
    echo "      FlaxySystems Admin Tool       "
    echo "====================================="
    echo -e "${RESET}"
    echo "1) Enable Root SSH"
    echo "2) Disable Root SSH"
    echo "3) Create Sudo User"
    echo "4) Remove User"
    echo "5) Show System Info"
    echo "6) Secure SSH (Key Only)"
    echo "7) Update Server"
    echo "8) Check Open Ports"
    echo "9) Exit"
    echo ""
}

while true; do
    menu
    read -p "Select option [1-9]: " choice
    case $choice in
        1) enable_root ;;
        2) disable_root ;;
        3) create_user ;;
        4) remove_user ;;
        5) system_info ;;
        6) secure_ssh ;;
        7) update_server ;;
        8) check_ports ;;
        9) exit 0 ;;
        *) echo -e "${RED}Invalid Option!${RESET}"; sleep 1 ;;
    esac
done
