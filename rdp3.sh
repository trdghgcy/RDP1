#!/bin/bash

# Set default username and password
username="user"
password="root"

# Set default CRP value
CRP=""

# Set default Pin value
Pin="123456"

# Set default Autostart value
Autostart=true

echo "Creating User and Setting it up"
if ! sudo useradd -m "$username"; then
    echo "Failed to create user $username"
    exit 1
fi

if ! sudo adduser "$username" sudo; then
    echo "Failed to add user $username to sudo group"
    exit 1
fi

echo "$username:$password" | sudo chpasswd
sudo sed -i 's//bin/sh//bin/bash/g' /etc/passwd
echo "User created and configured with username '$username' and password '$password'"

echo "Installing necessary packages"
sudo apt update
if ! sudo apt install -y xfce4 desktop-base xfce4-terminal tightvncserver wget; then
    echo "Failed to install necessary packages"
    exit 1
fi

echo "Setting up Chrome Remote Desktop"
echo "Installing Chrome Remote Desktop"
wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb -O chrome-remote-desktop.deb
if ! sudo dpkg --install chrome-remote-desktop.deb; then
    echo "Failed to install Chrome Remote Desktop"
    exit 1
fi

sudo apt install --assume-yes --fix-broken

echo "Installing Desktop Environment"
export DEBIAN_FRONTEND=noninteractive
if ! sudo apt install --assume-yes xfce4 desktop-base xfce4-terminal; then
    echo "Failed to install XFCE desktop environment"
    exit 1
fi

echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" | sudo tee /etc/chrome-remote-desktop-session > /dev/null
sudo apt remove --assume-yes gnome-terminal
sudo apt install --assume-yes xscreensaver
sudo systemctl disable lightdm.service

echo "Installing Google Chrome"
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O google-chrome.deb
if ! sudo dpkg --install google-chrome.deb; then
    echo "Failed to install Google Chrome"
    exit 1
fi

sudo apt install --assume-yes --fix-broken

# Prompt user for CRP value
read -p "Enter CRP value: " CRP

echo "Finalizing"
if [ "$Autostart" = true ]; then
    mkdir -p "/home/$username/.config/autostart"
    link="https://youtu.be/d9ui27vVePY?si=TfVDVQOd0VHjUt_b"
    colab_autostart="[Desktop Entry]\nType=Application\nName=Colab\nExec=sh -c 'sensible-browser $link'\nIcon=\nComment=Open a predefined notebook at session signin.\nX-GNOME-Autostart-enabled=true"
    echo -e "$colab_autostart" | sudo tee "/home/$username/.config/autostart/colab.desktop" > /dev/null
    sudo chmod +x "/home/$username/.config/autostart/colab.desktop"
    sudo chown -R "$username:$username" "/home/$username/.config"
fi

sudo adduser "$username" chrome-remote-desktop

# Start Chrome Remote Desktop service with the provided CRP and Pin
command="$CRP --pin=$Pin"
sudo -u "$username" sh -c "$command"

# Start the Chrome Remote Desktop service
sudo service chrome-remote-desktop start

echo "Finished Successfully"
while true; do sleep 10; done