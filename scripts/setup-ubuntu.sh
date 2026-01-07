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
  while true; do
    sudo -n true
    sleep 120
    kill -0 "$$" || exit
  done 2>/dev/null &
}

backup_if_exists() {
  local file="$1"
  if [[ -e "$file" && ! -L "$file" ]]; then
    mv "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backed up $(basename "$file")"
  fi
  return 0
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
# Oh My Zsh + Oh My Bash
# ==========================================================

section "Oh My Zsh & Oh My Bash"

# --------------------------
# Oh My Zsh
# --------------------------

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log_info "Installing Oh My Zsh"
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log_info "Oh My Zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

ZSH_PLUGINS=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-completions
  zsh-users/zsh-history-substring-search
)

for repo in "${ZSH_PLUGINS[@]}"; do
  dir="$ZSH_CUSTOM/plugins/$(basename "$repo")"
  [[ -d "$dir" ]] || git clone "https://github.com/$repo" "$dir"
done

# Set zsh as default shell (only if user wants zsh)
if [[ "$SHELL" != "$(command -v zsh)" ]]; then
  chsh -s "$(command -v zsh)"
  log_warn "Default shell changed to zsh (logout required)"
fi

log_ok "Oh My Zsh configured"

# --------------------------
# Oh My Bash
# --------------------------

if [[ ! -d "$HOME/.oh-my-bash" ]]; then
  log_info "Installing Oh My Bash"
  bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" \
    -- --unattended
else
  log_info "Oh My Bash already installed"
fi

log_ok "Oh My Bash configured"


# ==========================================================
# Homebrew
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
  lazygit lazydocker tlrc
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
# pnpm Shell Completion (FIXED)
# ==========================================================

section "pnpm Shell Completion"

PNPM_PLUGIN_DIR="$ZSH_CUSTOM/plugins/pnpm-shell-completion"

if [[ ! -d "$PNPM_PLUGIN_DIR" ]]; then
  TMP_DIR="$(mktemp -d)"
  curl -fsSL \
    "https://github.com/g-plane/pnpm-shell-completion/releases/download/v${PNPM_COMPLETION_VERSION}/pnpm-shell-completion_${PNPM_COMPLETION_ARCH}.tar.gz" \
    | tar -xz -C "$TMP_DIR"
  (cd "$TMP_DIR" && ./install.zsh "$ZSH_CUSTOM/plugins")
fi

log_ok "pnpm completion ready"

# ==========================================================
# Docker
# ==========================================================

section "Docker"

if ! command_exists docker; then
  curl -fsSL https://get.docker.com | sh
  sudo systemctl enable docker --now
fi

groups "$USER" | grep -q docker || sudo usermod -aG docker "$USER"

log_ok "Docker ready (logout required)"

# ==========================================================
# Node (fnm)
# ==========================================================

section "Node"

if ! command_exists fnm; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi

export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env)" || true

fnm list | grep -q lts || fnm install --lts
fnm default lts-latest

# ==========================================================
# pnpm & Bun
# ==========================================================

section "pnpm & Bun"

command_exists npm || log_error "npm missing (Node install failed)"
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
backup_if_exists "$HOME/.config/zed"

rm -f "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.tmux.conf" "$HOME/.config/zed"

for dir in alacritty bash btop fastfetch ghostty kitty nvim starship tmux zed zsh; do
  [[ -d "$dir" ]] && stow --verbose "$dir"
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
log_ok "Logout required for Docker & shell"
log_ok "Happy coding 🚀"
