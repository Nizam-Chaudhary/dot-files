# ==========================================================
# ZINIT HIGH-PERFORMANCE CONFIG (Corrected)
# ==========================================================

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"

# Advanced Turbo Multi-Load (SAFE ORDER)
zinit wait"0" lucid for \
    OMZL::git.zsh \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit" \
        zsh-users/zsh-completions \
    atload"zicdreplay" \
        g-plane/pnpm-shell-completion \
    atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
        zsh-users/zsh-history-substring-search \
    atload"zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting

# 3. Specialized Binary Plugins (unchanged)
zinit ice atload"zpcdreplay" atclone"./zplug.zsh" atpull"%atclone"

# zinit ice depth=1
# zinit light jeffreytse/zsh-vi-mode
