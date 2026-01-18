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
# KEYBINDINGS (Modern/Standard)
# ==========================================================

# Use emacs keymap (default for Zsh, enables Ctrl+A, Ctrl+E, etc.)
bindkey -e

# --- Navigation (Ctrl + Arrows) ---
bindkey '^[[1;5C' forward-word          # Ctrl + Right Arrow
bindkey '^[[1;5D' backward-word         # Ctrl + Left Arrow

# --- Navigation (Home/End) ---
bindkey '^[[H' beginning-of-line        # Home Key
bindkey '^[[F' end-of-line              # End Key

# --- Deletion ---
bindkey '^H' backward-kill-word         # Ctrl + Backspace
bindkey '^[[3;5~' kill-word             # Ctrl + Delete (Forward)
bindkey '^[[3~' delete-char             # Delete Key (Forward)
bindkey '^H' backward-kill-word         # Ctrl + Backspace
bindkey '^[[3;5~' kill-word             # Ctrl + Delete (Forward)

# --- Completion & Search ---
bindkey '^[[Z' reverse-menu-complete    # Shift + Tab (Cycle backwards)
bindkey '^R' history-incremental-search-backward # Ctrl + R

# --- History Substring Search ---
# Hooked to Arrow Keys (Requires history-substring-search plugin)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
