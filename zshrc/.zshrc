# Add deno completions to search path
if [[ ":$FPATH:" != *":/home/nizam/.zsh/completions:"* ]]; then export FPATH="/home/nizam/.zsh/completions:$FPATH"; fi
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# zsh completions
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
autoload -U compinit && compinit

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# starship prompt
# eval "$(starship init zsh)"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"

zstyle ':omz:update' mode auto      # update automatically without asking

zstyle ':omz:update' frequency 7

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Add wisely, as too many plugins slow down shell startup.
plugins=(git fzf extract eza sudo npm node docker docker-compose zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search)

source $ZSH/oh-my-zsh.sh

# Ignore commands that start with spaces and duplicates.
export HISTCONTROL=ignoreboth

# Don't add certain commands to the history file.
export HISTIGNORE="&:[bf]g:c:clear:history:exit:q:pwd:* --help"s

# Use custom `less` colors for `man` pages.
export LESS_TERMCAP_md="$(tput bold 2> /dev/null; tput setaf 2 2> /dev/null)"
export LESS_TERMCAP_me="$(tput sgr0 2> /dev/null)"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
#alias open="xdg-open"
alias make="make -j`nproc`"
alias ninja="ninja -j`nproc`"
alias n="ninja"
alias c="clear"
# alias rmpkg="sudo pacman -Rsn"
# alias cleanch="sudo pacman -Scc"
# alias fixpacman="sudo rm /var/lib/pacman/db.lck"
# alias update="sudo pacman -Syu"

# Fish-like syntax highlighting and autosuggestions
# source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Use history substring search
# source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# pkgfile "command not found" handler
# source /usr/share/doc/pkgfile/command-not-found.zsh


# Make new shells get the history lines from all previous
# shells instead of the default "last window closed" history.
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# if [ -x "$(command -v gnome-text-editor)" ]; then
#     alias note="gnome-text-editor"
#     alias text="gnome-text-editor"
# fi

bindkey ^H backward-delete-word

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export GPG_TTY=$(tty)
export PATH=$HOME/.local/bin:$PATH

export GPG_TTY=$(tty)

# Set up fzf key bindings and fuzzy completion
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# source <(fzf --zsh)

# pnpm
export PNPM_HOME="/home/nizam/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# fnm
FNM_PATH="/home/nizam/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

# SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gcr/ssh

# fnm
FNM_PATH="/home/nizam/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/nizam/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi

# Starship
eval "$(starship init zsh)"
