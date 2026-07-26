#!/bin/bash

mem_total=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
mem_free=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
mem_used=$((mem_total - mem_free))

mem_g=$(awk -v m="$mem_used" 'BEGIN {printf "%.1f", m/1024/1024}')

echo "  ${mem_g}G %"
