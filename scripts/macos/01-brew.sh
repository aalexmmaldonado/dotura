#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# Assumes the parent script set DOTURA_OS_NAME to "macos"
PKG_DIR="$SCRIPT_DIR/../../pkg/$DOTURA_OS_NAME"

# Define paths for Homebrew package lists
BREW_LIST="$PKG_DIR/brew.txt"
CASK_LIST="$PKG_DIR/cask.txt"

# Colors for output
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

log()    { echo -e "${GREEN}[+]${RESET} $1"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $1"; }
error()  { echo -e "${RED}[-]${RESET} $1"; }

# Check if package lists exist
[[ -f $BREW_LIST ]] || { error "Missing $BREW_LIST"; exit 1; }
[[ -f $CASK_LIST ]] || { error "Missing $CASK_LIST"; exit 1; }

# Ensure Homebrew is installed
if ! command -v brew &>/dev/null; then
    log "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to the PATH for the current script's execution
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    log "Homebrew is already installed."
fi

log "Updating Homebrew and upgrading packages..."
brew update
brew upgrade

log "Installing command-line tools (formulae)..."
if [[ -s $BREW_LIST ]]; then
    # Homebrew automatically handles the "needed" logic
    brew install $(< "$BREW_LIST")
else
    warn "No formulae listed in $BREW_LIST"
fi

log "Installing GUI applications (casks)..."
if [[ -s $CASK_LIST ]]; then
    brew install --cask $(< "$CASK_LIST")
else
    warn "No casks listed in $CASK_LIST"
fi

log "Package installation complete"