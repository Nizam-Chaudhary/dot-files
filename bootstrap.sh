#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================================
# Bootstrap
# ==========================================================

# Resolve repo root safely
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPTS_DIR="$REPO_ROOT/scripts"
STOW_SCRIPT="$SCRIPTS_DIR/stow.sh"
FONTS_SCRIPT="$SCRIPTS_DIR/install-fonts.sh"
ARCH_SCRIPT="$SCRIPTS_DIR/setup-arch.sh"
UBUNTU_SCRIPT="$SCRIPTS_DIR/setup-ubuntu.sh"
UBUNTU_SERVER_SCRIPT="$SCRIPTS_DIR/setup-ubuntu-server.sh"
UBUNTU_WSL_SCRIPT="$SCRIPTS_DIR/setup-ubuntu-wsl.sh"

# ==========================================================
# Enhanced Logging
# ==========================================================
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'

log_ts() { date +"%Y-%m-%d %H:%M:%S"; }

log_info()  { printf "[%s] ${BLUE}INFO${NC}  %s\n" "$(log_ts)" "$*"; }
log_ok()    { printf "[%s] ${GREEN}OK${NC}    %s\n" "$(log_ts)" "$*"; }
log_warn()  { printf "[%s] ${YELLOW}WARN${NC}  %s\n" "$(log_ts)" "$*"; }
log_error() { printf "[%s] ${RED}ERROR${NC} %s\n" "$(log_ts)" "$*"; }

section() {
  echo -e "\n${CYAN}══════════════════════════════════════════════════════"
  echo -e " ▶ $1"
  echo -e "══════════════════════════════════════════════════════${NC}"
}

run() {
  log_info "Executing: $*"
  "$@"
}

trap 'log_error "Script failed at line $LINENO"' ERR

# ==========================================================
# Helpers
# ==========================================================
ensure_executable() {
  local script="$1"

  if [[ ! -f "$script" ]]; then
    log_error "$(basename "$script") not found"
    exit 1
  fi

  if [[ ! -x "$script" ]]; then
    log_warn "$(basename "$script") is not executable — fixing"
    chmod +x "$script"
  fi
}

show_usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Bootstrap dotfiles and system setup.

OPTIONS:
  -f, --fonts           Install fonts
  -d, --dotfiles        Setup dotfiles (stow)
  -a, --arch            Setup Arch Linux
  -u, --ubuntu          Setup Ubuntu Desktop
  -w, --wsl             Setup WSL Ubuntu
  -s, --server          Setup Ubuntu Server
  -h, --help            Show this help message

If no options are provided, defaults to running setup-ubuntu-server.sh

EXAMPLES:
  $(basename "$0")                # Run Ubuntu Server setup (default)
  $(basename "$0") --fonts        # Install fonts only
  $(basename "$0") --arch         # Setup Arch Linux
  $(basename "$0") -d -f          # Setup dotfiles and install fonts

EOF
}

# ==========================================================
# Parse Arguments
# ==========================================================
ACTION=""

if [[ $# -eq 0 ]]; then
  # No arguments provided, default to Ubuntu Server setup
  ACTION="server"
else
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--fonts)
        ACTION="fonts"
        shift
        ;;
      -d|--dotfiles)
        ACTION="dotfiles"
        shift
        ;;
      -a|--arch)
        ACTION="arch"
        shift
        ;;
      -u|--ubuntu)
        ACTION="ubuntu"
        shift
        ;;
      -w|--wsl)
        ACTION="wsl"
        shift
        ;;
      -s|--server)
        ACTION="server"
        shift
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done
fi

# ==========================================================
# Execute Action
# ==========================================================
section "Dotfiles Bootstrap"

case "$ACTION" in
  fonts)
    section "Install Fonts"
    ensure_executable "$FONTS_SCRIPT"
    run "$FONTS_SCRIPT"
    ;;
  dotfiles)
    section "Setup Dotfiles"
    ensure_executable "$STOW_SCRIPT"
    run "$STOW_SCRIPT"
    ;;
  arch)
    section "Setup Arch Linux"
    ensure_executable "$ARCH_SCRIPT"
    run "$ARCH_SCRIPT"
    ;;
  ubuntu)
    section "Setup Ubuntu Desktop"
    ensure_executable "$UBUNTU_SCRIPT"
    run "$UBUNTU_SCRIPT"
    ;;
  server)
    section "Setup Ubuntu Server"
    ensure_executable "$UBUNTU_SERVER_SCRIPT"
    run "$UBUNTU_SERVER_SCRIPT"
    ;;
  wsl)
    section "Setup WSL Ubuntu Distro"
    ensure_executable "$UBUNTU_WSL_SCRIPT"
    run "$UBUNTU_WSL_SCRIPT"
    ;;
  *)
    log_error "No valid action specified"
    show_usage
    exit 1
    ;;
esac

log_ok "Bootstrap completed successfully"
