#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================================
# Configuration
# ==========================================================

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dot-files}"
PNPM_COMPLETION_VERSION="0.5.5"
PNPM_COMPLETION_ARCH="x86_64-unknown-linux-gnu"

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

package_installed() {
  dpkg -l | grep -q "^ii  $1 "
}

sudo_keep_alive() {
  sudo -v
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
}

backup_if_exists() {
  local file="$1"
  if [ -e "$file" ] && [ ! -L "$file" ]; then
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    log_warn "Backing up $file → $backup"
    mv "$file" "$backup"
  fi
}

check_prerequisites() {
  if [ ! -d "$DOTFILES_DIR" ]; then
    log_error "Dotfiles directory not found: $DOTFILES_DIR"
    log_info "Please clone your dotfiles or set DOTFILES_DIR environment variable"
    exit 1
  fi
}

clone_or_update_repo() {
  local repo="$1"
  local dir="$2"
  local name="$(basename "$dir")"

  if [ -d "$dir" ]; then
    log_info "Updating $name..."
    (cd "$dir" && git pull -q) || log_warn "Failed to update $name"
  else
    log_info "Installing $name..."
    run git clone -q "$repo" "$dir"
    log_ok "$name installed"
  fi
}

# ==========================================================
# Initialization
# ==========================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log_ok "Bootstrap complete — starting system setup 🚀"
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
# Core Packages
# ==========================================================

section "Core Packages"

CORE_PACKAGES=(
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
  aria2
  htop
  net-tools
  dnsutils
  jq
  less
  rsync
  tree
  ncdu
  software-properties-common
  apt-transport-https
)

PACKAGES_TO_INSTALL=()
for pkg in "${CORE_PACKAGES[@]}"; do
  if ! package_installed "$pkg"; then
    PACKAGES_TO_INSTALL+=("$pkg")
  fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
  log_info "Installing ${#PACKAGES_TO_INSTALL[@]} core packages..."
  run sudo apt install -y "${PACKAGES_TO_INSTALL[@]}"
  log_ok "Core packages installed"
else
  log_info "All core packages already installed"
fi

# ==========================================================
# Alacritty
# ==========================================================

section "Alacritty"

if ! command_exists alacritty; then
  if package_installed alacritty; then
    log_info "Alacritty already installed"
  else
    run sudo apt install -y alacritty
    log_ok "Alacritty installed"
  fi
else
  log_info "Alacritty already installed ($(alacritty --version | head -n1))"
fi

# ==========================================================
# Download Helper
# ==========================================================

section "Download Helper"

if [ -f "$SCRIPT_DIR/download" ]; then
  if ! command_exists download || ! cmp -s "$SCRIPT_DIR/download" /usr/local/bin/download; then
    run sudo cp "$SCRIPT_DIR/download" /usr/local/bin/download
    run sudo chmod +x /usr/local/bin/download
    log_ok "Download helper installed/updated"
  else
    log_info "Download helper already installed"
  fi
else
  log_warn "Download helper script not found at $SCRIPT_DIR/download"
fi

# ==========================================================
# Oh My Zsh
# ==========================================================

section "Oh My Zsh"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log_info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  log_ok "Oh My Zsh installed"
else
  log_info "Oh My Zsh already installed, updating..."
  (cd "$HOME/.oh-my-zsh" && git pull -q) || log_warn "Failed to update Oh My Zsh"
fi

# ==========================================================
# Oh My Bash
# ==========================================================

section "Oh My Bash"

if [ ! -d "$HOME/.oh-my-bash" ]; then
  log_info "Installing Oh My Bash..."
  bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended || true
  log_ok "Oh My Bash installed"
else
  log_info "Oh My Bash already installed, updating..."
  (cd "$HOME/.oh-my-bash" && git pull -q) || log_warn "Failed to update Oh My Bash"
fi

# ==========================================================
# Default Shell
# ==========================================================

section "Default Shell"

if [ "$SHELL" != "$(which zsh)" ]; then
  run chsh -s "$(which zsh)"
  log_ok "ZSH set as default shell (logout required)"
else
  log_info "ZSH already default shell"
fi

# ==========================================================
# Fonts
# ==========================================================

section "Fonts"

if [ -f "$SCRIPT_DIR/install-fonts.sh" ]; then
  run chmod +x "$SCRIPT_DIR/install-fonts.sh"
  run "$SCRIPT_DIR/install-fonts.sh"
  log_ok "Fonts installed"
else
  log_warn "Font installation script not found at $SCRIPT_DIR/install-fonts.sh"
fi

# ==========================================================
# Homebrew (Linuxbrew)
# ==========================================================

section "Homebrew"

if ! command_exists brew; then
  log_info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
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
# Brew Packages
# ==========================================================

section "Brew Packages"

BREW_PACKAGES=(
  gcc
  fd
  ripgrep
  bat
  tree
  zoxide
  fzf
  eza
  fastfetch
  starship
  git-delta
  lazygit
  lazydocker
  tldr
)

for pkg in "${BREW_PACKAGES[@]}"; do
  if ! brew list "$pkg" >/dev/null 2>&1; then
    log_info "Installing $pkg..."
    run brew install "$pkg"
  else
    log_info "$pkg already installed"
  fi
done

log_ok "Brew packages installed"

# Setup fzf key bindings
if command_exists fzf && [ ! -f "$HOME/.fzf.zsh" ]; then
  log_info "Setting up fzf key bindings..."
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

# ==========================================================
# GUI Applications
# ==========================================================

section "GUI Applications"

# Zed Editor
if ! command_exists zed; then
  log_info "Installing Zed..."
  run curl -fsSL https://zed.dev/install.sh | sh
  log_ok "Zed installed"
else
  log_info "Zed already installed"
fi

# VS Code
if ! command_exists code; then
  log_info "Installing VS Code..."
  
  run wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
  run sudo install -o root -g root -m 644 /tmp/microsoft.gpg /etc/apt/trusted.gpg.d/
  run rm /tmp/microsoft.gpg
  
  run sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
  
  run sudo apt update
  run sudo apt install -y code
  log_ok "VS Code installed"
else
  log_info "VS Code already installed ($(code --version | head -n1))"
fi

# Google Chrome
if ! command_exists google-chrome; then
  log_info "Installing Google Chrome..."
  
  TMP_CHROME="/tmp/google-chrome-stable_current_amd64.deb"
  run wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O "$TMP_CHROME"
  run sudo apt install -y "$TMP_CHROME"
  run rm "$TMP_CHROME"
  
  log_ok "Google Chrome installed"
else
  log_info "Google Chrome already installed ($(google-chrome --version))"
fi

# ==========================================================
# Docker
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

# Docker Compose
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
# ZSH Plugins
# ==========================================================

section "ZSH Plugins"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_or_update_repo https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

clone_or_update_repo https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

clone_or_update_repo https://github.com/zsh-users/zsh-completions \
  "$ZSH_CUSTOM/plugins/zsh-completions"

clone_or_update_repo https://github.com/zsh-users/zsh-history-substring-search \
  "$ZSH_CUSTOM/plugins/zsh-history-substring-search"

log_ok "ZSH plugins installed/updated"

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
# fnm + Node
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
if ! fnm list 2>/dev/null | grep -q "lts"; then
  log_info "Installing Node LTS..."
  run fnm install --lts
  run fnm default lts-latest
  log_ok "Node LTS installed ($(node --version))"
else
  log_info "Node LTS already installed ($(node --version))"
  fnm list
fi

# ==========================================================
# pnpm
# ==========================================================

section "pnpm"

if ! command_exists pnpm; then
  log_info "Installing pnpm..."
  run npm install -g pnpm
  log_ok "pnpm installed ($(pnpm --version))"
else
  log_info "pnpm already installed ($(pnpm --version))"
fi

# ==========================================================
# Bun
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
# Rust (Optional)
# ==========================================================

section "Rust (Optional)"

if ! command_exists rustc; then
  log_info "Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  source "$HOME/.cargo/env"
  log_ok "Rust installed ($(rustc --version))"
else
  log_info "Rust already installed ($(rustc --version))"
fi

# ==========================================================
# Dotfiles (Stow)
# ==========================================================

section "Dotfiles"

cd "$DOTFILES_DIR"

# Backup existing configs
backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.bashrc"
backup_if_exists "$HOME/.config/nvim"
backup_if_exists "$HOME/.config/alacritty"
backup_if_exists "$HOME/.zed"
backup_if_exists "$HOME/.config/ghostty"
backup_if_exists "$HOME/.config/starship.toml"
backup_if_exists "$HOME/.tmux.conf"

# Remove symlinks if they exist (stow will recreate)
rm -f "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.tmux.conf"
rm -rf "$HOME/.config/nvim" "$HOME/.config/alacritty" "$HOME/.zed" "$HOME/.config/ghostty"

STOW_DIRS=(
  alacritty
  bashrc
  zshrc
  btop
  starship
  ghostty
  git
  kitty
  nvim
  tmux
  zed
)

log_info "Stowing dotfiles..."
for dir in "${STOW_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    run stow -v "$dir" 2>&1 | grep -v "BUG in find_stowed_path" || true
    log_ok "Stowed $dir"
  else
    log_warn "Directory $dir not found in $DOTFILES_DIR, skipping"
  fi
done

log_ok "Dotfiles stowed"

# ==========================================================
# Final Setup
# ==========================================================

section "Final Configuration"

# Create common directories
mkdir -p "$HOME/.config"
mkdir -p "$HOME/projects"
mkdir -p "$HOME/bin"
mkdir -p "$HOME/Downloads"

log_ok "Common directories created"

# ==========================================================
# Manual Installations
# ==========================================================

section "Manual Installs"

cat <<'EOF'

The following tools require manual installation:

📦 Database Tools:
  • DBeaver         → https://dbeaver.io/download/
  • MongoDB Compass → https://www.mongodb.com/try/download/compass
  • Redis Insight   → https://redis.com/redis-enterprise/redis-insight/
  • TablePlus       → https://tableplus.com/download

📬 API Tools:
  • Postman         → https://www.postman.com/downloads/
  • Bruno           → https://www.usebruno.com/downloads

📝 Productivity:
  • Obsidian        → https://obsidian.md/download
  • Cursor          → https://cursor.com/download

🖥️  Terminals:
  • Ghostty         → https://ghostty.org/docs/install/binary#universal-appimage

EOF

# ==========================================================
# Summary
# ==========================================================

section "Setup Complete! 🎉"

log_ok "System setup complete"
echo ""
echo "📋 Summary:"
echo "  ✓ Core packages and tools installed"
echo "  ✓ Shell environment configured (ZSH + Oh My Zsh)"
echo "  ✓ Development tools installed (Node, Bun, Docker, Rust)"
echo "  ✓ GUI applications installed (VS Code, Chrome, Zed)"
echo "  ✓ Modern CLI tools installed (eza, bat, ripgrep, fzf, etc.)"
echo "  ✓ Dotfiles deployed"
echo ""
echo "⚠️  Important:"
echo "  • Logout/login required for shell & docker group changes"
echo "  • Run 'source ~/.zshrc' to apply ZSH configuration"
echo "  • Check manual installations list above"
echo ""
log_info "Happy coding! 🚀"