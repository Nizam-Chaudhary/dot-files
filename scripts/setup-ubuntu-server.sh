#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================================
# Configuration
# ==========================================================

PNPM_COMPLETION_VERSION="0.5.5"
PNPM_COMPLETION_ARCH="x86_64-unknown-linux-gnu"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dot-files}"

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

trap 'log_error "Script failed at line $LINENO with exit code $?"' ERR

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

check_prerequisites() {
  if [ ! -d "$DOTFILES_DIR" ]; then
    log_error "Dotfiles directory not found at: $DOTFILES_DIR"
    log_info "Please clone your dotfiles or set DOTFILES_DIR environment variable"
    exit 1
  fi
}

# ==========================================================
# Initialization
# ==========================================================

log_ok "Starting SERVER terminal environment setup 🚀"
check_prerequisites
sudo_keep_alive

# ==========================================================
# System Update
# ==========================================================

section "System Update"

if command_exists nala; then
  run sudo nala update
  run sudo nala upgrade -y
else
  run sudo apt update -y
  run sudo apt upgrade -y
fi
log_ok "System packages updated"

# ==========================================================
# Core Server Packages
# ==========================================================

section "Core Server Packages"

PACKAGES=(
  zsh
  git
  curl
  wget
  build-essential
  vim
  neovim
  tmux
  stow
  btop
  unzip
  ca-certificates
  gnupg
  lsb-release
  nala
  htop
  net-tools
  dnsutils
  jq
  less
  rsync
  tree
  ncdu
  ripgrep
)

# Check which packages need to be installed
PACKAGES_TO_INSTALL=()
for pkg in "${PACKAGES[@]}"; do
  if ! dpkg -l | grep -q "^ii  $pkg "; then
    PACKAGES_TO_INSTALL+=("$pkg")
  fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
  log_info "Installing ${#PACKAGES_TO_INSTALL[@]} packages..."
  run sudo apt install -y "${PACKAGES_TO_INSTALL[@]}"
  log_ok "Core server packages installed"
else
  log_info "All core packages already installed"
fi

# ==========================================================
# Oh My Zsh (non-interactive)
# ==========================================================

section "Oh My Zsh"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log_info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  log_ok "Oh My Zsh installed"
else
  log_info "Oh My Zsh already installed"
  
  # Update Oh My Zsh
  log_info "Updating Oh My Zsh..."
  (cd "$HOME/.oh-my-zsh" && git pull) || log_warn "Failed to update Oh My Zsh"
fi

# ==========================================================
# Default Shell (Server Safe)
# ==========================================================

section "Default Shell"

if [ "$SHELL" != "$(which zsh)" ]; then
  run chsh -s "$(which zsh)"
  log_ok "ZSH set as default shell (logout required)"
else
  log_info "ZSH already default shell"
fi

# ==========================================================
# Clone TPM
# ==========================================================

section "TPM (Tmux Plugin Manager)"

# Clone TPM only if not already installed
TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ -d "$TPM_DIR" ]; then
  log_info "TPM already installed"
else
  run git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  log_ok "TPM installed successfully"
fi

# ==========================================================
# ZSH Plugins
# ==========================================================

section "ZSH Plugins"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_or_update_plugin() {
  local repo="$1"
  local dir="$2"
  local name="$(basename "$dir")"

  if [ -d "$dir" ]; then
    log_info "Updating $name..."
    (cd "$dir" && git pull) || log_warn "Failed to update $name"
  else
    log_info "Installing $name..."
    run git clone "$repo" "$dir"
    log_ok "$name installed"
  fi
}

clone_or_update_plugin https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

clone_or_update_plugin https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

clone_or_update_plugin https://github.com/zsh-users/zsh-completions \
  "$ZSH_CUSTOM/plugins/zsh-completions"

clone_or_update_plugin https://github.com/zsh-users/zsh-history-substring-search \
  "$ZSH_CUSTOM/plugins/zsh-history-substring-search"

# ==========================================================
# pnpm-shell-completion
# ==========================================================

section "pnpm Shell Completion"

PNPM_PLUGIN_DIR="$ZSH_CUSTOM/plugins/pnpm-shell-completion"

if [ ! -d "$PNPM_PLUGIN_DIR" ]; then
  log_info "Installing pnpm shell completion v${PNPM_COMPLETION_VERSION}"
  
  TMP_DIR="$(mktemp -d)"
  trap "rm -rf '$TMP_DIR'" EXIT
  
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
  
  log_ok "pnpm shell completion installed"
else
  log_info "pnpm shell completion already installed"
fi

# ==========================================================
# fnm + Node (LTS)
# ==========================================================

section "Node (fnm)"

if ! command_exists fnm; then
  log_info "Installing fnm..."
  run curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
  log_ok "fnm installed"
fi

# Ensure fnm is in PATH
export PATH="$HOME/.local/share/fnm:$PATH"
if command_exists fnm; then
  eval "$(fnm env --use-on-cd)"
fi

# Install Node LTS if not present
if ! fnm list | grep -q "lts"; then
  log_info "Installing Node LTS..."
  run fnm install --lts
  run fnm default lts-latest
  log_ok "Node LTS installed"
else
  log_info "Node LTS already installed"
  fnm list
fi

# ==========================================================
# pnpm (Package Manager)
# ==========================================================

section "pnpm"

if ! command_exists pnpm; then
  log_info "Installing pnpm..."
  run npm install -g pnpm
  log_ok "pnpm installed"
else
  log_info "pnpm already installed ($(pnpm --version))"
fi

# ==========================================================
# Bun (Optional but Fast)
# ==========================================================

section "Bun"

if ! command_exists bun; then
  log_info "Installing Bun..."
  run curl -fsSL https://bun.sh/install | bash
  log_ok "Bun installed"
else
  log_info "Bun already installed ($(bun --version))"
fi

# ==========================================================
# Docker (Server Safe)
# ==========================================================

section "Docker"

if ! command_exists docker; then
  log_info "Installing Docker..."
  run curl -fsSL https://get.docker.com | sh
  run sudo usermod -aG docker "$USER"
  log_ok "Docker installed (logout required for group changes)"
else
  log_info "Docker already installed ($(docker --version))"
  
  # Check if user is in docker group
  if ! groups | grep -q docker; then
    log_warn "User not in docker group, adding..."
    run sudo usermod -aG docker "$USER"
    log_ok "Added to docker group (logout required)"
  fi
fi

# ==========================================================
# Docker Compose
# ==========================================================

section "Docker Compose"

if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
  log_info "Installing Docker Compose plugin..."
  DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
  mkdir -p "$DOCKER_CONFIG/cli-plugins"
  curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
  chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
  log_ok "Docker Compose installed"
else
  log_info "Docker Compose already available"
fi

# ==========================================================
# Homebrew (Optional on Servers)
# ==========================================================

section "Homebrew"

if ! command_exists brew; then
  log_info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Add to shell profile
  BREW_PREFIX="/home/linuxbrew/.linuxbrew"
  if [ -d "$BREW_PREFIX" ]; then
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$($BREW_PREFIX/bin/brew shellenv)"
  fi
  log_ok "Homebrew installed"
else
  log_info "Homebrew already installed"
  eval "$(brew shellenv)"
fi

# ==========================================================
# Brew CLI Tools
# ==========================================================

section "Brew CLI Tools"

BREW_PACKAGES=(
  fd
  ripgrep
  bat
  eza
  zoxide
  fzf
  starship
  git-delta
  fastfetch
  lazygit
  lazydocker
)

for pkg in "${BREW_PACKAGES[@]}"; do
  if ! brew list "$pkg" >/dev/null 2>&1; then
    log_info "Installing $pkg..."
    run brew install "$pkg"
  else
    log_info "$pkg already installed"
  fi
done

log_ok "Brew CLI tools installed"

# Setup fzf key bindings if not done
if command_exists fzf && [ ! -f "$HOME/.fzf.zsh" ]; then
  log_info "Setting up fzf key bindings..."
  $(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc
fi

# # ==========================================================
# # Rust (Optional but Useful)
# # ==========================================================

# section "Rust (Optional)"

# if ! command_exists rustc; then
#   log_info "Installing Rust..."
#   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
#   source "$HOME/.cargo/env"
#   log_ok "Rust installed"
# else
#   log_info "Rust already installed ($(rustc --version))"
# fi

# ==========================================================
# Dotfiles (Server Profile)
# ==========================================================

section "Dotfiles (Server)"

cd "$DOTFILES_DIR"

# Backup existing configs
backup_if_exists() {
  local file="$1"
  if [ -e "$file" ] && [ ! -L "$file" ]; then
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    log_warn "Backing up existing $file to $backup"
    mv "$file" "$backup"
  fi
}

backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.bashrc"
backup_if_exists "$HOME/.config/nvim"
backup_if_exists "$HOME/.config/starship.toml"
backup_if_exists "$HOME/.tmux.conf"

# Remove if they're already symlinks (stow will recreate)
rm -f "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.tmux.conf"
rm -rf "$HOME/.config/nvim" "$HOME/.config/starship.toml"

log_info "Stowing dotfiles..."
STOW_DIRS=(
  bashrc
  zshrc
  git
  nvim
  tmux
  starship
  btop
)

for dir in "${STOW_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    run stow "$dir"
    log_ok "Stowed $dir"
  else
    log_warn "Directory $dir not found, skipping"
  fi
done

log_ok "Server dotfiles stowed"

# ==========================================================
# Final Steps
# ==========================================================

section "Final Configuration"

# Create common directories
mkdir -p "$HOME/.config"
mkdir -p "$HOME/projects"
mkdir -p "$HOME/bin"

log_ok "Common directories created"

# ==========================================================
# Summary
# ==========================================================

section "Setup Complete! 🎉"

log_ok "Server terminal setup complete"
echo ""
echo "Important notes:"
echo "  • Logout/login required for shell & docker group changes"
echo "  • Run 'source ~/.zshrc' to apply ZSH configuration"
echo "  • Docker commands will work after re-login"
echo ""
echo "Installed tools:"
echo "  • ZSH with Oh My Zsh and plugins"
echo "  • Node.js ($(node --version 2>/dev/null || echo 'logout required'))"
echo "  • Docker ($(docker --version 2>/dev/null || echo 'installed'))"
echo "  • Modern CLI tools (eza, bat, ripgrep, fzf, etc.)"
echo ""
log_info "Happy coding! 🚀"