# ===============================
# Bash entry point (interactive only)
# ===============================

case $- in
  *i*) ;;
    *) return;;
esac

# Load order matters
source ~/.bash/env.bash
source ~/.bash/plugins.bash
source ~/.bash/node.bash
source ~/.bash/tmux.bash
source ~/.bash/aliases.bash

# Starship (force bash, do NOT trust $SHELL)
eval "$(starship init bash)"
