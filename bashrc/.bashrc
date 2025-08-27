# ~/.bashrc
# ===============================
# Minimal, structured bash config
# ===============================

# Run only in interactive shells
case $- in
  *i*) ;;
    *) return;;
esac


##### OH-MY-BASH #####
export OSH="$HOME/.oh-my-bash"
OSH_THEME="agnoster"

completions=(git composer ssh)
aliases=(general)
plugins=(git bashmarks)

source "$OSH/oh-my-bash.sh"


##### ALIASES #####
# eza / exa (modern ls)
if command -v eza &>/dev/null; then
  alias ls="eza --icons"
  alias la="eza --long --all --group --icons"
  alias l="eza -l --icons"
  alias tree="eza --tree"
elif command -v exa &>/dev/null; then
  alias ls="exa --icons"
  alias la="exa --long --all --group --icons"
  alias l="exa -l --icons"
  alias tree="exa --tree"
fi

# gnome-text-editor shortcuts
if command -v gnome-text-editor &>/dev/null; then
  alias note="gnome-text-editor"
  alias text="gnome-text-editor"
fi

alias vi=vim
alias vim=vim


##### NODE / JS TOOLS #####
# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env)"
fi

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


##### PACKAGE MANAGERS #####
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"


##### UTILITIES #####
# fzf fuzzy finder
command -v fzf &>/dev/null && eval "$(fzf --bash)"


# zoxide
eval "$(zoxide init bash)"
alias cd="z"


##### SSH / GPG #####
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gcr/ssh


##### PATHS #####
export PATH="$HOME/.local/bin:$PATH"
### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)


##### LOCALE #####
export LC_ALL="en_IN.UTF-8"
export LANG="en_IN.UTF-8"
