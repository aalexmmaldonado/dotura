#!/usr/bin/env zsh

# Set Zsh options for safer scripting (equivalent to bash's set -euo pipefail)
setopt ERR_EXIT UNSET PIPE_FAIL

# Output colors (no change needed)
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

log()    { echo -e "${GREEN}[+]${RESET} $1"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $1"; }
error()  { echo -e "${RED}[-]${RESET} $1"; }

# Determine paths relative to the script
SCRIPT_DIR=${0:a:h}
PKG_DIR="$SCRIPT_DIR/../../pkg/macos"

BREW_LIST="$PKG_DIR/brew.txt"
CASK_LIST="$PKG_DIR/cask.txt"
EXTRA_LIST="$PKG_DIR/extra.txt"

# Ensure required files and directory exist
mkdir -p "$PKG_DIR"
touch "$BREW_LIST" "$CASK_LIST" "$EXTRA_LIST"

# --- Get lists of installed packages using Zsh's clean array creation ---
log "Getting lists of installed packages..."
local -a installed_formulae installed_casks
installed_formulae=(${(f)"$(brew leaves)"})
installed_casks=(${(f)"$(brew list --cask)"})
local -a explicit_pkgs=("${installed_formulae[@]}" "${installed_casks[@]}")

# --- Read tracked packages and create an efficient lookup table ---
log "Reading tracked package lists..."
local -a brew_pkgs cask_pkgs extra_pkgs
brew_pkgs=(${(f)"$(<"$BREW_LIST")"})
cask_pkgs=(${(f)"$(<"$CASK_LIST")"})
extra_pkgs=(${(f)"$(<"$EXTRA_LIST")"})

# Use an associative array for fast O(1) lookups instead of grep
typeset -A tracked_set
for pkg in "${brew_pkgs[@]}" "${cask_pkgs[@]}" "${extra_pkgs[@]}"; do
    tracked_set[$pkg]=1
done

# --- Determine untracked packages ---
log "Comparing installed packages to tracked lists..."
local -a untracked_pkgs
for pkg in "${explicit_pkgs[@]}"; do
    # Check if the package exists as a key in our lookup table
    if (( ! ${+tracked_set[$pkg]} )); then
        untracked_pkgs+=($pkg)
    fi
done

if (( ${#untracked_pkgs} == 0 )); then
    log "All installed packages are tracked. Nothing to do. ✨"
    exit 0
fi

log "Found ${#untracked_pkgs} new package(s) to review."

# --- Create a cask lookup table for the user prompt ---
typeset -A is_cask
for pkg in "${installed_casks[@]}"; do
    is_cask[$pkg]=1
done

# --- User Interaction Loop ---
for pkg in "${untracked_pkgs[@]}"; do
    local source="brew"
    if (( ${+is_cask[$pkg]} )); then
        source="cask"
    fi

    # Use Zsh's enhanced 'read' command for a cleaner prompt
    read -r "choice?${YELLOW}Include package '$pkg' from [$source]?${RESET}\n[y] Add to list | [n] Add to extra.txt | [s] Skip: "
    case "$choice" in
        y|Y)
            if [[ "$source" == "cask" ]]; then
                echo "$pkg" >> "$CASK_LIST"
                log "Added '$pkg' to cask.txt"
            else
                echo "$pkg" >> "$BREW_LIST"
                log "Added '$pkg' to brew.txt"
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

# Sort and deduplicate lists for cleanliness
log "Sorting and cleaning up package lists..."
for file in "$BREW_LIST" "$CASK_LIST" "$EXTRA_LIST"; do
    sort -u "$file" -o "$file"
done