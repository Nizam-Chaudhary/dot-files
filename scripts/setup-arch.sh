#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================================
# Arch Linux Guard
# ==========================================================
if [[ ! -f /etc/arch-release ]]; then
  echo "❌ This script is for Arch Linux only"
  exit 1
fi

# ==========================================================
# Configuration
# ==========================================================

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dot-files}"
AUR_HELPER="yay"

# ==========================================================
# Logging
# ==========================================================

LOG_TS() { date +"%Y-%m-%d %H:%M:%S"; }

log() {
  local level="$1"; shift
  printf "[%s] %-5s %s\n" "$(LOG_TS)" "$level" "$*"
}

log_info()  { log INFO  "$*"; }
log_ok()    { log OK    "$*"; }
log_warn()  { log WARN  "$*"; }
log_error() { log ERROR "$*"; }

section() {
  echo ""
  echo "══════════════════════════════════════════════════════"
  echo "▶ $1"
  echo "══════════════════════════════════════════════════════"
}

run() {
  log_info "Running: $*"
  "$@"
}

trap 'log_error "Script failed at line $LINENO"' ERR

# ==========================================================
# Helpers
# ==========================================================

command_exists() { command -v "$1" &>/dev/null; }

pacman_installed() {
  pacman -Qi "$1" &>/dev/null
}

sudo_keep_alive() {
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

check_prerequisites() {
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    log_error "Dotfiles directory not found: $DOTFILES_DIR"
    exit 1
  fi
}

# ==========================================================
# Init
# ==========================================================

log_ok "Starting Arch Linux setup 🚀"
check_prerequisites
sudo_keep_alive

# ==========================================================
# System Update
# ==========================================================

section "System Update"

run sudo pacman -Syu --noconfirm
log_ok "System updated"

# ==========================================================
# Base Packages
# ==========================================================

section "Core Packages"

CORE_PACKAGES=(
  base-devel
  git
  curl
  wget
  zsh
  neovim
  vim
  tmux
  stow
  btop
  htop
  unzip
  jq
  tree
  ncdu
  rsync
  fd
  ripgrep
  bat
  eza
  fzf
  zoxide
  starship
  fastfetch
  lazygit
  git-delta
  tldr
  alacritty
  docker
  docker-compose
  docker-buildx
  docker-machine
  nodejs
  flatpak
  npm
  pnpm
  bun
)

sudo pacman -S --noconfirm --needed "${CORE_PACKAGES[@]}"

# Enable Flathub repository
if ! flatpak remote-list | grep -q flathub; then
  log_info "Adding Flathub remote..."
  run sudo flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo
  log_ok "Flathub enabled"
else
  log_info "Flathub already configured"
fi

log_ok "Core packages installed"

# ==========================================================
# AUR Helper (yay)
# ==========================================================

section "AUR Helper"

if ! command_exists yay; then
  log_info "Installing yay..."

  cd /tmp
  rm -rf yay
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm

  log_ok "yay installed"
else
  log_info "yay already installed"
fi

# ==========================================================
# GUI Applications (AUR / Repo)
# ==========================================================

section "GUI Applications"

AUR_GUI_APPS=(
  visual-studio-code-bin
  google-chrome
  postman-bin
  bruno-bin
  mongodb-compass
  redisinsight
  dbeaver
  obsidian
  tableplus
)

log_info "Installing GUI applications in one go..."
yay -S --noconfirm --needed "${AUR_GUI_APPS[@]}"

# ==========================================================
# GUI Applications (Flatpak)
# ==========================================================
FLATPAK_GUI_APPS=(
  md.obsidian.Obsidian
)

log_info "Installing Flatpak GUI applications..."
flatpak install -y "${FLATPAK_GUI_APPS[@]}"

# ==========================================================
# Zed Editor (Official Installer)
# ==========================================================

section "Zed Editor"

if command_exists zed; then
  log_info "Zed already installed ($(zed --version 2>/dev/null || echo installed))"
else
  log_info "Installing Zed using official installer..."
  run curl -f https://zed.dev/install.sh | sh
  log_ok "Zed installed successfully"
fi


log_ok "GUI apps installed"

# ==========================================================
# Docker setup
# ==========================================================

section "Docker Setup"

if ! systemctl is-enabled docker &>/dev/null; then
  run sudo systemctl enable --now docker
else
  log_info "Docker already enabled"
fi

if ! groups "$USER" | grep -q docker; then
  run sudo usermod -aG docker "$USER"
  log_warn "Logout required for docker group to take effect"
else
  log_info "User already in docker group"
fi

# ==========================================================
# Oh My Zsh
# ==========================================================

section "Oh My Zsh"

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

git clone https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true

git clone https://github.com/zsh-users/zsh-completions \
  "$ZSH_CUSTOM/plugins/zsh-completions" 2>/dev/null || true

log_ok "ZSH + plugins ready"

# ==========================================================
# Default Shell
# ==========================================================

section "Default Shell"

if [[ "$SHELL" != "$(which zsh)" ]]; then
  chsh -s "$(which zsh)"
  log_ok "ZSH set as default shell"
fi

# ==========================================================
# Dotfiles
# ==========================================================

section "Dotfiles"

cd "$DOTFILES_DIR"

STOW_DIRS=(
  zshrc
  bashrc
  git
  nvim
  tmux
  alacritty
  starship
  btop
)

for dir in "${STOW_DIRS[@]}"; do
  [[ -d "$dir" ]] && stow "$dir"
done

log_ok "Dotfiles stowed"

# ==========================================================
# Cleanup
# ==========================================================

section "Cleanup"

if pacman -Qtdq &>/dev/null; then
  sudo pacman -Rns $(pacman -Qtdq) --noconfirm
  log_ok "Removed orphan packages"
else
  log_info "No orphan packages found"
fi

# ==========================================================
# Final
# ==========================================================

section "Setup Complete 🎉"

echo "✔ System ready"
echo "✔ Docker enabled"
echo "✔ GUI apps installed via AUR"
echo "✔ Dev stack ready (Node, pnpm, Bun)"
echo ""
echo "⚠️ Logout required for docker & shell changes"
echo ""
log_ok "Happy hacking on Arch 🚀"
