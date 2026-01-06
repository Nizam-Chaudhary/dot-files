# ===============================
# OH-MY-BASH & UTILITIES
# ===============================

export OSH="$HOME/.oh-my-bash"
OSH_THEME=""  # Starship owns the prompt

plugins=(git bashmarks)
aliases=(general)
completions=(git ssh)

[ -d "$OSH" ] && source "$OSH/oh-my-bash.sh"

# Homebrew (proper guarded loading)
BREW_PREFIX="/home/linuxbrew/.linuxbrew"
if [ -x "$BREW_PREFIX/bin/brew" ]; then
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
fi

# fzf (bash)
command -v fzf >/dev/null && eval "$(fzf --bash)"

# zoxide
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
