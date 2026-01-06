# ===============================
# ENV & CORE SETTINGS
# ===============================

# Locale (safe)
export LANG="en_IN.UTF-8"
export LC_CTYPE="en_IN.UTF-8"

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Rancher Desktop (preserved)
export PATH="$HOME/.rd/bin:$PATH"

# Cargo
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# History (bash-native, clean)
export HISTFILE=~/.bash_history
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
PROMPT_COMMAND="history -a; history -n; $PROMPT_COMMAND"

# Git perf
export GIT_OPTIONAL_LOCKS=0

# SSH / GPG (guarded)
export GPG_TTY="$(tty)"
if [[ -S "$XDG_RUNTIME_DIR/gcr/ssh" ]]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
fi
