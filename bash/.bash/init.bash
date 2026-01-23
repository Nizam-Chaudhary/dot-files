if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
fi

if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi

if command -v try &>/dev/null; then
  eval "$(try init ~/Work/tries)"
fi

if command -v fzf &>/dev/null; then
  if [[ -f /usr/share/fzf/completion.bash ]]; then
    source /usr/share/fzf/completion.bash
  fi
  if [[ -f /usr/share/fzf/key-bindings.bash ]]; then
    source /usr/share/fzf/key-bindings.bash
  fi
fi

if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Load atuin env if present
if [[ -f "$HOME/.atuin/bin/env" ]]; then
  source "$HOME/.atuin/bin/env"
fi

# bash-preexec (required for atuin)
if [[ -f "$HOME/.bash-preexec.sh" ]]; then
  source "$HOME/.bash-preexec.sh"
fi

# Initialize atuin only if available
if command -v atuin &>/dev/null; then
  eval "$(atuin init bash)"
fi
