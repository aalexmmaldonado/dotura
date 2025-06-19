#!/bin/bash

# Characters representing load levels (0–7)
blocks=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

# Temp file to store previous values
STAT_FILE="/tmp/waybar_cpu_stat"

# Read current stats: (total, idle) per core
mapfile -t current < <(grep '^cpu[0-9]' /proc/stat | awk '{total=$2+$3+$4+$5+$6+$7+$8; print total " " $5}')

# Load previous values
if [[ -f "$STAT_FILE" ]]; then
    mapfile -t prev < "$STAT_FILE"
else
    printf "%s\n" "${current[@]}" > "$STAT_FILE"
    echo '{"text": "⏳", "tooltip": "Initializing CPU stats..."}'
    exit 0
fi

bars=""
core_count=${#current[@]}

for ((i=0; i<core_count; i++)); do
    read -r total_now idle_now <<< "${current[i]}"
    read -r total_prev idle_prev <<< "${prev[i]}"

    diff_total=$((total_now - total_prev))
    diff_idle=$((idle_now - idle_prev))

    if (( diff_total > 0 )); then
        usage=$(( (1000 * (diff_total - diff_idle)) / diff_total ))
    else
        usage=0
    fi

    index=$((usage * 8 / 1000))
    (( index > 7 )) && index=7

    bars+="${blocks[index]}"
done

# Save current stats
printf "%s\n" "${current[@]}" > "$STAT_FILE"

# Output JSON for Waybar
echo "{\"text\": \"$bars\", \"tooltip\": \"Per-core CPU Load\", \"class\": \"cpu_bars\"}"
