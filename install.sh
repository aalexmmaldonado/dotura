#!/bin/bash

set -euo pipefail

# Update repo
git pull
git submodule update --init --recursive

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

log()   { echo -e "${GREEN}[+]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $1"; }
error() { echo -e "${RED}[-]${RESET} $1"; }


# Resolve script directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $REPO_DIR/scripts/set-env.sh

SCRIPTS_PATH="$REPO_DIR/scripts/$DOTURA_OS_NAME"
COMMON_SCRIPTS_PATH="$REPO_DIR/scripts/common"

if [[ ! -d "$SCRIPTS_PATH" ]]; then
    error "Script directory not found: $SCRIPTS_PATH"
    exit 1
fi

if [[ ! -d "$COMMON_SCRIPTS_PATH" ]]; then
    error "Script directory not found: $COMMON_SCRIPTS_PATH"
    exit 1
fi

# Get sorted list of scripts: 01-xxx.sh, 02-xxx.sh, ...
scripts=()
while IFS= read -r line; do
    scripts+=("$line")
done < <(find "$COMMON_SCRIPTS_PATH" "$SCRIPTS_PATH" -maxdepth 1 -type f -name '[0-9][0-9]*-*.sh' 2>/dev/null | sort -u)

if [[ ${#scripts[@]} -eq 0 ]]; then
    warn "No scripts found to run in $SCRIPTS_PATH"
    exit 0
else
    log "Found scripts in $SCRIPTS_PATH"
fi

log "Running install scripts from"
log "    $SCRIPTS_PATH"
log "    $SCRIPTS_PATH"

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
