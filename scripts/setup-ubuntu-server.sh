#!/usr/bin/env bash
set -Eeuo pipefail

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
  log_info "$*"
  "$@"
}

trap 'log_error "Script failed at line $LINENO"' ERR

# ==========================================================
# Helpers
# ==========================================================

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

sudo_keep_alive() {
  sudo -v
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
}

log_ok "Starting SERVER terminal environment setup 🚀"
sudo_keep_alive

# ==========================================================
# System Update
# ==========================================================

section "System Update"

run sudo apt update -y
run sudo apt upgrade -y
log_ok "System packages updated"

# ==========================================================
# Core Server Packages
# ==========================================================

section "Core Server Packages"

run sudo apt install -y \
  zsh \
  git \
  curl \
  wget \
  build-essential \
  vim \
  neovim \
  tmux \
  stow \
  btop \
  unzip \
  ca-certificates \
  gnupg \
  lsb-release \
  nala \
  htop \
  net-tools \
  dnsutils \
  jq \
  less \
  rsync

log_ok "Core server packages installed"

# ==========================================================
# Oh My Zsh (non-interactive)
# ==========================================================

section "Oh My Zsh"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  log_ok "Oh My Zsh installed"
else
  log_info "Oh My Zsh already installed"
fi

# ==========================================================
# Default Shell (Server Safe)
# ==========================================================

section "Default Shell"

if [ "$SHELL" != "$(which zsh)" ]; then
  run chsh -s "$(which zsh)"
  log_ok "ZSH set as default shell"
else
  log_info "ZSH already default shell"
fi

# ==========================================================
# ZSH Plugins
# ==========================================================

section "ZSH Plugins"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_plugin() {
  local repo="$1"
  local dir="$2"

  if [ -d "$dir" ]; then
    log_info "$(basename "$dir") already present"
  else
    run git clone "$repo" "$dir"
    log_ok "$(basename "$dir") installed"
  fi
}

clone_plugin https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

clone_plugin https://github.com/zsh-users/zsh-completions \
  "$ZSH_CUSTOM/plugins/zsh-completions"

clone_plugin https://github.com/zsh-users/zsh-history-substring-search \
  "$ZSH_CUSTOM/plugins/zsh-history-substring-search"

# ==========================================================
# pnpm-shell-completion
# ==========================================================

section "pnpm Shell Completion"

PNPM_COMPLETION_VERSION="0.5.5"
PNPM_COMPLETION_ARCH="x86_64-unknown-linux-gnu"
TMP_DIR="$(mktemp -d)"

log_info "Installing pnpm shell completion v${PNPM_COMPLETION_VERSION}"

curl -fsSL \
  "https://github.com/g-plane/pnpm-shell-completion/releases/download/v${PNPM_COMPLETION_VERSION}/pnpm-shell-completion_${PNPM_COMPLETION_ARCH}.tar.gz" \
  | tar -xz -C "$TMP_DIR"

if [ ! -f "$TMP_DIR/install.zsh" ]; then
  log_error "install.zsh not found after extraction"
  ls -la "$TMP_DIR"
  exit 1
fi

(
  cd "$TMP_DIR"
  run chmod +x install.zsh
  run ./install.zsh "$ZSH_CUSTOM/plugins"
)

run rm -rf "$TMP_DIR"

log_ok "pnpm shell completion installed"

# ==========================================================
# fnm + Node (LTS only)
# ==========================================================

section "Node (fnm)"

if ! command_exists fnm; then
  run curl -fsSL https://fnm.vercel.app/install | bash
fi

export PATH="$HOME/.fnm:$PATH"
eval "$(fnm env)"

run fnm install --lts
run fnm default lts-latest
log_ok "Node LTS installed"

# ==========================================================
# Bun (Optional but Fast)
# ==========================================================

section "Bun"

if ! command_exists bun; then
  run curl -fsSL https://bun.sh/install | bash
  log_ok "Bun installed"
else
  log_info "Bun already installed"
fi

# ==========================================================
# Docker (Server Safe)
# ==========================================================

section "Docker"

if ! command_exists docker; then
  run curl -fsSL https://get.docker.com | sh
  run sudo usermod -aG docker "$USER"
  log_ok "Docker installed (logout required)"
else
  log_info "Docker already installed"
fi

# ==========================================================
# Homebrew (Optional on Servers)
# ==========================================================

section "Homebrew (Optional)"

if ! command_exists brew; then
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  log_ok "Homebrew installed"
else
  log_info "Homebrew already installed"
fi

# ==========================================================
# Brew CLI Tools
# ==========================================================

section "Brew CLI Tools"

run brew install \
  fd \
  ripgrep \
  bat \
  eza \
  zoxide \
  fzf \
  starship \
  git-delta \
  fastfetch

log_ok "Brew CLI tools installed"

# ==========================================================
# Dotfiles (Server Profile)
# ==========================================================

section "Dotfiles (Server)"

cd "$HOME/dot-files"

run rm -rf \
  ~/.zshrc \
  ~/.bashrc \
  ~/.config/nvim \
  ~/.config/starship.toml \
  ~/.tmux.conf

run stow \
  bashrc \
  zshrc \
  git \
  nvim \
  tmux \
  starship \
  btop

log_ok "Server dotfiles stowed"

# ==========================================================
# Completed
# ==========================================================

section "Completed"

log_ok "Server terminal setup complete 🎉"
log_info "Logout/login required for shell & docker group changes"
