#!/bin/bash
set -euo pipefail

# Update repo
git pull
git submodule update --init --recursive

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$SCRIPT_DIR/scripts"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

log()   { echo -e "${GREEN}[+]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $1"; }
error() { echo -e "${RED}[-]${RESET} $1"; }

if [[ ! -d "$SCRIPTS_PATH" ]]; then
    error "Script directory not found: $SCRIPTS_PATH"
    exit 1
fi

log "Running install scripts from: $SCRIPTS_PATH"

# Get sorted list of scripts: 01-xxx.sh, 02-xxx.sh, ...
mapfile -t scripts < <(find "$SCRIPTS_PATH" -maxdepth 1 -type f -name '[0-9][0-9]*-*.sh' | sort)

if [[ ${#scripts[@]} -eq 0 ]]; then
    warn "No scripts found to run in $SCRIPTS_PATH"
    exit 0
fi

for script in "${scripts[@]}"; do
    name="$(basename "$script")"
    log "Running $name..."
    if bash "$script"; then
        log "$name completed successfully"
    else
        error "$name failed. Exiting."
        exit 1
    fi
done

log "All setup scripts completed successfully."
