#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf "[fonts] %s\n" "$*"; }

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

JETBRAINS_FONT="JetBrainsMono Nerd Font"
CASCADIA_FONT="Cascadia Code Nerd Font"

JETBRAINS_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
CASCADIA_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip"

TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

font_installed() {
  fc-list | grep -qi "$1"
}

install_font() {
  local name="$1"
  local url="$2"
  local zip="$TMP_DIR/font.zip"

  if font_installed "$name"; then
    log "✔ $name already installed — skipping"
    return
  fi

  log "⬇ Installing $name"
  wget -qO "$zip" "$url"
  unzip -oq "$zip" -d "$FONT_DIR"
  log "✔ $name installed"
}

install_font "$JETBRAINS_FONT" "$JETBRAINS_URL"
install_font "$CASCADIA_FONT" "$CASCADIA_URL"

log "🔄 Updating font cache"
fc-cache -f "$FONT_DIR"

log "✅ Font installation complete"
