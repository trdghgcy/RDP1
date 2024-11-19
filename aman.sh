#!/bin/bash

# Set default values
username="user"
password="root"
chrome_remote_desktop_url="https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb"

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Function to install packages
install_package() {
    package_url=$1
    log "Downloading $package_url"
    wget -q --show-progress "$package_url" -O "$(basename "$package_url")"
    
    if [[ $? -ne 0 ]]; then
        log "Failed to download $(basename "$package_url")"
        exit 1
    fi

    log "Installing $(basename "$package_url")"
    sudo dpkg --install "$(basename "$package_url")"

    if [[ $? -ne 0 ]]; then
        log "Failed to install $(basename "$package_url")"
        log "Fixing broken dependencies"
        sudo apt-get install --fix-broken -y
    fi

    rm "$(basename "$package_url")"
}

# Installation steps
log "Starting installation"

# Create user
log "Creating user '$username'"
if ! sudo useradd -m "$username"; then
    log "Failed to create user '$username'"
    exit 1
fi

echo "$username:$password" | sudo chpasswd

if [[ $? -ne 0 ]]; then
    log "Failed to set password for user '$username'"
    exit 1
fi

sudo sed -i 's//bin/sh//bin/bash/g' /etc/passwd

# Install Chrome Remote Desktop
install_package "$chrome_remote_desktop_url"

# Install XFCE desktop environment
log "Installing XFCE desktop environment"
if ! sudo DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes -y xfce4 desktop-base dbus-x11 xscreensaver; then
    log "Failed to install XFCE desktop environment"
    exit 1
fi

# Set up Chrome Remote Desktop session
log "Setting up Chrome Remote Desktop session"
echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" | sudo tee /etc/chrome-remote-desktop-session > /dev/null

# Disable lightdm service
log "Disabling lightdm service"
if ! sudo systemctl disable lightdm.service; then
    log "Failed to disable lightdm service"
    exit 1
fi

# Install Firefox ESR
log "Installing Firefox ESR"
if ! sudo apt update; then
    log "Failed to update package list"
    exit 1
fi

if ! sudo apt install -y firefox-esr; then
    log "Failed to install Firefox ESR"
    exit 1
fi

log "Installation completed successfully"