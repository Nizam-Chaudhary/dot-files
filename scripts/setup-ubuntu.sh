#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================================
# Ubuntu Guard
# ==========================================================

if ! grep -qi ubuntu /etc/os-release; then
  echo "❌ This script is for Ubuntu only"
  exit 1
fi

# ==========================================================
# Configuration
# ==========================================================

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dot-files}"
PNPM_COMPLETION_VERSION="0.5.5"
PNPM_COMPLETION_ARCH="x86_64-unknown-linux-gnu"

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

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

package_installed() {
  dpkg -s "$1" &>/dev/null
}

retry() {
  for _ in {1..3}; do
    "$@" && return
    sleep 2
  done
  return 1
}

sudo_keep_alive() {
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

backup_if_exists() {
  local file="$1"
  [[ -e "$file" && ! -L "$file" ]] || return
  mv "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
}

# ==========================================================
# Init
# ==========================================================

log_ok "Starting Ubuntu Desktop setup 🚀"
sudo_keep_alive

# ==========================================================
# System Update
# ==========================================================

section "System Update"

retry sudo apt update
retry sudo apt upgrade -y
log_ok "System updated"

# ==========================================================
# Core Packages (APT)
# ==========================================================

section "Core Packages"

CORE_PACKAGES=(
  zsh git curl wget build-essential
  vim neovim tmux stow
  btop htop unzip jq tree ncdu rsync
  ca-certificates gnupg lsb-release
  aria2 net-tools dnsutils
  software-properties-common
  apt-transport-https
  alacritty flatpak
)

sudo apt install -y --no-install-recommends "${CORE_PACKAGES[@]}"

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
# Oh My Zsh
# ==========================================================

section "Oh My Zsh"

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

for repo in \
  zsh-users/zsh-autosuggestions \
  zsh-users/zsh-syntax-highlighting \
  zsh-users/zsh-completions \
  zsh-users/zsh-history-substring-search
do
  dir="$ZSH_CUSTOM/plugins/$(basename "$repo")"
  [[ -d "$dir" ]] || git clone "https://github.com/$repo" "$dir"
done

if [[ "$SHELL" != "$(command -v zsh)" ]]; then
  chsh -s "$(command -v zsh)"
fi

log_ok "ZSH configured"

# ==========================================================
# Fonts
# ==========================================================

section "Fonts"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/install-fonts.sh" ]]; then
  chmod +x "$SCRIPT_DIR/install-fonts.sh"
  "$SCRIPT_DIR/install-fonts.sh"
fi

# ==========================================================
# Homebrew (Linuxbrew)
# ==========================================================

section "Homebrew"

if ! command_exists brew; then
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
else
  eval "$(brew shellenv)"
fi

# ==========================================================
# Brew Packages (Modern CLI only)
# ==========================================================

section "Brew Packages"

BREW_PACKAGES=(
  fd ripgrep bat eza fzf zoxide
  starship fastfetch git-delta
  lazygit lazydocker tldr
)

brew install "${BREW_PACKAGES[@]}"
log_ok "Brew packages installed"

# ==========================================================
# GUI Applications
# ==========================================================

section "GUI Applications"

# Zed
if ! command_exists zed; then
  retry curl -f https://zed.dev/install.sh | sh
fi

# VS Code
if ! command_exists code; then
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg >/dev/null
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" |
    sudo tee /etc/apt/sources.list.d/vscode.list
  sudo apt update
  sudo apt install -y code
fi

# Chrome
if ! command_exists google-chrome; then
  wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
  sudo apt install -y /tmp/chrome.deb
  rm /tmp/chrome.deb
fi

# ==========================================================
# GUI Applications (Flatpak)
# ==========================================================
FLATPAK_GUI_APPS=(
  md.obsidian.Obsidian
)

log_info "Installing Flatpak GUI applications..."
flatpak install -y "${FLATPAK_GUI_APPS[@]}"

log_ok "GUI applications installed"

# ==========================================================
# Docker (Official Repo)
# ==========================================================

section "Docker"

if ! command_exists docker; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

sudo systemctl enable docker --now

groups "$USER" | grep -q docker || sudo usermod -aG docker "$USER"
log_ok "Docker ready (logout required)"

# ==========================================================
# fnm + Node
# ==========================================================

section "Node (fnm)"

if ! command_exists fnm; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi

export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd)"

fnm install --lts || true
fnm default lts-latest

# ==========================================================
# pnpm + Bun
# ==========================================================

section "pnpm & Bun"

command_exists pnpm || npm install -g pnpm
command_exists bun  || curl -fsSL https://bun.sh/install | bash

# ==========================================================
# Dotfiles
# ==========================================================

section "Dotfiles"

cd "$DOTFILES_DIR"

backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.bashrc"
backup_if_exists "$HOME/.tmux.conf"

rm -f "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.tmux.conf"

STOW_DIRS=(alacritty bashrc zshrc btop starship git nvim tmux zed)

for dir in "${STOW_DIRS[@]}"; do
  [[ -d "$dir" ]] && stow "$dir"
done

log_ok "Dotfiles applied"

# ==========================================================
# Manual GUI Tools (Not Installed by Script)
# ==========================================================

section "Manual GUI Tools"

cat <<'EOF'
The following tools are NOT installed automatically and must be installed manually:

📦 Database & Dev Tools:
  • DBeaver
      https://dbeaver.io/download/

  • MongoDB Compass
      https://www.mongodb.com/try/download/compass

  • Redis Insight
      https://redis.com/redis-enterprise/redis-insight/

  • TablePlus
      https://tableplus.com/download

📬 API & Testing:
  • Postman
      https://www.postman.com/downloads/

  • Bruno
      https://www.usebruno.com/downloads

📝 Productivity:
  • Obsidian
      https://obsidian.md/download

  • Cursor
      https://cursor.sh

🖥️ Terminal:
  • Ghostty (AppImage)
      https://ghostty.org/docs/install/binary#universal-appimage

EOF

# ==========================================================
# Health Check
# ==========================================================

section "Health Check"

for cmd in git zsh docker node pnpm bun zed code google-chrome; do
  command_exists "$cmd" && log_ok "$cmd OK" || log_warn "$cmd missing"
done

# ==========================================================
# Done
# ==========================================================

section "Setup Complete 🎉"

echo "✔ Ubuntu desktop ready"
echo "✔ Dev environment configured"
echo "✔ Logout required for Docker & shell"
echo ""
log_ok "Happy coding 🚀"
