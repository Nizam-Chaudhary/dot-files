#!/bin/bash

# This script is used to setup archlinux with hyprland configuration
# Author: https://github.com/The-Repo-Club
# License: MIT

# Check if the script is being run as root
# if [[ $EUID -ne 0 ]]; then
#    echo "This script must be run as root" 1>&2
#    exit 1
# fi

echo "Welcome to the Arch Linux Hyprland Setup Script"
echo "This script will install the necessary packages and configure the desktop environment."
echo "Please make sure you have a backup of your files before running this script."
read -p "Do you want to take backup of your config? (y/n): " choice
if [[ $choice == "y" || $choice == "Y" ]]; then
    echo "Backing up config..."
    mkdir -p ~/config-backup/
    cp -r ~/.config/hypr ~/config-backup/
    cp -r ~/.config/waybar ~/config-backup/
    cp -r ~/.config/alacritty ~/config-backup/
    cp -r ~/.config/kitty ~/config-backup/
    cp -r ~/.zshrc ~/config-backup/zshrc/
    cp -r ~/.bashrc ~/config-backup/bashrc/
    cp -r ~/.config/nvim ~/config-backup/
    cp -r ~/.config/starship.toml ~/config-backup/starship/
    cp -r ~/.config/wofi ~/config-backup/
    echo "Backup taken"
else
    echo "Continuing at your risk"
fi
read -p "Press [Enter] to continue..."

# Install yay
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si
    rm -rf yay-bin
fi

# Install the necessary packages
yay -Syyu --noconfirm
yay -S --noconfirm --needed \
    hyprland \
    hyprlock \
    hypridle \
    hyprpaper \
    starship \
    waybar \
    wofi \
    dunst \
    rofi \
    feh \
    fastfetch \
    firefox \
    ttf-font-awesome \
    ttf-cascadia-code-nerd \
    ttf-jetbrains-mono-nerd \
    kitty \
    zsh \
    zsh-autosuggestions \
    zsh-completions \
    fzf \
    # ranger

cd ~/config-files
echo "Applying configuration files..."
stow alacritty backgrounds basrhc hyprland \
  hyprlock hyprpaper hyprmocha kitty wofi zshrc \
  starship waybar \
