# Dotfiles

A comprehensive dotfiles repository with automated setup scripts for Arch Linux, Ubuntu Desktop, and Ubuntu Server environments.

## Features

- 🚀 **Automated setup** for multiple Linux distributions
- 🔧 **Modern development tools** (mise, Node.js, Bun, pnpm)
- 🎨 **Shell enhancements** (Zsh with Oh My Zsh, Starship prompt)
- 📦 **Package management** via stow for modular configuration
- 🐳 **Docker** setup and configuration
- 🎯 **Development apps** (VS Code, Zed, Neovim, tmux)
- 🔍 **CLI utilities** (fzf, ripgrep, bat, eza, zoxide, fd)

## Quick Start

### Fresh Installation (Default: Ubuntu Server)

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x bootstrap.sh
./bootstrap.sh
```

This will automatically run the Ubuntu Server setup script.

### Custom Installation

```bash
# Install fonts only
./bootstrap.sh --fonts

# Setup dotfiles (stow)
./bootstrap.sh --dotfiles

# Setup Arch Linux
./bootstrap.sh --arch

# Setup Ubuntu Desktop
./bootstrap.sh --ubuntu

# Setup Ubuntu Server
./bootstrap.sh --server

# Show all options
./bootstrap.sh --help
```

## Repository Structure

```
dotfiles/
├── bootstrap.sh              # Main entry point
├── scripts/
│   ├── setup-arch.sh        # Arch Linux setup
│   ├── setup-ubuntu.sh      # Ubuntu Desktop setup
│   ├── setup-ubuntu-server.sh # Ubuntu Server setup
│   ├── stow.sh              # Dotfiles symlink manager
│   └── install-fonts.sh     # Font installation
├── .bashrc                  # Bash configuration
├── .zshrc                   # Zsh configuration
├── .tmux.conf              # Tmux configuration
└── .config/                # Application configs
    ├── nvim/
    ├── starship.toml
    └── ...
```

## What Gets Installed

### Core Tools

- **Package Managers**: pacman/apt, yay (Arch), flatpak
- **Version Managers**: mise (for Node.js, Bun, pnpm, etc.)
- **Shells**: bash, zsh with Oh My Zsh
- **Editors**: Neovim, Vim, VS Code, Zed
- **Terminal**: Ghostty (Arch), tmux
- **CLI Tools**:
  - File management: eza, tree, ncdu, fd, ripgrep
  - System monitoring: btop, htop, fastfetch
  - Development: git, lazygit, git-delta
  - Search: fzf, zoxide
  - Utilities: bat, jq, curl, wget, stow

### Development Environment

- **Runtimes**: Node.js 22, Bun, pnpm (via mise)
- **Containers**: Docker, Docker Compose
- **Database Tools**: DBeaver, MongoDB Compass, RedisInsight
- **API Testing**: Postman, Bruno
- **Version Control**: Git with delta diff viewer, Lazygit

### Desktop Apps (Ubuntu/Arch Desktop)

- Google Chrome
- Visual Studio Code
- Obsidian
- qBittorrent

### Zsh Plugins

- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-history-substring-search
- zsh-completions
- pnpm-shell-completion

## Post-Installation

After running the setup script:

1. **Logout and login** to apply group changes (especially for Docker)
2. **Restart your shell** or run:

   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

3. **Activate mise** (if not already in your shell config):

   ```bash
   eval "$(mise activate bash)"  # or zsh
   ```

## Usage Examples

### Updating Dotfiles

```bash
cd ~/dotfiles
git pull
./bootstrap.sh --dotfiles  # Re-stow configurations
```

### Adding New Configurations

1. Add your config files to the appropriate directory
2. Run stow to symlink them:

   ```bash
   ./bootstrap.sh --dotfiles
   ```

### Installing Additional Fonts

```bash
./bootstrap.sh --fonts
```

## Customization

### Environment Variables

Set these before running the bootstrap script:

```bash
export DOTFILES_DIR="$HOME/dotfiles"  # Change dotfiles location
./bootstrap.sh
```

### Modifying Package Lists

Edit the respective setup script:

- `scripts/setup-arch.sh` - For Arch Linux packages
- `scripts/setup-ubuntu.sh` - For Ubuntu Desktop packages
- `scripts/setup-ubuntu-server.sh` - For Ubuntu Server packages

Look for the `CORE_PACKAGES` and `AUR_PACKAGES` arrays.

## Troubleshooting

### mise tools not found

Activate mise in your current shell:

```bash
eval "$(mise activate bash)"
```

### Docker permission denied

Logout and login again, or run:

```bash
newgrp docker
```

### Stow conflicts

If stow reports conflicts, backup existing configs:

```bash
mkdir -p ~/.config-backup
mv ~/.bashrc ~/.config-backup/
./bootstrap.sh --dotfiles
```

### Fonts not appearing

Rebuild font cache:

```bash
fc-cache -fv
```

## Platform-Specific Notes

### Arch Linux

- Uses `yay` as AUR helper
- Includes GUI applications by default
- Installs Ghostty terminal

### Ubuntu Desktop

- Uses `nala` for better package management UI
- Includes desktop apps and fonts
- Configures GNOME settings

### Ubuntu Server

- Minimal installation without GUI apps
- Optimized for server/headless environments
- Includes Docker and development tools only

## Requirements

- Fresh installation of Arch Linux or Ubuntu (20.04+)
- Internet connection
- Sudo privileges
- Git (will be installed if not present)

## Contributing

Feel free to fork this repository and customize it for your needs. Pull requests for improvements are welcome!

## License

MIT License - Feel free to use and modify as needed.

## Credits

- [Oh My Zsh](https://ohmyz.sh/)
- [Starship](https://starship.rs/)
- [mise](https://mise.jdx.dev/)
- [TPM](https://github.com/tmux-plugins/tpm)
- All the amazing open-source tools included in this setup

---

**Note**: Always review scripts before running them with sudo privileges. These scripts modify system configurations and install software.
