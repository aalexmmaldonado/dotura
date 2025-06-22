#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PKG_DIR="$SCRIPT_DIR/pkg"

PACMAN_LIST="$PKG_DIR/pacman.txt"
AUR_LIST="$PKG_DIR/aur.txt"
EXTRA_LIST="$PKG_DIR/extra.txt"

# Output colors
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

log()    { echo -e "${GREEN}[+]${RESET} $1"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $1"; }
error()  { echo -e "${RED}[-]${RESET} $1"; }

# Ensure required files exist
mkdir -p "$PKG_DIR"
touch "$PACMAN_LIST" "$AUR_LIST" "$EXTRA_LIST"

# Get list of explicitly installed packages
log "Getting list of explicitly installed packages..."
mapfile -t explicit_pkgs < <(pacman -Qqe)

# Get AUR/foreign packages
log "Detecting AUR (foreign) packages..."
if command -v yay &>/dev/null; then
    mapfile -t aur_installed < <(yay -Qm)
else
    mapfile -t aur_installed < <(pacman -Qm)
fi
aur_set=$(printf "%s\n" "${aur_installed[@]}" | cut -d' ' -f1 | sort -u)

# Fast lookup for AUR packages
declare -A is_aur
for pkg in $aur_set; do
    is_aur["$pkg"]=1
done

# Read tracked package lists
readarray -t pacman_pkgs < "$PACMAN_LIST"
readarray -t aur_pkgs < "$AUR_LIST"
readarray -t extra_pkgs < "$EXTRA_LIST"

# Combine all tracked packages
tracked_set=$(printf "%s\n" "${pacman_pkgs[@]}" "${aur_pkgs[@]}" "${extra_pkgs[@]}" | sort -u)

# Determine untracked packages
log "Comparing installed packages to tracked lists..."
untracked_pkgs=()
for pkg in "${explicit_pkgs[@]}"; do
    if ! grep -qxF "$pkg" <<< "$tracked_set"; then
        untracked_pkgs+=("$pkg")
    fi
done

if [[ ${#untracked_pkgs[@]} -eq 0 ]]; then
    log "No new packages to consider."
    exit 0
fi

log "Found ${#untracked_pkgs[@]} new packages to review."

# Prompt user for each untracked package
for pkg in "${untracked_pkgs[@]}"; do
    if [[ ${is_aur[$pkg]+1} ]]; then
        source="aur"
    else
        source="pacman"
    fi

    echo -e "${YELLOW}Include package '$pkg' from [$source]?${RESET}"
    echo -n "[y] Add to list | [n] Add to extra.txt | [s] Skip: "
    read -r choice
    case "$choice" in
        y|Y)
            if [[ "$source" == "aur" ]]; then
                echo "$pkg" >> "$AUR_LIST"
                log "Added '$pkg' to aur.txt"
            else
                echo "$pkg" >> "$PACMAN_LIST"
                log "Added '$pkg' to pacman.txt"
            fi
            ;;
        n|N)
            echo "$pkg" >> "$EXTRA_LIST"
            log "Added '$pkg' to extra.txt"
            ;;
        s|S)
            warn "Skipped '$pkg'"
            ;;
        *)
            warn "Invalid input, skipping '$pkg'"
            ;;
    esac
done

# Sort and deduplicate lists
log "Sorting and deduplicating package lists..."
for file in "$PACMAN_LIST" "$AUR_LIST" "$EXTRA_LIST"; do
    sort -u "$file" -o "$file"
done

log "Package sync complete."
