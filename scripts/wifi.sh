#!/bin/bash

ssid=$(nmcli -t -f active,ssid dev wifi | awk -F: '$1=="yes"{print $2}')
[ -z "$ssid" ] && ssid="??"

echo "  ${ssid}"
