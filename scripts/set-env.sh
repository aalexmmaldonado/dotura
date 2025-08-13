#!/bin/bash

# A function to show an error and exit
# It's good practice to have this self-contained
error() { echo -e "\e[31m[-]\e[0m $1"; }

# Detect operating system
OS_NAME=""
case "$(uname -s)" in
    Darwin)
        OS_NAME="macos"
        ;;
    Linux)
        # Further check for Arch Linux specifically
        if [[ -f /etc/arch-release ]]; then
            OS_NAME="arch"
        else
            error "Unsupported Linux distribution."
            # 'return' is better than 'exit' in a sourced script
            # because 'exit' will close your whole terminal.
            return 1
        fi
        ;;
    *)
        error "Unsupported operating system: $(uname -s)"
        return 1
        ;;
esac

export DOTURA_OS_NAME="$OS_NAME"

log "Detected OS: $DOTURA_OS_NAME"