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

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log_ok "Bootstrap complete — starting system setup 🚀"
sudo_keep_alive

# ==========================================================
# System Update
# ==========================================================

section "System Update"

run sudo apt update -y
run sudo apt upgrade -y
log_ok "System packages updated"

# ==========================================================
# Core Packages
# ==========================================================

section "Core Packages"

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
  aria2

log_ok "Core packages installed"

# ==========================================================
# Alacritty
# ==========================================================

section "Alacritty"

if ! command_exists alacritty; then
  run sudo apt install -y alacritty
  log_ok "Alacritty installed"
else
  log_info "Alacritty already installed"
fi

# ==========================================================
# Download helper
# ==========================================================

section "Download Helper"

if ! command_exists download; then
  run sudo cp "$SCRIPT_DIR/download" /usr/local/bin/download
  run sudo chmod +x /usr/local/bin/download
  log_ok "Download helper installed"
else
  log_info "Download helper already present"
fi

# ==========================================================
# Oh My Zsh
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
# Oh My Bash
# ==========================================================

section "Oh My Bash"

if [ ! -d "$HOME/.oh-my-bash" ]; then
  bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" || true
  log_ok "Oh My Bash installed"
else
  log_info "Oh My Bash already installed"
fi

# ==========================================================
# Default Shell
# ==========================================================

section "Default Shell"

if [ "$SHELL" != "$(which zsh)" ]; then
  run chsh -s "$(which zsh)"
  log_ok "ZSH set as default shell"
else
  log_info "ZSH already default shell"
fi

# ==========================================================
# Fonts
# ==========================================================

section "Fonts"

run chmod +x "$SCRIPT_DIR/install-fonts.sh"
run "$SCRIPT_DIR/install-fonts.sh"
log_ok "Fonts installed"

# ==========================================================
# Homebrew (Linuxbrew)
# ==========================================================

section "Homebrew"

if ! command_exists brew; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  log_ok "Homebrew installed"
else
  log_info "Homebrew already installed"
fi

# ==========================================================
# Brew Packages
# ==========================================================

section "Brew Packages"

run brew install \
  gcc \
  fd \
  ripgrep \
  bat \
  tree \
  zoxide \
  fzf \
  eza \
  fastfetch \
  starship \
  git-delta

log_ok "Brew packages installed"

# ==========================================================
# GUI Apps
# ==========================================================

section "GUI Applications"

if ! command_exists zed; then
  run curl -fsSL https://zed.dev/install.sh | sh
  log_ok "Zed installed"
else
  log_info "Zed already installed"
fi

if ! command_exists code; then
  run wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor > microsoft.gpg

  run sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
  run sudo sh -c \
    'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" \
     > /etc/apt/sources.list.d/vscode.list'

  run sudo apt update
  run sudo apt install -y code
  log_ok "VS Code installed"
else
  log_info "VS Code already installed"
fi

if ! command_exists google-chrome; then
  run wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  run sudo apt install -y ./google-chrome-stable_current_amd64.deb
  run rm google-chrome-stable_current_amd64.deb
  log_ok "Google Chrome installed"
else
  log_info "Google Chrome already installed"
fi

# ==========================================================
# Docker
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
# fnm + Node
# ==========================================================

section "Node (fnm)"

if ! command_exists fnm; then
  run curl -fsSL https://fnm.vercel.app/install | bash
fi

export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env)"
run fnm install --lts
run fnm default lts-latest
log_ok "Node LTS installed"

# ==========================================================
# Bun
# ==========================================================

section "Bun"

if ! command_exists bun; then
  run curl -fsSL https://bun.sh/install | bash
  log_ok "Bun installed"
else
  log_info "Bun already installed"
fi

# ==========================================================
# Dotfiles (Stow)
# ==========================================================

section "Dotfiles"

cd "$HOME/dot-files"

run rm -rf \
  ~/.zshrc \
  ~/.bashrc \
  ~/.config/nvim \
  ~/.config/alacritty \
  ~/.zed \
  ~/.config/ghostty

run stow \
  alacritty \
  bashrc \
  zshrc \
  btop \
  starship \
  ghostty \
  git \
  kitty \
  nvim \
  tmux \
  zed

log_ok "Dotfiles stowed"

# ==========================================================
# Manual Tools
# ==========================================================

section "Manual Installs"

cat <<'EOF'
• DBeaver        https://dbeaver.io/download/
• MongoDB Compass https://www.mongodb.com/try/download/compass
• Redis Insight  https://redis.com/redis-enterprise/redis-insight/
• Postman        https://www.postman.com/downloads/
• Bruno          https://www.usebruno.com/downloads
• TablePlus      https://tableplus.com/download
• Obsidian       https://obsidian.md/download
• Cursor         https://cursor.com /download
EOF

# ==========================================================
# Done
# ==========================================================

section "Completed"

log_ok "Setup complete 🎉"
log_info "Restart terminal or logout recommended"
