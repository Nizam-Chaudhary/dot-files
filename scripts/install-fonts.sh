#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================================
# Configuration
# ==========================================================

FONT_DIR="${FONT_DIR:-$HOME/.local/share/fonts}"
NERD_FONTS_VERSION="v3.4.0"
NERD_FONTS_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}"
INPUT_MONO_URL="https://input.djr.com/build/?fontSelection=whole&a=0&g=0&i=0&l=0&zero=0&asterisk=0&braces=0&preset=default&line-height=1.2&accept=I+do&email="

# Font definitions: name, filename|url, display_name
# For Nerd Fonts: filename is used with NERD_FONTS_BASE_URL
# For Input Mono: use special URL format "INPUT_MONO_URL|InputMono.zip"
declare -A FONTS=(
  ["JetBrainsMono"]="JetBrainsMono.zip|JetBrainsMono Nerd Font"
  ["CascadiaCode"]="CascadiaCode.zip|Cascadia Code Nerd Font"
  ["GeistMono"]="GeistMono.zip|GeistMono Nerd Font"
  ["FiraCode"]="FiraCode.zip|FiraCode Nerd Font"
  ["Hack"]="Hack.zip|Hack Nerd Font"
  ["Meslo"]="Meslo.zip|Meslo Nerd Font"
  ["SourceCodePro"]="SourceCodePro.zip|SauceCodePro Nerd Font"
  ["UbuntuMono"]="UbuntuMono.zip|UbuntuMono Nerd Font"
  ["InputMono"]="INPUT_MONO_URL|InputMono.zip|Input Mono"
)

# Default fonts to install (can be overridden with -f flag)
DEFAULT_FONTS=("JetBrainsMono")

# ==========================================================
# Logging
# ==========================================================

log() { printf "[fonts] %s\n" "$*"; }
log_info() { printf "[fonts] ℹ️  %s\n" "$*"; }
log_ok() { printf "[fonts] ✅ %s\n" "$*"; }
log_warn() { printf "[fonts] ⚠️  %s\n" "$*"; }
log_error() { printf "[fonts] ❌ %s\n" "$*" >&2; }

# ==========================================================
# Helpers
# ==========================================================

show_usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install fonts (Nerd Fonts and Input Mono) for development environments.

OPTIONS:
  -f, --font FONT     Install specific font(s) (can be used multiple times)
  -a, --all           Install all available fonts
  -l, --list          List all available fonts
  -u, --update        Update existing fonts
  -c, --clean         Clean font cache before installation
  -h, --help          Show this help message

AVAILABLE FONTS:
$(for font in "${!FONTS[@]}"; do echo "  • $font"; done | sort)

EXAMPLES:
  $(basename "$0")                           # Install default fonts (JetBrains, Cascadia)
  $(basename "$0") -f FiraCode               # Install FiraCode only
  $(basename "$0") -f Hack -f Meslo          # Install Hack and Meslo
  $(basename "$0") -a                        # Install all fonts
  $(basename "$0") -u                        # Update all installed fonts

EOF
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

font_installed() {
  fc-list 2>/dev/null | grep -qi "$1"
}

check_dependencies() {
  local missing=()
  
  for cmd in wget unzip fc-cache fc-list; do
    if ! command_exists "$cmd"; then
      missing+=("$cmd")
    fi
  done
  
  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Missing required dependencies: ${missing[*]}"
    log_info "Install with: sudo apt install wget unzip fontconfig"
    exit 1
  fi
}

get_font_info() {
  local font_key="$1"
  local info="${FONTS[$font_key]}"
  
  # Handle Input Mono which has format: "INPUT_MONO_URL|InputMono.zip|Input Mono"
  if [[ "$font_key" == "InputMono" ]]; then
    local parts=($(echo "$info" | tr '|' '\n'))
    echo "${parts[1]}" "${parts[2]}"
  else
    # Other fonts: "filename|display_name"
    echo "${info%%|*}" "${info##*|}"
  fi
}

get_font_url() {
  local font_key="$1"
  local filename="$2"
  
  if [[ "$font_key" == "InputMono" ]]; then
    echo "$INPUT_MONO_URL"
  else
    echo "${NERD_FONTS_BASE_URL}/${filename}"
  fi
}

# ==========================================================
# Font Operations
# ==========================================================

install_font() {
  local font_key="$1"
  local update_mode="${2:-false}"
  
  if [ -z "${FONTS[$font_key]:-}" ]; then
    log_error "Unknown font: $font_key"
    return 1
  fi
  
  read -r filename display_name <<< "$(get_font_info "$font_key")"
  local url=$(get_font_url "$font_key" "$filename")
  local zip_file="${TMP_DIR}/${filename}"
  
  # Use different subdirectory structure for Input Mono vs Nerd Fonts
  if [[ "$font_key" == "InputMono" ]]; then
    local font_subdir="${FONT_DIR}/InputMono"
  else
    local font_subdir="${FONT_DIR}/NerdFonts/${font_key}"
  fi
  
  # Check if already installed by checking the font directory
  if [ "$update_mode" = "false" ] && [ -d "$font_subdir" ] && [ "$(find "$font_subdir" -type f \( -iname "*.ttf" -o -iname "*.otf" \) | wc -l)" -gt 0 ]; then
    log_ok "$display_name already installed — skipping"
    return 0
  fi
  
  # Create subdirectory for this font
  mkdir -p "$font_subdir"
  
  if [ "$update_mode" = "true" ]; then
    log_info "Updating $display_name..."
    # Remove old version
    rm -rf "$font_subdir"/*
  else
    log_info "Installing $display_name..."
  fi
  
  # Download with retry logic
  local max_retries=3
  local retry_count=0
  
  while [ $retry_count -lt $max_retries ]; do
    if wget -q --show-progress --progress=bar:force:noscroll -O "$zip_file" "$url" 2>&1; then
      break
    else
      retry_count=$((retry_count + 1))
      if [ $retry_count -lt $max_retries ]; then
        log_warn "Download failed, retrying ($retry_count/$max_retries)..."
        sleep 2
      else
        log_error "Failed to download $display_name after $max_retries attempts"
        return 1
      fi
    fi
  done
  
  # Extract all files first, then filter
  if ! unzip -oq "$zip_file" -d "$font_subdir" 2>/dev/null; then
    log_error "Failed to extract $display_name"
    return 1
  fi
  
  # Find and keep only font files (TTF, OTF)
  local font_files=$(find "$font_subdir" -type f \( -iname "*.ttf" -o -iname "*.otf" \))
  local count=$(echo "$font_files" | grep -c '^' || echo 0)
  
  if [ "$count" -eq 0 ]; then
    log_error "No font files found in $display_name archive"
    return 1
  fi
  
  # Remove non-font files
  find "$font_subdir" -type f ! \( -iname "*.ttf" -o -iname "*.otf" \) -delete
  find "$font_subdir" -type d -empty -delete
  
  log_ok "$display_name installed ($count font files)"
  return 0
}

list_fonts() {
  echo ""
  echo "Available Fonts:"
  echo "═══════════════════════════════════════════════════════"
  
  for font_key in $(echo "${!FONTS[@]}" | tr ' ' '\n' | sort); do
    read -r filename display_name <<< "$(get_font_info "$font_key")"
    
    local status="❌ Not installed"
    if font_installed "$display_name"; then
      status="✅ Installed"
    fi
    
    printf "  %-20s %s\n" "$font_key" "$status"
  done
  
  echo ""
}

list_installed_fonts() {
  echo ""
  echo "Installed Fonts:"
  echo "═══════════════════════════════════════════════════════"
  
  local found=0
  for font_key in $(echo "${!FONTS[@]}" | tr ' ' '\n' | sort); do
    read -r filename display_name <<< "$(get_font_info "$font_key")"
    
    if font_installed "$display_name"; then
      echo "  ✅ $display_name"
      found=1
    fi
  done
  
  if [ $found -eq 0 ]; then
    echo "  No fonts installed"
  fi
  
  echo ""
}

clean_font_cache() {
  log_info "Cleaning font cache..."
  
  # Remove cache files
  rm -rf "$HOME/.cache/fontconfig"
  rm -rf "$HOME/.fontconfig"
  
  # Rebuild cache
  fc-cache -f -v "$FONT_DIR" >/dev/null 2>&1
  
  log_ok "Font cache cleaned"
}

# ==========================================================
# Main Script
# ==========================================================

main() {
  local fonts_to_install=()
  local install_all=false
  local update_mode=false
  local clean_cache=false
  local list_only=false
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -f|--font)
        fonts_to_install+=("$2")
        shift 2
        ;;
      -a|--all)
        install_all=true
        shift
        ;;
      -l|--list)
        list_only=true
        shift
        ;;
      -u|--update)
        update_mode=true
        shift
        ;;
      -c|--clean)
        clean_cache=true
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
  
  # Check dependencies
  check_dependencies
  
  # Handle list mode
  if [ "$list_only" = true ]; then
    list_fonts
    list_installed_fonts
    exit 0
  fi
  
  # Create font directory
  mkdir -p "$FONT_DIR"
  
  # Clean cache if requested
  if [ "$clean_cache" = true ]; then
    clean_font_cache
  fi
  
  # Determine which fonts to install
  if [ "$install_all" = true ]; then
    fonts_to_install=("${!FONTS[@]}")
  elif [ ${#fonts_to_install[@]} -eq 0 ]; then
    fonts_to_install=("${DEFAULT_FONTS[@]}")
  fi
  
  # Validate font names
  for font in "${fonts_to_install[@]}"; do
    if [ -z "${FONTS[$font]:-}" ]; then
      log_error "Unknown font: $font"
      log_info "Use -l to list available fonts"
      exit 1
    fi
  done
  
  # Create temporary directory
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  
  # Install fonts
  log_info "Starting font installation..."
  echo ""
  
  local success_count=0
  local fail_count=0
  
  for font in "${fonts_to_install[@]}"; do
    if install_font "$font" "$update_mode"; then
      success_count=$((success_count + 1))
    else
      fail_count=$((fail_count + 1))
    fi
  done
  
  echo ""
  log_info "Updating font cache (this may take a moment)..."
  fc-cache -f "$FONT_DIR"
  
  # Summary
  echo ""
  echo "═══════════════════════════════════════════════════════"
  log_ok "Font installation complete!"
  echo ""
  echo "Summary:"
  echo "  ✅ Successfully installed: $success_count"
  if [ $fail_count -gt 0 ]; then
    echo "  ❌ Failed: $fail_count"
  fi
  echo "  📁 Font directory: $FONT_DIR"
  echo ""
  
  if [ $success_count -gt 0 ]; then
    log_info "Restart your terminal or applications to use the new fonts"
    log_info "Run 'fc-list | grep -i font' to verify installation"
  fi
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
