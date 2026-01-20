# ==========================================================
# ZINIT HIGH-PERFORMANCE CONFIG (Optimized & Fixed)
# ==========================================================

# 1. Core Zinit Loading
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"

# 2. Advanced Turbo Multi-Load
# Grouping everything here prevents "unhandled widget" errors by ensuring
# the search plugin is fully loaded before the syntax highlighter.
zinit wait"0" lucid for \
    OMZL::git.zsh \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
        zsh-users/zsh-completions \
    atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    zsh-users/zsh-history-substring-search \
    atload"zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting

# 3. Specialized Binary Plugins
# Handled with wait"1" to give core UI plugins priority
zinit ice wait"1" lucid from"gh-r" as"program" atclone"./install.sh" atpull"%atclone"
zinit light g-plane/pnpm-shell-completion

# zinit ice depth=1
# zinit light jeffreytse/zsh-vi-mode
