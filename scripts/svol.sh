#!/bin/bash

# Load PulseAudio environment (relevant for pipewire-pulse)
export PULSE_RUNTIME_PATH="/run/user/$(id -u)/pulse"

# -------------------------
# Function: get earbuds battery if connected
# -------------------------
get_earbuds_info() {
  connected_devices=$(bluetoothctl devices Connected | awk '{print $2}')

  for dev_mac in $connected_devices; do
    dev_name=$(bluetoothctl info "$dev_mac" | awk -F ': ' '/Name/ {print $2}')
    if echo "$dev_name" | grep -qiE "earbud|headset|airpods|buds|sony|bose|jabra"; then
      upower_path=$(upower -e | grep -i "$dev_mac")
      if [ -n "$upower_path" ]; then
        battery=$(upower -i "$upower_path" | awk '/percentage/ {print $2}')
        [ -n "$battery" ] && echo "$dev_name|${battery/\%/}" && return
      fi
      battery=$(bluetoothctl info "$dev_mac" | grep -i "Battery Percentage" | sed -n 's/.*(\([0-9]\+\)).*/\1/p')
      [ -n "$battery" ] && echo "$dev_name|$battery" && return
    fi
  done
}

# -------------------------
# Function: get current volume & mute status
# -------------------------
get_volume() {
  default_sink=$(pactl info | grep "Default Sink" | cut -d ':' -f2 | xargs)
  if [ -z "$default_sink" ]; then
    echo " No Sink"
    return
  fi

  if pactl get-sink-mute "$default_sink" | grep -q "yes"; then
    vol_output=" 󰅗"
  else
    vol=$(pactl get-sink-volume "$default_sink" | grep -oP '\d+?(?=%)' | head -n 1)
    [ "$vol" -gt 100 ] && pactl set-sink-volume "$default_sink" 100% && vol=100
    vol_output=" ${vol}%"
  fi

  earbuds_info=$(get_earbuds_info)
  if [ -n "$earbuds_info" ]; then
    earbuds_battery=${earbuds_info##*|}
    echo " 󱡏$vol_output | 󰥈${earbuds_battery}% | $(get_mic_status)"
  else
    echo "$vol_output $(get_mic_status)"
  fi
}

# -------------------------
# Function: get microphone mute status
# -------------------------
get_mic_status() {
  default_source=$(pactl info | grep "Default Source" | sed 's/^[^:]*: *//')
  if [ -z "$default_source" ]; then
    echo ""
    return
  fi

  if pactl get-source-mute "$default_source" | grep -q "yes"; then
    # Muted
    echo ""
  else
    # Active
    echo ""
  fi
}

# -------------------------
# Initial sanity check
# -------------------------
current_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+?(?=%)' | head -n 1)
[ "$current_vol" -gt 100 ] && pactl set-sink-volume @DEFAULT_SINK@ 100%

# -------------------------
# Print initial status
# -------------------------
get_volume

