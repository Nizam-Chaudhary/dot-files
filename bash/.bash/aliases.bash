# ===============================
# ALIASES
# ===============================

# Modern ls
if command -v eza >/dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias la='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
elif command -v exa >/dev/null; then
  alias ls='exa -lh --group-directories-first --icons'
fi

# Navigation
alias zz='z'

# Editors
alias vi=vim
alias vim=vim

# Clear
alias c='clear'

# FZF helper
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
