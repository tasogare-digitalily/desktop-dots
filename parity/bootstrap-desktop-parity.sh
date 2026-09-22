#!/usr/bin/env bash
#
# Brings a machine to parity with this desktop's setup: the packages that
# hypr/, waybar/, wofi/, swaync/, wal/, and noctalia/ (this repo's tracked
# config dirs) actually invoke at runtime, plus the native Spotify +
# Spicetify + Noctalia color-integration setup (spotify-launcher install,
# Comfy + Colorful Spicetify themes, the noctalia community-template files
# that drive live color updates). Meant to be run from inside a checked-out
# copy of this desktop-dots repo, after `git pull` has already synced those
# dirs. Idempotent: safe to re-run, already-present pieces are skipped.
#
# Deliberately NOT covered: general desktop software with no tie to a
# tracked config (game emulators, 3D-print slicers, printer drivers, etc.)
# and the caelestia/quickshell-git stack, which looks like a separate,
# parallel theming setup rather than part of the noctalia rice. Install
# those yourself if you want them on this machine too.
#
# On any failure, every change this run made (and only this run) is rolled
# back automatically. Anything this script overwrites is backed up first;
# see the manifest path printed at the end for where the prior state lives.
#
# Usage: ./bootstrap-desktop-parity.sh

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.local/state/desktop-dots-bootstrap/backups/$(date +%Y%m%d-%H%M%S)"
MANIFEST="$BACKUP_ROOT/manifest.txt"
ROLLBACK_STACK=()

# ---------- logging ----------
c_info() { printf '\033[34m[info]\033[0m %s\n' "$*"; }
c_ok()   { printf '\033[32m[ok]\033[0m %s\n' "$*"; }
c_warn() { printf '\033[33m[warn]\033[0m %s\n' "$*"; }
c_err()  { printf '\033[31m[error]\033[0m %s\n' "$*" >&2; }

manifest_note() {
  mkdir -p "$BACKUP_ROOT"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$MANIFEST"
}

# ---------- rollback plumbing ----------
push_rollback() {
  ROLLBACK_STACK+=("$1")
}

run_rollback() {
  local exit_code=$?
  if [ "$exit_code" -eq 0 ]; then
    return
  fi
  c_err "Setup failed (exit $exit_code). Rolling back changes made by this run..."
  local i
  for (( i=${#ROLLBACK_STACK[@]}-1; i>=0; i-- )); do
    c_warn "undo: ${ROLLBACK_STACK[$i]}"
    eval "${ROLLBACK_STACK[$i]}" || c_warn "  (rollback step itself failed, continuing)"
  done
  manifest_note "ROLLBACK COMPLETED after failure (exit $exit_code)"
  c_err "Rolled back. Nothing from this run should remain."
  c_err "Details / prior state backups: $BACKUP_ROOT"
  exit "$exit_code"
}
trap run_rollback ERR

# backup_path <path>
# If <path> exists, copies it into the backup dir (preserving relative
# structure) and arranges for rollback to restore it. If <path> does NOT
# exist yet, arranges for rollback to just remove whatever gets created
# there. Either way, call this BEFORE you write to <path>.
backup_path() {
  local path="$1"
  local rel="${path#"$HOME"/}"
  local dest="$BACKUP_ROOT/$rel"
  if [ -e "$path" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -a "$path" "$dest"
    manifest_note "BACKED UP (pre-existing): $path -> $dest"
    push_rollback "rm -rf '$path' && cp -a '$dest' '$path'"
  else
    manifest_note "WILL CREATE (nothing there before): $path"
    push_rollback "rm -rf '$path'"
  fi
}

# ---------- helpers ----------
pkg_installed() { pacman -Qi "$1" &>/dev/null; }

ensure_pacman_pkg() {
  local name="$1"
  if pkg_installed "$name"; then
    c_ok "pacman package '$name' already installed"
    return
  fi
  c_info "installing pacman package '$name'..."
  sudo pacman -S --needed --noconfirm "$name"
  manifest_note "INSTALLED pacman package: $name (was not previously installed)"
  push_rollback "sudo pacman -R --noconfirm '$name' || true"
  c_ok "installed '$name'"
}

AUR_HELPER=""
detect_aur_helper() {
  if command -v yay &>/dev/null; then AUR_HELPER="yay";
  elif command -v paru &>/dev/null; then AUR_HELPER="paru";
  else
    c_err "no AUR helper found (checked yay, paru). Install one first (spicetify-cli lives in the AUR)."
    exit 1
  fi
}

ensure_aur_pkg() {
  local name="$1"
  if pkg_installed "$name"; then
    c_ok "AUR package '$name' already installed"
    return
  fi
  c_info "installing AUR package '$name' via $AUR_HELPER..."
  "$AUR_HELPER" -S --noconfirm "$name"
  manifest_note "INSTALLED AUR package: $name (was not previously installed, via $AUR_HELPER)"
  push_rollback "sudo pacman -R --noconfirm '$name' || true"
  c_ok "installed '$name'"
}

clone_if_missing() {
  local url="$1" dest="$2"
  if [ -d "$dest" ]; then
    c_ok "$dest already present, skipping clone"
    return 1
  fi
  git clone --depth 1 "$url" "$dest"
  manifest_note "CLONED: $url -> $dest"
  push_rollback "rm -rf '$dest'"
  return 0
}

# ---------- preflight ----------
if [ ! -f /etc/os-release ] || ! grep -q '^ID=arch' /etc/os-release; then
  c_err "this script assumes Arch Linux (pacman/AUR). Aborting."
  exit 1
fi
detect_aur_helper
c_info "using AUR helper: $AUR_HELPER"
c_info "backups/manifest for this run: $BACKUP_ROOT"
manifest_note "=== bootstrap-desktop-parity.sh run started ==="

# ---------- 0. packages the tracked configs actually invoke at runtime ----------
# Sourced from an audit of hypr/hyprland.lua (autostart + keybinds),
# waybar/config + waybar/scripts/*, wofi/config, swaync/*.sh, and the
# wal/ template dir. Trivial base-system packages (systemd, dbus,
# procps-ng, psmisc, systemd-sysvcompat) are skipped as guaranteed-present
# on any usable Arch desktop.
PACMAN_DESKTOP_PACKAGES=(
  hyprland hyprlock noctalia waybar wofi swaync            # core session/shell
  awww hyprpicker hyprpolkitagent xdg-desktop-portal xdg-desktop-portal-hyprland
  kitty thunar firefox code discord steam                  # hyprland.lua vars/autostart
  brightnessctl playerctl wireplumber pavucontrol blueman   # hardware/media keybinds
  imagemagick libnotify wl-clipboard                        # waybar/scripts/colorpicker.sh
  mpv                                                       # swaync/notification.sh sound
  pacman-contrib flatpak python                             # waybar custom modules
)
AUR_DESKTOP_PACKAGES=(
  wlogout xwaylandvideobridge opentabletdriver
  matugen-bin                                                # noctalia's color-generation backend
  python-pywal16 python-pywalfox                             # wal/ templates + the active "pywalfox" noctalia community template
  zscroll-git                                                # scrolling-mpris waybar module
)

for pkg in "${PACMAN_DESKTOP_PACKAGES[@]}"; do
  ensure_pacman_pkg "$pkg"
done
for pkg in "${AUR_DESKTOP_PACKAGES[@]}"; do
  ensure_aur_pkg "$pkg"
done

# ---------- 1. clear leftover Flatpak/Snap Spotify installs ----------
# spicetify's Linux path-detection (used by `spicetify watch`) checks for
# ~/snap/spotify and ~/.var/app/com.spotify.Client BEFORE falling back to
# the normal ~/.cache/spotify location. A leftover directory from a
# previously-removed Flatpak/Snap install of Spotify will make it look in
# the wrong place and silently fail with "Can't find offline.bnk".
if [ -d "$HOME/.var/app/com.spotify.Client" ] && ! (command -v flatpak &>/dev/null && flatpak list --app 2>/dev/null | grep -qi spotify); then
  c_warn "found leftover Flatpak Spotify data with no Flatpak Spotify installed — moving aside"
  backup_path "$HOME/.var/app/com.spotify.Client"
  mv "$HOME/.var/app/com.spotify.Client" "$HOME/.var/app/com.spotify.Client.bak-unused"
  manifest_note "MOVED ASIDE: ~/.var/app/com.spotify.Client -> ~/.var/app/com.spotify.Client.bak-unused"
fi
if [ -d "$HOME/snap/spotify" ] && ! (command -v snap &>/dev/null && snap list 2>/dev/null | grep -qi spotify); then
  c_warn "found leftover Snap Spotify data with no Snap Spotify installed — moving aside"
  backup_path "$HOME/snap/spotify"
  mv "$HOME/snap/spotify" "$HOME/snap/spotify.bak-unused"
  manifest_note "MOVED ASIDE: ~/snap/spotify -> ~/snap/spotify.bak-unused"
fi

# ---------- 2. Spotify via spotify-launcher ----------
ensure_pacman_pkg spotify-launcher
c_info "fetching Spotify client (spotify-launcher --no-exec)..."
spotify-launcher --no-exec
c_ok "Spotify client present"

# ---------- 3. spicetify-cli ----------
ensure_aur_pkg spicetify-cli
backup_path "$HOME/.config/spicetify/config-xpui.ini"
c_info "running spicetify backup apply..."
pkill -f '/spotify-launcher/install/.*/spotify$' 2>/dev/null || true
sleep 1
spicetify backup apply
c_ok "spicetify backed up + patched Spotify"

# ---------- 4. Comfy theme ----------
THEMES_DIR="$HOME/.config/spicetify/Themes"
mkdir -p "$THEMES_DIR"
if [ ! -d "$THEMES_DIR/Comfy" ]; then
  TMP_COMFY="$(mktemp -d)"
  clone_if_missing "https://github.com/Comfy-Themes/Spicetify.git" "$TMP_COMFY/repo"
  backup_path "$THEMES_DIR/Comfy"
  mv "$TMP_COMFY/repo/Comfy" "$THEMES_DIR/Comfy"
  manifest_note "INSTALLED theme: Comfy -> $THEMES_DIR/Comfy"
  rm -rf "$TMP_COMFY"
else
  c_ok "Comfy theme already installed"
fi

# ---------- 5. Colorful theme ----------
if [ ! -d "$THEMES_DIR/Colorful" ]; then
  TMP_COLORFUL="$(mktemp -d)"
  git clone --depth 1 "https://github.com/sanoojes/spicetify-colorful.git" "$TMP_COLORFUL/repo"
  mkdir -p "$THEMES_DIR/Colorful"
  push_rollback "rm -rf '$THEMES_DIR/Colorful'"
  cp "$TMP_COLORFUL/repo/src/color.ini" "$THEMES_DIR/Colorful/color.ini"
  cp "$TMP_COLORFUL/repo/src/user.css" "$THEMES_DIR/Colorful/user.css"
  manifest_note "INSTALLED theme: Colorful -> $THEMES_DIR/Colorful"
  rm -rf "$TMP_COLORFUL"
else
  c_ok "Colorful theme already installed"
fi

# ---------- 6. noctalia community-template cache files ----------
# These live outside ~/.config (under ~/.local/state) so they don't sync via
# the dotfiles repo's own git pull. noctalia/config.toml's
# [theme.templates.user.spicetify] block references them by absolute path.
CT_DEST="$HOME/.local/state/noctalia/community-templates/spicetify"
CT_SRC="$SCRIPT_DIR/community-templates/spicetify"
mkdir -p "$CT_DEST"
for f in apply.sh template.toml spicetify.ini spicetify_colorful.ini README.MD; do
  backup_path "$CT_DEST/$f"
  cp "$CT_SRC/$f" "$CT_DEST/$f"
done
chmod +x "$CT_DEST/apply.sh"
manifest_note "RESTORED noctalia community-template files -> $CT_DEST"
c_ok "noctalia community-template files in place"

# ---------- 7. configure spicetify to match desktop state ----------
c_info "configuring spicetify (current_theme=Colorful, color_scheme=noctalia)..."
spicetify config current_theme Colorful color_scheme noctalia
spicetify config inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1
spicetify apply
manifest_note "CONFIGURED spicetify: current_theme=Colorful color_scheme=noctalia"
c_ok "spicetify configured and applied"

manifest_note "=== bootstrap-desktop-parity.sh run completed successfully ==="
c_ok "Done. Prior-state backups (if any existed) are kept at: $BACKUP_ROOT"
c_info "Next: log out/in (or 'hyprctl reload') to pick up the noctalia/hyprland.lua autostart"
c_info "entries for spotify-launcher and 'spicetify watch -s' — those sync via git, not this script."
c_info "To start live color-watching right now without reloading: spicetify watch -s &"
