# ===============================
# TMUX / TERMINAL
# ===============================

# Better color handling in tmux
if [[ -n "$TMUX" ]]; then
  export TERM="xterm-256color"
fi

# Window title (kitty-friendly)
PROMPT_COMMAND='printf "\033]0;%s\007" "${PWD##*/}"; '"$PROMPT_COMMAND"
