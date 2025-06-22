#!/bin/bash

set -euo pipefail

# Resolve script path and chezmoi source
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SOURCE_DIR="$SCRIPT_DIR/../dotfiles"
DEST_DIR="$HOME/.local/share/chezmoi"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

log()    { echo -e "${GREEN}[+]${RESET} $1"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $1"; }
error()  { echo -e "${RED}[-]${RESET} $1"; }

# 1. Install chezmoi if not present
if ! command -v chezmoi &>/dev/null; then
    log "chezmoi is not installed!"
    exit 1
else
    log "chezmoi is already installed."
fi

# 2. Create chezmoi source dir if needed
mkdir -p "$DEST_DIR"

# 3. Initialize chezmoi Git repo if not present
if [[ ! -d "$DEST_DIR/.git" ]]; then
    warn "chezmoi is not initialized with Git."
    exit 1
fi

log "Cloning dotfiles"
git clone git@github.com:aalexmmaldonado/dotfiles.git ~/.local/share/chezmoi

# 5. Apply chezmoi config
log "Applying chezmoi configuration..."
chezmoi apply

log "chezmoi setup complete."
