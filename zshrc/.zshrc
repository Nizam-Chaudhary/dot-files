# ~/.zshrc
# ===============================
# Minimal, structured zsh config
# ===============================

##### OHO MY ZSH COMPLETIONS #####
# Custom completions (deno, zsh-completions plugin)
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
autoload -U compinit && compinit
fpath+=($HOME/.zsh/pure)
autoload -U promptinit; promptinit

##### OH-MY-ZSH #####
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(
  git fzf sudo npm node docker docker-compose
  bun kubectl
  zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search
)

source $ZSH/oh-my-zsh.sh
# prompt pure

# Auto update OMZ without prompt (weekly)
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7

##### HOMEBREW #####
# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

##### HISTORY #####
export HISTCONTROL=ignoreboth
export HISTIGNORE="&:[bf]g:c:clear:history:exit:q:pwd:* --help"
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"


##### SHELL BEHAVIOR #####
DISABLE_MAGIC_FUNCTIONS="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

bindkey ^H backward-delete-word


##### EDITOR #####
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi


##### PATHS #####
export PATH="$HOME/.local/bin:$PATH"
export LC_ALL="en_IN.UTF-8"
export LANG="en_IN.UTF-8"


##### NVM #####
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"


##### BUN #####
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"


##### FNM (Fast Node Manager) #####
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env)"
fi

##### ZOXIDE #####
eval "$(zoxide init zsh)"
alias cd="z"

##### PNPM #####
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac


##### SSH / GPG #####
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gcr/ssh


##### ALIASES #####
alias make="make -j$(nproc)"
alias ninja="ninja -j$(nproc)"
alias n="ninja"
alias c="clear"

alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

##### PNPM Completions #####
# source /home/$USER/.oh-my-zsh/custom/plugins/pnpm-shell-completion/pnpm-shell-completion.plugin.zsh
source /usr/share/zsh/plugins/pnpm-shell-completion/pnpm-shell-completion.zsh

# bun completions
[ -s "/home/nizam/.bun/_bun" ] && source "/home/nizam/.bun/_bun"
