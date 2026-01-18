# ==========================================================
# ZSH MAIN ENTRY
# ==========================================================

# Core environment and shell settings (Immediate)
source ~/.zsh/envs.zsh
source ~/.zsh/shell.zsh

# Performance Plugin Manager
source ~/.zsh/zinit.zsh

# Logic modules
source ~/.zsh/aliases.zsh
source ~/.zsh/functions.zsh

# Post-init scripts
source ~/.zsh/init.zsh

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
alias l='ls'
alias la='ls -la'
alias oc='opencode'
alias c='clear'
alias rip="rip --graveyard ~/.local/share/Trash"
