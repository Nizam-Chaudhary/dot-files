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
  local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
  log_warn "Backing up $file → $backup"
  mv "$file" "$backup"
}

# ==========================================================
# Init
# ==========================================================

log_ok "Starting Ubuntu Server setup 🚀"

if [[ ! -d "$DOTFILES_DIR" ]]; then
  log_error "Dotfiles directory not found: $DOTFILES_DIR"
  exit 1
fi

sudo_keep_alive

# ==========================================================
# System Update
# ==========================================================

section "System Update"

retry sudo apt update
retry sudo apt upgrade -y
log_ok "System updated"

# ==========================================================
# Core Server Packages
# ==========================================================

section "Core Packages (Server)"

PACKAGES=(
  zsh git curl wget build-essential
  vim neovim tmux stow
  btop htop unzip jq tree ncdu rsync
  ca-certificates gnupg lsb-release
  net-tools dnsutils
  software-properties-common
  apt-transport-https
  ripgrep
)

sudo apt install -y --no-install-recommends "${PACKAGES[@]}"
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
# TPM (tmux plugin manager)
# ==========================================================

section "TPM"

TPM_DIR="$HOME/.tmux/plugins/tpm"
[[ -d "$TPM_DIR" ]] || git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
log_ok "TPM ready"

# ==========================================================
# Homebrew (Optional but Supported)
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
# Brew CLI Tools
# ==========================================================

section "Brew Packages"

BREW_PACKAGES=(
  fd ripgrep bat eza fzf zoxide
  starship fastfetch git-delta
  lazygit lazydocker tlrc
)

brew install "${BREW_PACKAGES[@]}" || true
log_ok "Brew packages installed"

# ==========================================================
# Node (fnm)
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
fi

sudo systemctl enable docker --now
groups "$USER" | grep -q docker || sudo usermod -aG docker "$USER"

log_ok "Docker ready (logout required)"

# ==========================================================
# Dotfiles
# ==========================================================

section "Dotfiles"

cd "$DOTFILES_DIR"

backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.bashrc"
backup_if_exists "$HOME/.tmux.conf"
backup_if_exists "$HOME/.config/nvim"
backup_if_exists "$HOME/.config/starship.toml"

rm -f "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.tmux.conf"
rm -rf "$HOME/.config/nvim" "$HOME/.config/starship.toml"

STOW_DIRS=(bash btop fastfetch nvim starship tmux zsh)

for dir in "${STOW_DIRS[@]}"; do
  [[ -d "$dir" ]] && stow "$dir"
done

log_ok "Dotfiles applied"

# ==========================================================
# Manual Tools (Server)
# ==========================================================

section "Manual Tools"

cat <<'EOF'
Optional tools (install manually if needed):

• k9s
• ctop
• pgcli / mycli
• redis-cli
• mongosh

EOF

# ==========================================================
# Done
# ==========================================================

section "Setup Complete 🎉"

echo "✔ Ubuntu server ready"
echo "✔ Dev environment configured"
echo "✔ Logout required for Docker & ZSH"
log_ok "Happy hacking 🚀"
