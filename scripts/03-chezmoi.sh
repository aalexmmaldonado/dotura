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
    read -rp "Initialize a Git repo in $DEST_DIR? [y/N] " init_git
    if [[ "$init_git" =~ ^[Yy]$ ]]; then
        git -C "$DEST_DIR" init
        log "Initialized Git repo in chezmoi directory."
    else
        warn "Skipping Git initialization."
    fi
fi

# 4. Copy files with conflict checking
log "Importing files from $SOURCE_DIR to $DEST_DIR..."

copy_file() {
    local src="$1"
    local rel="${src#$SOURCE_DIR/}"
    local dst="$DEST_DIR/$rel"

    mkdir -p "$(dirname "$dst")"

    if [[ -f "$dst" ]]; then
        if ! diff -q "$src" "$dst" &>/dev/null; then
            echo -e "${YELLOW}[~]${RESET} File differs: $rel"
            diff --color=always -u "$dst" "$src" || true
            read -rp "Overwrite this file? [y/N] " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                cp "$src" "$dst"
                log "Overwritten: $rel"
            else
                warn "Skipped: $rel"
            fi
        else
            log "Unchanged: $rel"
        fi
    else
        cp "$src" "$dst"
        log "Copied new file: $rel"
    fi
}

find "$SOURCE_DIR" -type f | while read -r file; do
    copy_file "$file"
done

# 5. Apply chezmoi config
log "Applying chezmoi configuration..."
chezmoi apply

# 6. Optionally commit and push
if [[ -d "$DEST_DIR/.git" ]]; then
    read -rp "Commit and push changes to Git? [y/N] " push_git
    if [[ "$push_git" =~ ^[Yy]$ ]]; then
        git -C "$DEST_DIR" add .
        git -C "$DEST_DIR" commit -m "Update chezmoi files"
        if git -C "$DEST_DIR" remote | grep -q origin; then
            git -C "$DEST_DIR" push
            log "Pushed changes to origin."
        else
            warn "No remote configured. Skipping push."
        fi
    else
        warn "Skipped Git commit and push."
    fi
fi

log "chezmoi setup complete."
