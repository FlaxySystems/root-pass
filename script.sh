#!/bin/bash

# ==============================
# Root SSH Enable Script
# ==============================

set -e

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

echo -e "${GREEN}=====================================${RESET}"
echo -e "${GREEN}   Root SSH Enable Script Starting   ${RESET}"
echo -e "${GREEN}=====================================${RESET}"

# Must be root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Please run as root (sudo -i first)${RESET}"
   exit 1
fi

# Backup ssh config
echo -e "${YELLOW}Backing up sshd_config...${RESET}"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%F-%T)

# Enable root login
echo -e "${YELLOW}Enabling PermitRootLogin...${RESET}"
if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
else
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
fi

# Enable password authentication
echo -e "${YELLOW}Enabling PasswordAuthentication...${RESET}"
if grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
else
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
fi

# Set root password
echo -e "${YELLOW}Set new root password:${RESET}"
passwd root

# Restart SSH service
echo -e "${YELLOW}Restarting SSH service...${RESET}"
systemctl restart ssh 2>/dev/null || systemctl restart sshd

echo -e "${GREEN}=====================================${RESET}"
echo -e "${GREEN} Root SSH Login Successfully Enabled ${RESET}"
echo -e "${GREEN}=====================================${RESET}"
