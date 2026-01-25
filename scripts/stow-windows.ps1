# ==============================
# Manual Dotfiles Symlink Script
# PowerShell only
# ==============================

$ErrorActionPreference = "Stop"

$DOTFILES = "$HOME\dotfiles"

function Link-File {
  param (
    [Parameter(Mandatory)]
    [string]$Source,

    [Parameter(Mandatory)]
    [string]$Target
  )

  if (!(Test-Path $Source)) {
    Write-Warning "Source not found: $Source"
    return
  }

  # Ensure parent directory exists
  $parent = Split-Path $Target -Parent
  if ($parent -and !(Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  # Remove existing file or symlink
  if (Test-Path $Target) {
    Write-Host "Removing existing: $Target"
    Remove-Item $Target -Force
  }

  Write-Host "Linking $Target → $Source"
  New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
}

# ==============================
# Git
# ==============================
Link-File `
  -Source "$DOTFILES\git\.config/git/config" `
  -Target "$HOME\.gitconfig"

# # ==============================
# # Neovim
# # ==============================
# Link-File `
#   -Source "$DOTFILES\nvim\.config\nvim" `
#   -Target "$HOME\AppData\Local\nvim"

# # ==============================
# # Alacritty
# # ==============================
# Link-File `
#   -Source "$DOTFILES\alacritty\alacritty.toml" `
#   -Target "$HOME\AppData\Roaming\alacritty\alacritty.toml"

# Write-Host "`n✔ Dotfiles linked successfully"
