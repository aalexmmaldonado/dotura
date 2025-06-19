#!/bin/bash
set -euo pipefail

SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

log()   { echo -e "${GREEN}[+]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $1"; }
error() { echo -e "${RED}[-]${RESET} $1"; }

generate_key() {
    local service="$1"
    local filename="$SSH_DIR/id_ed25519_$service"
    local email="${USER}@$(hostname)"

    if [[ -f "$filename" ]]; then
        warn "Key already exists for $service: $filename"
    else
        log "Generating SSH key for $service..."
        ssh-keygen -t ed25519 -C "$email ($service)" -f "$filename" -N ""
    fi

    echo
    log "Public key for $service:"
    echo
    cat "${filename}.pub"
    echo
}

add_to_agent() {
    if ! pgrep -u "$USER" ssh-agent > /dev/null; then
        warn "No ssh-agent running. Starting one..."
        eval "$(ssh-agent -s)"
    fi

    ssh-add "$1"
    log "Added $1 to ssh-agent."
}

# Services to setup
for service in github gitlab tor; do
    generate_key "$service"

    read -rp "Add key for $service to ssh-agent? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        add_to_agent "$SSH_DIR/id_ed25519_${service}"
    else
        warn "Skipped adding $service key to ssh-agent."
    fi
done

log "SSH key setup complete."

