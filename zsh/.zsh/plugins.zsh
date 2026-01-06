# ===============================
# OH-MY-ZSH & PLUGINS
# ===============================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="" # Starship owns the prompt

plugins=(
  git sudo docker docker-compose kubectl
  npm bun pnpm-shell-completion node
  zsh-history-substring-search
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# OMZ auto-update (silent, weekly)
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7

# Homebrew (proper guarded loading)
BREW_PREFIX="/home/linuxbrew/.linuxbrew"

if [ -x "$BREW_PREFIX/bin/brew" ]; then
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
fi

# FZF (lazy + fast)
if command -v fzf >/dev/null; then
  source <(fzf --zsh)
fi

# Zoxide
eval "$(zoxide init zsh)"
