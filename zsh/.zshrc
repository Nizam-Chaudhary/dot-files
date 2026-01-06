# ===============================
# ZSH ENTRY POINT
# ===============================

# Load order matters (fast → heavy → prompt)

source ~/.zsh/env.zsh
source ~/.zsh/plugins.zsh
source ~/.zsh/node.zsh
source ~/.zsh/tmux.zsh
source ~/.zsh/aliases.zsh

# Prompt (last)
eval "$(starship init zsh)"
