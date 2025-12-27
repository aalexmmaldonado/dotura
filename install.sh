#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"

# --- LOGGING ---
log()   { echo -e "${GREEN}[+]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $1"; }
error() { echo -e "${RED}[-]${RESET} $1"; exit 1; }

# --- OS DETECTION ---
OS_NAME=$(uname -s)
if [[ "$OS_NAME" == "Darwin" ]]; then
    IS_MAC=true
elif [[ "$OS_NAME" == "Linux" ]]; then
    IS_MAC=false
else
    error "Unsupported OS: $OS_NAME"
fi

# --- ROOT CHECK ---
if (( EUID != 0 )); then
    error "Run as root: sudo $0"
fi

# --- FUNCTIONS ---

list_devices_linux() {
    printf "%3s %-8s %-6s %-12s %-8s %-10s %s\n" "Idx" "Name" "Size" "Model" "Type" "Mount" "RO"
    printf "%3s %-8s %-6s %-12s %-8s %-10s %s\n" "---" "--------" "------" "------------" "-------" "----------" "--"

    local i=1
    DEVICES_MAP=()
    
    # Process substitution <(...) works in Bash, but not 'sh'
    while read -r line; do
        read -r name size model vendor tran type mountpoint ro <<< "$line"
        
        # Skip loop devices or empty lines
        [[ "$name" == "NAME" ]] && continue

        local clean_name=$(echo "$name" | sed 's|^/dev/||')
        local full_path="/dev/$clean_name"
        
        DEVICES_MAP[$i]="$full_path"

        printf "%3d %-8s %-6s %-12s %-8s %-10s %s\n" \
            "$i" "$clean_name" "$size" "$model" "$type" "$mountpoint" "$ro"
        ((i++))
    done < <(lsblk -o NAME,SIZE,MODEL,VENDOR,TRAN,TYPE,MOUNTPOINT,RO -d -n -e 7,11,9,2,259,1)
}

list_devices_mac() {
    log "Listing external physical drives (macOS)..."
    diskutil list external physical
    echo ""
    echo "Enter the DEVICE IDENTIFIER (e.g., 'disk2') to target."
    echo "WARNING: Ensure you pick the USB drive. This device will be ERASED."
}

cleanup() {
    log "Cleaning up..."
    if [[ -n "${MNT_ISO:-}" && -d "$MNT_ISO" ]]; then
        if $IS_MAC; then
            hdiutil detach "$MNT_ISO" -quiet || true
        else
            umount "$MNT_ISO" || true
            rmdir "$MNT_ISO"
        fi
    fi

    if [[ -n "${MNT_USB:-}" && -d "$MNT_USB" ]]; then
        if $IS_MAC; then
             # Mac usually auto-mounts after format, let's just detach valid disk
             diskutil unmountDisk "$DEV" || true
        else
             umount "$MNT_USB" || true
             rmdir "$MNT_USB"
        fi
    fi

    log "Success!"
}

trap cleanup EXIT

# --- MAIN LOGIC ---

log "Detected OS: $OS_NAME"

if $IS_MAC; then
    list_devices_mac
    read -p "Enter Device Node: " SELECTED_DEV
    
    # Sanitize input
    SELECTED_DEV="${SELECTED_DEV#/dev/}" # remove /dev/ if user typed it
    DEV="/dev/$SELECTED_DEV"

    if ! diskutil info "$DEV" >/dev/null 2>&1; then
        error "Device $DEV not found."
    fi
else
    # Linux Selection Logic
    declare -a DEVICES_MAP
    list_devices_linux
    
    while true; do
        read -p "Select USB device by Idx (0 to quit): " SELECTED_INDEX
        if [[ "$SELECTED_INDEX" =~ ^[0-9]+$ ]]; then
            if (( SELECTED_INDEX == 0 )); then error "Aborted."; fi
            if [[ -n "${DEVICES_MAP[$SELECTED_INDEX]:-}" ]]; then
                DEV="${DEVICES_MAP[$SELECTED_INDEX]}"
                break
            else
                warn "Invalid index."
            fi
        else
            warn "Please enter a number."
        fi
    done
fi

log "Selected Device: $DEV"

# -- ISO INPUT --
read -e -p "Path to ISO: " ISO_PATH

# Strip surrounding quotes (double or single) commonly added by drag-and-drop
ISO_PATH="${ISO_PATH%\"}" # Remove trailing double quote
ISO_PATH="${ISO_PATH#\"}" # Remove leading double quote
ISO_PATH="${ISO_PATH%\'}" # Remove trailing single quote
ISO_PATH="${ISO_PATH#\'}" # Remove leading single quote

# Manually expand tilde (~) if it is the first character
if [[ "$ISO_PATH" == "~"* ]]; then
    ISO_PATH="${HOME}${ISO_PATH:1}"
fi

# Validation
if [[ ! -f "$ISO_PATH" ]]; then
    error "ISO not found at '$ISO_PATH'"
fi

# Convert to Absolute Path
# We use a subshell $(...) to enter the directory and print PWD without affecting the main script.
ISO_DIR=$(dirname "$ISO_PATH")
ISO_NAME=$(basename "$ISO_PATH")
ISO_PATH="$(cd "$ISO_DIR" && pwd)/$ISO_NAME"

log "Using ISO: $ISO_PATH"

read -e -p "Optional path to config file (press Enter to skip): " CONFIG_PATH
if [[ -n "$CONFIG_PATH" && ! -f "$CONFIG_PATH" ]]; then
    error "Config not found at '$CONFIG_PATH'"
fi

echo ""
warn "WARNING: YOU ARE ABOUT TO WIPE $DEV"
read -p "Type 'yes' to proceed: " CONFIRM
[[ "$CONFIRM" == "yes" ]] || error "Aborted."


log "Unmounting target device..."
if $IS_MAC; then
    diskutil unmountDisk "$DEV"
else
    for p in $(lsblk -lnpo NAME,MOUNTPOINT "${DEV}"* | awk '$2!=""{print $1}'); do
        umount "$p" || true
    done
fi


log "Wiping and Formatting $DEV as FAT32..."
if [[ "$ISO_PATH" =~ archlinux ]]; then
    YYYYMM=$(basename "$ISO_PATH" | grep -oE '[0-9]{4}\.[0-9]{2}' | sed 's/\.//')
    USB_LABEL="ARCH_${YYYYMM}"
else
    USB_LABEL="INSTALLER"
fi
log "Partition Label: $USB_LABEL"

count=0
max_retries=15
if $IS_MAC; then
    diskutil unmountDisk force "$DEV"

    diskutil eraseDisk MS-DOS "$USB_LABEL" MBR "$DEV"
    
    log "Waiting for volume to mount..."
    MNT_USB="/Volumes/$USB_LABEL"
    
    while [[ ! -d "$MNT_USB" ]]; do
        sleep 1
        ((count++))
        if (( count >= max_retries )); then
            warn "Auto-mount slow... attempting manual mount."
            diskutil mount "${DEV}s1" || true
            if [[ ! -d "$MNT_USB" ]]; then
                 error "Timed out waiting for $MNT_USB to mount."
            fi
        fi
    done
    log "Volume mounted at $MNT_USB"

else
    for p in $(lsblk -lnpo NAME,MOUNTPOINT "${DEV}"* | awk '$2!=""{print $1}'); do
        umount "$p" || true
    done

    parted --script "$DEV" mklabel msdos mkpart primary fat32 1MiB 100% set 1 boot on
    
    if [[ "$DEV" == *"nvme"* || "$DEV" == *"mmcblk"* ]]; then PART="${DEV}p1"; else PART="${DEV}1"; fi
    
    sleep 1 # Wait for kernel
    mkfs.vfat -F32 -n "$USB_LABEL" "$PART"
    
    MNT_USB=$(mktemp -d)
    mount "$PART" "$MNT_USB"
fi

log "Extracting ISO contents to USB..."

if $IS_MAC; then
    bsdtar -x -f "$ISO_PATH" -C "$MNT_USB"
else
    MNT_ISO=$(mktemp -d)
    mount -o loop "$ISO_PATH" "$MNT_ISO"
    cp -rL "${MNT_ISO}/." "${MNT_USB}/"
    umount "$MNT_ISO"
    rmdir "$MNT_ISO"
fi


if [[ -n "$CONFIG_PATH" ]]; then
  log "Adding config file to USB root..."
  cp -r "$CONFIG_PATH" "${MNT_USB}/"
fi


if [[ "$ISO_PATH" =~ archlinux ]]; then
    echo ""
    read -r -p "Disable Kernel Mode Setting (could fix NVIDIA black screen)? [y/N]: " KMS_RESP
    # Default to n if empty
    KMS_RESP=${KMS_RESP:-n}

    if [[ "$KMS_RESP" =~ ^[yY] ]]; then
        log "Adding 'nomodeset nouveau.modeset=0' to boot entries..."
        
        # Check for entries in the standard loader location
        # We use a wildcard *.conf because the filename might vary (01-archiso... vs archiso-x86...)
        shopt -s nullglob
        CONF_FILES=("$MNT_USB"/loader/entries/*.conf)
        shopt -u nullglob

        if [ ${#CONF_FILES[@]} -eq 0 ]; then
            warn "No boot entry files found in loader/entries/. Skipping KMS modification."
        else
            for entry in "${CONF_FILES[@]}"; do
                log "Patching $entry"
                if $IS_MAC; then
                    # macOS sed requires an empty string for the backup extension
                    sed -i '' '/^options/ s/$/ nomodeset nouveau.modeset=0/' "$entry"
                else
                    # Linux sed (GNU) does not
                    sed -i '/^options/ s/$/ nomodeset nouveau.modeset=0/' "$entry"
                fi
            done
        fi
    fi
fi


log "Syncing buffers..."
sync

if $IS_MAC; then
    diskutil unmountDisk "$DEV"
else
    umount "$MNT_USB"
    rmdir "$MNT_USB"
fi
