# ===============================
# TMUX / KITTY AWARENESS
# ===============================

# Faster redraws in tmux
if [[ -n "$TMUX" ]]; then
  export TERM="xterm-256color"
fi

# Avoid duplicate ssh-agent startups
setopt NO_HUP

# Cleaner titles (kitty uses cwd + command already)
precmd() {
  print -Pn "\e]0;%~\a"
}
