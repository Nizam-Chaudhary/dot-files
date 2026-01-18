# ~/.config/tmux/tmux.conf

## Install

Once everything has been installed it's time to run TPM, install first:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### Keybinding Changes (Cheatsheet)

Your `tmux.reset.conf` significantly alters the default tmux experience to be more "modern" and Vim-like. Here is the breakdown of the major changes:

| Action                     | Default Tmux               | **Your New Config**             |
| -------------------------- | -------------------------- | ------------------------------- |
| **Prefix Key**             | `Ctrl + b`                 | `Ctrl + a`                      |
| **Split Vertical**         | `Prefix + %`               | `Prefix + v` (Path aware)       |
| **Split Horizontal**       | `Prefix + "`               | `Prefix + s` (Path aware)       |
| **Pane Navigation**        | `Prefix + Arrow Keys`      | `Prefix + h/j/k/l` (Vim style)  |
| **Window Nav (Next/Prev)** | `Prefix + n / p`           | `Prefix + L / H` (Shift+L/H)    |
| **Kill Pane**              | `Prefix + x` (with prompt) | `Prefix + c` (Instant)          |
| **Kill Window**            | No default shortcut        | `Prefix + X` (from Nix config)  |
| **Resize Panes**           | `Prefix + Ctrl+Arrows`     | `Prefix + , . - =` (Repeatedly) |
| **Clear Screen**           | `Ctrl + l`                 | `Prefix + K`                    |
| **Reload Config**          | Manual command             | `Prefix + R`                    |
| **Floating Terminal**      | N/A                        | `Prefix + p` (via Floax)        |
| **Session Switcher**       | `Prefix + s`               | `Prefix + o` (via Sessionx)     |

Based on the `tmux.reset.conf` you provided, here are the specific keybindings for session and window management.

Note that because you set `set -g prefix C-a`, all of these are triggered by pressing **Ctrl+a** first.

### 1. Window Management

| Action              | Keybinding      | Notes                                |
| ------------------- | --------------- | ------------------------------------ |
| **New Window**      | `Prefix` + `^C` | `Ctrl+a` then `Ctrl+c`               |
| **Rename Window**   | `Prefix` + `r`  | Opens a prompt at the bottom         |
| **Next Window**     | `Prefix` + `L`  | `Shift + l`                          |
| **Previous Window** | `Prefix` + `H`  | `Shift + h`                          |
| **List Windows**    | `Prefix` + `w`  | Or `Prefix` + `^W`                   |
| **Last Window**     | `Prefix` + `^A` | Toggles between current and previous |

### 2. Session Management

| Action                   | Keybinding      | Notes                                |
| ------------------------ | --------------- | ------------------------------------ |
| **Rename Session**       | `Prefix` + `$`  | (Standard tmux default—still active) |
| **Switch Session**       | `Prefix` + `S`  | Standard list view                   |
| **Fuzzy Session Search** | `Prefix` + `o`  | **SessionX** (Modern fuzzy finder)   |
| **Detach Session**       | `Prefix` + `^D` | Drops you back to the terminal       |

---

### How to use the Modern Session Switcher (`SessionX`)

Since you have `omerxx/tmux-sessionx` installed in your `plugins.conf`, you should use it instead of the default `Prefix + S`:

1. Press **`Prefix` + `o**`.
2. A fuzzy-find window will appear.
3. Type the name of the project or session.
4. Press **`Enter`** to switch, or **`Ctrl + x`** to kill a session from the list.
