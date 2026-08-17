#!/usr/bin/env bash

SOUND_PATH="$HOME/.config/swaync/sounds/notification.mp3"
LOCK_FILE="/tmp/notification_sound.lock"
COOLDOWN_MS=500  # Minimum time required between sounds in milliseconds

# Ensure the lock file starts empty on script boot
echo "0" > "$LOCK_FILE"

# Monitor only the specific interface and member to reduce noise
dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" | \
awk '
# Whenever we see a method call, reset tracking for the new notification block
/^method call/ { app = "" }

# The freedesktop specs dictate the 1st string passed to Notify is the app name
/string "[^"]*"/ {
    if (app == "") {
        gsub(/.*string "|".*/, "", $0)
        print $0
        fflush()
    }
}
' | while read -r APP_NAME; do

    APP_LOWER=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')
    
    # Filter out Discord (and add any other apps here if needed)
    if [ "$APP_LOWER" != "discord" ]; then
        
        # Check Wayle's DND status
        IS_DND=$(/home/digitalily/Git/wayle/target/release/wayle config get notifications.dnd 2>/dev/null || echo "false")

        if [ "$IS_DND" = "false" ]; then
            CURRENT_TIME_MS=$(($(date +%s%N) / 1000000))
            LAST_PLAYED_MS=$(cat "$LOCK_FILE" 2>/dev/null || echo "0")
            TIME_DIFF=$((CURRENT_TIME_MS - LAST_PLAYED_MS))

            if [ "$TIME_DIFF" -gt "$COOLDOWN_MS" ]; then
                echo "$CURRENT_TIME_MS" > "$LOCK_FILE"
                mpv --no-terminal "$SOUND_PATH" &
            fi
        fi
    fi
done