#!/bin/bash

if [ "$(swaync-client -D)" = "false" ] && [ "$SWAYNC_APP_NAME" != "discord" ] && [ "$SWAYNC_APP_NAME" != "Discord" ]; then
    mpv --no-terminal ~/.config/swaync/sounds/notification.mp3 &
fi