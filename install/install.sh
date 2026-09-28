#!/usr/bin/env bash
set -Eeuo pipefail

log() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*" >&2; }
fail() {
  echo -e "\033[1;31m[ERROR]\033[0m $*" >&2
  exit 1
}
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Symlink $1 (in this repo) to $2. Anything already at $2 that isn't a symlink
# is moved aside rather than clobbered - app-managed configs live in these
# locations too, and a machine may have one worth keeping.
link() {
  local src="$HOME/dotfiles/$1" dest="$2"
  [[ -e "$src" ]] || fail "Missing dotfile: $src"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    local backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    warn "Backing up existing $dest -> $backup"
    mv "$dest" "$backup"
  fi
  ln -sfn "$src" "$dest"
}

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
# zshrc already puts ~/.local/share/bob/nvim-bin on $PATH, so tell bob not to
# prompt about doing it itself (the prompt blocks non-interactive installs).
link config/bob/config.json "$HOME/.config/bob/config.json"
bob use stable

#######################################
# Dotfiles
#######################################
log "Linking dotfiles"
link config/zsh/full.zsh "$HOME/.zshrc"
link config/git/.gitconfig "$HOME/.gitconfig"
link config/git/.gitignore_global "$HOME/.gitignore_global"
link config/starship.toml "$HOME/.config/starship.toml"
link config/nvim "$HOME/.config/nvim"
link config/yazi "$HOME/.config/yazi"
link config/gitui "$HOME/.config/gitui"
link config/bat "$HOME/.config/bat"
link config/alacritty "$HOME/.config/alacritty"
link config/zellij/config.kdl "$HOME/.config/zellij/config.kdl"
link config/zellij/layouts/status.kdl "$HOME/.config/zellij/layouts/default.kdl"
mkdir -p "$HOME/.local/share/zellij"
link config/.ideavimrc "$HOME/.ideavimrc"
link config/vscode/.vscodevimrc "$HOME/.vscodevimrc"
link config/vscode/settings.json \
  "$HOME/Library/Application Support/Code/User/settings.json"

#######################################
# Default shell
#######################################
# tmux and friends spawn $SHELL, which is the login shell from /etc/passwd and
# not whatever shell you happened to type. Leave it as bash - the usual
# devcontainer default - and none of the above is sourced inside them: no
# starship prompt, no aliases, no keybindings.
login_shell() {
  if command_exists getent; then
    getent passwd "$(id -un)" | cut -d: -f7
  elif [[ "$OS" == "Darwin" ]]; then
    dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}'
  else
    echo "$SHELL"
  fi
}

ZSH_PATH="$(command -v zsh)" || fail "zsh not found"
if [[ "$(login_shell)" == "$ZSH_PATH" ]]; then
  log "Login shell is already $ZSH_PATH"
else
  log "Setting $ZSH_PATH as the login shell"
  # chsh refuses a shell that isn't listed in /etc/shells.
  grep -qxF "$ZSH_PATH" /etc/shells 2>/dev/null ||
    echo "$ZSH_PATH" | $SUDO tee -a /etc/shells >/dev/null ||
    warn "Could not add $ZSH_PATH to /etc/shells"
  if $SUDO chsh -s "$ZSH_PATH" "$(id -un)"; then
    log "Login shell set - it takes effect in new sessions"
  else
    warn "Could not set the login shell. tmux will keep starting $(login_shell)."
    warn "Set it by hand with: chsh -s $ZSH_PATH"
  fi
fi

#######################################
# Bat theme
#######################################
# The theme and `--theme=` line ship in config/bat; bat only needs to be told
# to rebuild its cache so the .tmTheme is picked up.
if command_exists bat; then
  bat cache --build
fi

#######################################
# Submodules (zsh plugins, rellij)
#######################################
# A container usually sees the repo owned by a different uid than the user
# running this, and git refuses to touch it until the path is marked safe.
# Each submodule is its own repo, so they all need listing - a trailing /*
# would cover them in one go, but only on git 2.38+.
if ! git -C "$HOME/dotfiles" rev-parse --git-dir >/dev/null 2>&1; then
  log "Marking $HOME/dotfiles as a safe git directory"
  safe=("$HOME/dotfiles")
  while read -r _ path; do
    safe+=("$HOME/dotfiles/$path")
  done < <(git config -f "$HOME/dotfiles/.gitmodules" \
    --get-regexp '^submodule\..*\.path$')
  for dir in "${safe[@]}"; do
    git config --global --get-all safe.directory 2>/dev/null |
      grep -qxF "$dir" ||
      git config --global --add safe.directory "$dir"
  done
  git -C "$HOME/dotfiles" rev-parse --git-dir >/dev/null 2>&1 ||
    fail "Cannot read the git repo at $HOME/dotfiles"
fi

log "Fetching submodules"
git -C "$HOME/dotfiles" submodule update --init --recursive

#######################################
# NVM + Node (LTS)
#######################################
export NVM_DIR="$HOME/.nvm"
# nvm.sh reads unset variables all over the place, so nounset has to come off
# for the duration - `nvm use` dies on an unbound PROVIDED_VERSION otherwise.
set +u
# Only bootstrap when nvm is absent - brew and pacman both ship it, and the
# upstream installer would clobber their copy.
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  NVM_VERSION="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest |
    sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)"
  [[ -n "$NVM_VERSION" ]] || fail "Failed to fetch latest nvm release tag"
  log "Installing nvm $NVM_VERSION"
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi
source "$NVM_DIR/nvm.sh"

log "Installing Node (LTS) via nvm"
nvm install --lts
nvm use --lts
set -u

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

log "Pulling zellij fork"
bash "$SCRIPT_DIR/pull-zellij-fork.sh" ||
  warn "Continuing without the zellij fork"

#######################################
# rellij
#######################################
RELLIJ_SRC="$HOME/dotfiles/bin/rellij/rellij.sh"
if [[ -f "$RELLIJ_SRC" ]]; then
  log "Installing rellij"
  chmod +x "$RELLIJ_SRC"
  link bin/rellij/rellij.sh "$HOME/bin/rellij"
else
  warn "bin/rellij/rellij.sh is missing - is the submodule checked out?"
  warn "Fetch it with: git -C $HOME/dotfiles submodule update --init bin/rellij"
fi

log "Setup complete 🚀 Restart your shell."
log "Next steps:"
log "Install a NerdFont"
