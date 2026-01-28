
if command -v try &> /dev/null; then
  eval "$(try init ~/Work/tries)"
fi

# Load atuin env if present
if [[ -f "$HOME/.atuin/bin/env" ]]; then
  source "$HOME/.atuin/bin/env"
fi

# Initialize atuin only if available
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi

