# ===============================
# ENV & CORE SETTINGS
# ===============================

# Locale
export LANG="en_IN.UTF-8"
export LC_CTYPE="en_IN.UTF-8"

# Paths
export PATH="$HOME/.local/bin:$PATH"

# History (zsh-native, fast, shared)
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt EXTENDED_HISTORY
setopt HIST_VERIFY

# Shell behavior
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# Cargo
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Keybindings
bindkey '^?' backward-delete-char

# Git performance
export GIT_OPTIONAL_LOCKS=0

# SSH / GPG
export GPG_TTY=$(tty)
if [[ -S "$XDG_RUNTIME_DIR/gcr/ssh" ]]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
fi
