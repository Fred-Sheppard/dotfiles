#!/usr/bin/env bash
set -Eeuo pipefail

log() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*" >&2; }
fail() {
  echo -e "\033[1;31m[ERROR]\033[0m $*" >&2
  exit 1
}
command_exists() { command -v "$1" >/dev/null 2>&1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname)"

# Root (common in bare containers) needs no sudo, and it's often not
# even installed there.
SUDO=""
if [[ "$(id -u)" -ne 0 ]]; then
  SUDO="sudo"
fi

#######################################
# System packages
#######################################
case "$OS" in
Darwin)
  if ! command_exists brew; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    else
      fail "Homebrew not found. Install it first: https://brew.sh"
    fi
  fi
  log "Updating Homebrew"
  brew update
  log "Installing bootstrap packages via Homebrew"
  brew install fzf cargo-binstall
  ;;
Linux)
  # Only apt-based distros are automated. Everywhere else we just check that
  # the bootstrap packages are present and let the user install them with
  # whatever package manager they have.
  if command_exists apt-get; then
    log "Updating apt packages"
    $SUDO apt-get update
    $SUDO apt-get upgrade -y
    log "Installing bootstrap packages via apt"
    $SUDO apt-get install -y ca-certificates curl fzf gcc git make perl unzip zsh
  else
    warn "No apt-get found - skipping automatic package installation."
    warn "Update your system and install the equivalents of:"
    warn "  ca-certificates curl fzf gcc git make perl unzip zsh"
    missing=()
    for cmd in curl fzf gcc git make perl unzip zsh; do
      command_exists "$cmd" || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
      fail "Missing required commands: ${missing[*]}. Install them with your package manager, then re-run this script."
    fi
    log "All bootstrap commands present - continuing"
  fi
  ;;
*)
  fail "Unsupported OS: $OS"
  ;;
esac

#######################################
# Rust (rustup)
#######################################
if ! command_exists cargo; then
  log "Installing Rust via rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
    sh -s -- -y --no-modify-path
fi

export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"
export PATH="$CARGO_HOME/bin:$PATH"

command_exists cargo || fail "Rust installation failed"

#######################################
# cargo-binstall
#######################################
if ! command_exists cargo-binstall; then
  case "$OS" in
  Darwin)
    fail "cargo-binstall not found after Homebrew install"
    ;;
  Linux)
    log "Installing cargo-binstall"
    curl -L --proto '=https' --tlsv1.2 -sSf \
      https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh |
      bash
    ;;
  esac
fi

command_exists cargo-binstall || fail "cargo-binstall not found"

#######################################
# CLI tools
#######################################
# Skip anything already on PATH - it may well have come from brew/pacman, and
# a cargo-binstall copy would shadow or duplicate it.
binstall=()
while read -r -u 3 crate cmd || [[ -n "${crate:-}" ]]; do
  if [[ -z "$crate" || "$crate" == \#* ]]; then
    continue
  fi
  if command_exists "$cmd"; then
    log "$crate already installed ($(command -v "$cmd"))"
    continue
  fi
  binstall+=("$crate")
done 3<"$SCRIPT_DIR/tools/cargo.txt"

if [[ ${#binstall[@]} -gt 0 ]]; then
  log "Installing via cargo-binstall: ${binstall[*]}"
  cargo-binstall --no-confirm "${binstall[@]}"
else
  log "All cargo tools already installed"
fi

#######################################
# Neovim (bob)
#######################################
log "Installing Neovim (stable) via bob"
bob use stable

#######################################
# Dotfiles
#######################################
ln -sfn "$HOME/dotfiles/config/zsh/full.zsh" "$HOME/.zshrc"
mkdir -p "$HOME/.config/zellij/layouts"
mkdir -p "$HOME/.local/share/zellij"
ln -sfn "$HOME/dotfiles/config/zellij/layouts/status.kdl" \
  "$HOME/.config/zellij/layouts/default.kdl"
ln -sfn "$HOME/dotfiles/config/starship.toml" \
  "$HOME/.config/starship.toml"

#######################################
# Bat theme
#######################################
if command_exists bat; then
  BAT_CONFIG_DIR="$(bat --config-dir)"
  mkdir -p "$BAT_CONFIG_DIR/themes"
  curl -fsSL -o "$BAT_CONFIG_DIR/themes/Catppuccin Mocha.tmTheme" \
    https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
  bat cache --build
  grep -q Catppuccin "$BAT_CONFIG_DIR/config" 2>/dev/null ||
    echo '--theme="Catppuccin Mocha"' >>"$BAT_CONFIG_DIR/config"
fi

log "Pulling zellij fork"
case "$OS" in
Darwin) bash "$SCRIPT_DIR/pull-zellij-fork.sh" --macos ;;
Linux) bash "$SCRIPT_DIR/pull-zellij-fork.sh" --x86 ;;
esac

#######################################
# Zsh plugins (vendored as submodules)
#######################################
log "Fetching vendored zsh plugins"
git -C "$HOME/dotfiles" submodule update --init --recursive config/zsh/vendor

#######################################
# NVM + Node (LTS)
#######################################
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

#######################################
# GUI apps (Homebrew Cask)
#######################################
if [[ "$OS" == "Darwin" ]]; then
  log "Installing GUI apps via Homebrew Cask"
  # Errors if an app already exists at /Applications/*.app via a non-Homebrew
  # install - fix manually with `brew install --cask --force <name>` or by
  # removing the existing app, rather than scripting around it here.
  brew install --cask $(xargs <"$SCRIPT_DIR/brew_casks.txt")
fi

#######################################
# win32yank (WSL)
#######################################
if [[ "$OS" == "Linux" ]] && grep -qi microsoft /proc/version && ! command_exists win32yank.exe; then
  TMP="$(mktemp -d)"
  curl -fsSL -o "$TMP/win32yank.zip" \
    https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
  unzip -q "$TMP/win32yank.zip" -d "$TMP"
  $SUDO mv "$TMP/win32yank.exe" /usr/local/bin/
  $SUDO chmod +x /usr/local/bin/win32yank.exe
  rm -rf "$TMP"
fi

log "Setup complete 🚀 Restart your shell."
log "Next steps:"
log "Install a NerdFont"
