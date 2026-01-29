# ==========================================================
# SHELL SETTINGS & HISTORY
# ==========================================================

# History File Configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Shell Options
setopt HIST_IGNORE_ALL_DUPS  # Remove older duplicate entries from history
setopt SHARE_HISTORY         # Share history between all active terminals
setopt INC_APPEND_HISTORY    # Write to history file immediately (not on exit)
setopt INTERACTIVE_COMMENTS  # Allow comments (#) in the interactive shell
setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks from history strings

# ==========================================================
# KEYBINDINGS 
# ==========================================================

bindkey '^H' backward-kill-word    # Ctrl + W to delete word before cursor
