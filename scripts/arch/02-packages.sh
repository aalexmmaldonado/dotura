#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PKG_DIR="$SCRIPT_DIR/../../pkg/$DOTURA_OS_NAME"

PACMAN_LIST="$PKG_DIR/pacman.txt"
AUR_LIST="$PKG_DIR/aur.txt"

# Colors for output
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

log()    { echo -e "${GREEN}[+]${RESET} $1"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $1"; }
error()  { echo -e "${RED}[-]${RESET} $1"; }

# Check if package lists exist
[[ -f $PACMAN_LIST ]] || { error "Missing $PACMAN_LIST"; exit 1; }
[[ -f $AUR_LIST ]] || { error "Missing $AUR_LIST"; exit 1; }

log "Updating system and installing pacman packages..."
sudo pacman -Syu --noconfirm

if [[ -s $PACMAN_LIST ]]; then
    sudo pacman -S --noconfirm --needed $(< "$PACMAN_LIST")
else
    warn "No pacman packages listed in $PACMAN_LIST"
fi

# Ensure yay is installed
if ! command -v yay &>/dev/null; then
    log "yay not found. Installing yay from AUR..."
    temp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$temp_dir"
    pushd "$temp_dir" > /dev/null
    makepkg -si --noconfirm
    popd > /dev/null
    rm -rf "$temp_dir"
else
    log "yay is already installed."
fi

log "Installing AUR packages..."
if [[ -s $AUR_LIST ]]; then
    yay -S --noconfirm --needed $(< "$AUR_LIST")
else
    warn "No AUR packages listed in $AUR_LIST"
fi

log "Package installation complete."
