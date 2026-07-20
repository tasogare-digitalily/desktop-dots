#!/usr/bin/env bash

SOUND_PATH="$HOME/.config/swaync/sounds/notification.mp3"
LOCK_FILE="/tmp/notification_sound.lock"
COOLDOWN_MS=500  # Minimum time required between sounds in milliseconds

# Ensure the lock file starts empty on script boot
echo "0" > "$LOCK_FILE"

dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" | while read -r line; do
    
    # Check for the primary notification hook line
    if echo "$line" | grep -q "method call"; then
        
        # Read the immediate next lines to cleanly extract the app name string
        read -r _
        read -r app_line
        
        APP_NAME=$(echo "$app_line" | sed -n 's/.*string "\(.*\)".*/\1/p')
        APP_LOWER=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')

        # Filter out Discord
        if [ "$APP_LOWER" != "discord" ]; then
            
            # Check Wayle's DND status
            IS_DND=$(wayle config get notifications.dnd 2>/dev/null || echo "false")

            if [ "$IS_DND" = "false" ]; then
                # Get current time in milliseconds
                CURRENT_TIME_MS=$(($(date +%s%N) / 1000000))
                LAST_PLAYED_MS=$(cat "$LOCK_FILE" 2>/dev/null || echo "0")
                TIME_DIFF=$((CURRENT_TIME_MS - LAST_PLAYED_MS))

                # Play ONLY if the strict cooldown threshold has passed
                if [ "$TIME_DIFF" -gt "$COOLDOWN_MS" ]; then
                    echo "$CURRENT_TIME_MS" > "$LOCK_FILE"
                    mpv --no-terminal "$SOUND_PATH" &
                fi
            fi
        fi
    fi
done
