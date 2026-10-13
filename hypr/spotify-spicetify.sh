#!/usr/bin/env bash
# Starts Spotify with Spicetify applied. spotify-launcher updates the client on
# launch, which silently wipes Spicetify's patch, so: fetch any update first,
# re-patch only if the installed build differs from Spicetify's backup, then
# launch and attach the live-reload watcher.

SPOTIFY_BIN="$HOME/.local/share/spotify-launcher/install/usr/share/spotify/spotify"
INI="$HOME/.config/spicetify/config-xpui.ini"

spotify-launcher --no-exec

installed=$("$SPOTIFY_BIN" --version 2>/dev/null | sed -n 's/^Spotify version \([^,]*\),.*/\1/p')
backed_up=$(sed -n '/^\[Backup\]/,/^\[/{s/^version *= *//p}' "$INI")

if [ -n "$installed" ] && [ "$installed" != "$backed_up" ]; then
  pkill -x spotify
  sleep 2
  spicetify backup apply
fi

spotify-launcher &
sleep 5
exec spicetify watch -s
