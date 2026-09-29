#!/usr/bin/env bash
# Toggles a Hyprland special workspace by name, e.g.: toggle-special.sh spotify
exec hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$1\")"
