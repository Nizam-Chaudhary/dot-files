# ===============================
# ALIASES
# ===============================

# Build tools
alias make="make -j$(nproc)"
alias ninja="ninja -j$(nproc)"
alias n="ninja"

# Navigation
alias zz="z"

# Clear
alias c="clear"

# Listing (eza)
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'

# FZF
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

# Zoxide
alias cd="z"