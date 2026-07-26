#!/bin/bash
. ~/.config/lemonbar/colors.sh

readonly CACHE_FILE="$HOME/.config/lemonbar/cache/cpu_cache.txt"
readonly OUTPUT_CACHE="$HOME/.config/lemonbar/cache/cpu_output_cache.txt"
readonly MIN_INTERVAL=1  # Minimum seconds between calculations

# Get current timestamp
current_time=$(date +%s)

# Check if we can use cached output (less than MIN_INTERVAL seconds old)
if [[ -f "$OUTPUT_CACHE" ]]; then
    cache_time=$(stat -c %Y "$OUTPUT_CACHE" 2>/dev/null || echo 0)
    if (( current_time - cache_time < MIN_INTERVAL )); then
        cat "$OUTPUT_CACHE"
        exit 0
    fi
fi

# Read previous values and timestamp
if [[ -f "$CACHE_FILE" ]]; then
    read -r prev_total prev_idle prev_time < "$CACHE_FILE"
else
    prev_total=0
    prev_idle=0  
    prev_time=0
fi

# Only calculate if enough time has passed
time_diff=$((current_time - prev_time))
if (( time_diff < 1 && prev_time > 0 )); then
    # Use last known output if interval too short
    [[ -f "$OUTPUT_CACHE" ]] && cat "$OUTPUT_CACHE" && exit 0
fi

# Read current CPU stats
{
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice
} < /proc/stat

# Calculate CPU usage
total=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_all=$((idle + iowait))
totald=$((total - prev_total))
idled=$((idle_all - prev_idle))

if (( totald > 0 )); then
    usage=$(( (100 * (totald - idled)) / totald ))
else
    usage=0
fi

# Cache current values with timestamp
printf "%d %d %d\n" "$total" "$idle_all" "$current_time" > "$CACHE_FILE"

# Generate and cache output
output=" ${usage}%"
echo "$output" | tee "$OUTPUT_CACHE"
