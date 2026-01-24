# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

source ~/.bash/rc.bash

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
alias l='ls'
alias la='ls -la'
alias oc='opencode'
alias c='clear'
alias rip="rip --graveyard ~/.local/share/Trash"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

. "$HOME/.atuin/bin/env"

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"
