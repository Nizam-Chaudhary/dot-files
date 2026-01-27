if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

if command -v try &> /dev/null; then
  eval "$(try init ~/Work/tries)"
fi

if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi

# Load atuin env if present
if [[ -f "$HOME/.atuin/bin/env" ]]; then
  source "$HOME/.atuin/bin/env"
fi

# Initialize atuin only if available
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi

