#!/bin/bash

# ==========================================
#   FlaxySystems Root Management Script
# ==========================================

LOG_FILE="/var/log/flaxy-root-tool.log"
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
    read -p "Press Enter to continue..."
}

enable_root_ssh() {
    echo -e "${YELLOW}Enabling Root SSH Login...${RESET}"

    SSHD_CONFIG="/etc/ssh/sshd_config"

    cp $SSHD_CONFIG ${SSHD_CONFIG}.bak.$(date +%F-%H%M%S)

    sed -i '/^PermitRootLogin/d' $SSHD_CONFIG
    sed -i '/^PasswordAuthentication/d' $SSHD_CONFIG

    echo "PermitRootLogin yes" >> $SSHD_CONFIG
    echo "PasswordAuthentication yes" >> $SSHD_CONFIG

    passwd root

    sshd -t && systemctl restart ssh 2>/dev/null || systemctl restart sshd

    echo -e "${GREEN}Root SSH Enabled Successfully!${RESET}"
    pause
}

disable_root_ssh() {
    echo -e "${YELLOW}Disabling Root SSH Login...${RESET}"

    SSHD_CONFIG="/etc/ssh/sshd_config"

    sed -i '/^PermitRootLogin/d' $SSHD_CONFIG
    echo "PermitRootLogin no" >> $SSHD_CONFIG

    sshd -t && systemctl restart ssh 2>/dev/null || systemctl restart sshd

    echo -e "${GREEN}Root SSH Disabled Successfully!${RESET}"
    pause
}

change_ssh_port() {
    read -p "Enter new SSH port: " NEWPORT

    SSHD_CONFIG="/etc/ssh/sshd_config"
    sed -i '/^Port/d' $SSHD_CONFIG
    echo "Port $NEWPORT" >> $SSHD_CONFIG

    sshd -t && systemctl restart ssh 2>/dev/null || systemctl restart sshd

    echo -e "${GREEN}SSH Port Changed to $NEWPORT${RESET}"
    pause
}

install_fail2ban() {
    echo -e "${YELLOW}Installing Fail2Ban...${RESET}"
    apt update -y
    apt install fail2ban -y
    systemctl enable fail2ban
    systemctl start fail2ban
    echo -e "${GREEN}Fail2Ban Installed Successfully!${RESET}"
    pause
}

show_menu() {
    clear
    echo -e "${CYAN}"
    echo "========================================="
    echo "      FlaxySystems Root Tool v1.0       "
    echo "========================================="
    echo -e "${RESET}"
    echo "1) Enable Root SSH Login"
    echo "2) Disable Root SSH Login"
    echo "3) Change SSH Port"
    echo "4) Install Fail2Ban"
    echo "5) Exit"
    echo ""
}

while true; do
    show_menu
    read -p "Select an option [1-5]: " choice
    case $choice in
        1) enable_root_ssh ;;
        2) disable_root_ssh ;;
        3) change_ssh_port ;;
        4) install_fail2ban ;;
        5) exit 0 ;;
        *) echo -e "${RED}Invalid Option!${RESET}"; sleep 1 ;;
    esac
done
