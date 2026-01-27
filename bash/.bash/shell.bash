# History control
shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=32768
HISTFILESIZE="${HISTSIZE}"

# Homebrew environment
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Bash completion (system + Homebrew)
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  export BASH_COMPLETION_COMPAT_DIR="/home/linuxbrew/.linuxbrew/etc/bash_completion.d"
  source /usr/share/bash-completion/bash_completion
fi

# Ensure command hashing is off for mise
set +h
