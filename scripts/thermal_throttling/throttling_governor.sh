#!/bin/bash

TEMP_FILE="/sys/class/thermal/thermal_zone2/temp"
NOTIFY_URL="ntfy.sh/yourtopic" # Replace with your NTFY URL and topic
NOTIFY_TOKEN="tk_xxxx" # Replace with your own token
PERFORMANCE_SCRIPT="set_cpu_mode.sh"

HIGH_TEMP=80000 # 80ºC
CRITICAL_TEMP=90000 # 90ºC
COOL_TEMP=60000 # 60ºC

HIGH_TEMP_THRESHOLD=10 # 10 seconds
CRITICAL_TEMP_THRESHOLD=10 # 10 seconds
COOL_TEMP_THRESHOLD=1800 # 30 minutes

overheat_start=0
critical_start=0
cooldown_start=0
cooldown_active=0
last_event_reading=0

notified_high=0
notified_critical=0
notified_cool=0

echo "Starting homelab CPU temperature monitoring now..."

temp_reading=$(cat "$TEMP_FILE")
curl -u :$NOTIFY_TOKEN -d "Start monitoring homelab temperature. Now: $(($temp_reading/1000))ºC" "$NOTIFY_URL"

while true; do
    temp_reading=$(cat "$TEMP_FILE")
    current_time=$(date +%s)

    # High temperature event
    if [[ "$temp_reading" -ge "$HIGH_TEMP" && "$temp_reading" -lt "$CRITICAL_TEMP" ]]; then
        last_event_reading=$temp_reading
        if [[ "$overheat_start" -eq 0 ]]; then
            overheat_start=$current_time
        elif (( current_time - overheat_start >= HIGH_TEMP_THRESHOLD && notified_high == 0 )); then
            curl -u :$NOTIFY_TOKEN -d "Homelab is hot: $(($temp_reading/1000))ºC" "$NOTIFY_URL"
            notified_high=1
            notified_critical=0
            notified_cool=0
        fi
    else
        overheat_start=0
        notified_high=0
    fi

    # Critical temperature event
    if [[ "$temp_reading" -ge "$CRITICAL_TEMP" ]]; then
        if [[ "$critical_start" -eq 0 ]]; then
            critical_start=$current_time
        elif (( current_time - critical_start >= CRITICAL_TEMP_THRESHOLD && notified_critical == 0 )); then
            curl -u :$NOTIFY_TOKEN -d "Homelab is really hot: $(($temp_reading/1000))ºC. Throttling it now." "$NOTIFY_URL"
            bash "$PERFORMANCE_SCRIPT" --throttler
            cooldown_active=1
            cooldown_start=$current_time
            notified_critical=1
            notified_high=0
            notified_cool=0
        fi
    else
        critical_start=0
        notified_critical=0
    fi

    # Cool-down event
    if [[ "$last_event_reading" -ge "$HIGH_TEMP" && "$temp_reading" -le "$COOL_TEMP" ]]; then

        [[ "$notified_cool" -eq 0 ]] && curl -u :$NOTIFY_TOKEN -d "Homelab has cooled down: $(($temp_reading/1000))ºC." "$NOTIFY_URL"
        notified_cool=1

        if [[ "$cooldown_start" -eq 0 ]]; then
            cooldown_start=$current_time
        elif (( current_time - cooldown_start >= COOL_TEMP_THRESHOLD )); then
            curl -u :$NOTIFY_TOKEN -d "Homelab has been cool for a while now. Last reading: $(($temp_reading/1000))ºC. Moving to performance mode." "$NOTIFY_URL"
            bash "$PERFORMANCE_SCRIPT" --performance
            cooldown_active=0
            last_event_reading=$temp_reading
            notified_cool=0
            notified_high=0
            notified_critical=0
        fi
    else
        cooldown_start=0
    fi

    sleep 1
done
