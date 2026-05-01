#!/usr/bin/env bash
# Install ergonomic zsh for Debian/Ubuntu containers:
#   Oh My Zsh + zsh-vi-mode, autosuggestions, syntax-highlighting, safe-paste,
#   history-substring-search (via ~/.zsh/base.zsh), zoxide, yazi, scopy, y().
#   Plugins match the full dotfiles set except git and rust (no cargo/git OMZ plugins).
#
# Usage:
#   Run as the user who will own the shell (recommended for devcontainers):
#     DOTFILES_ROOT=/workspaces/dotfiles bash scripts/container-ergonomics.sh
#
#   As root with a non-root dev user:
#     INSTALL_USER=vscode DOTFILES_ROOT=/opt/dotfiles bash scripts/container-ergonomics.sh
#
# Minimal COPY layout for DOTFILES_ROOT:
#   config/zsh/omz-header.zsh, base.zsh, zshrc.container
#   config/yazi/   (optional; SKIP_YAZI_CFG=1 to skip)
#
# Env:
#   DOTFILES_ROOT   – repo root (default: parent of scripts/ if config/zsh/base.zsh exists)
#   INSTALL_USER    – if set, install into that user's HOME (requires root + sudo)
#   SKIP_APT=1      – skip apt-get
#   SKIP_YAZI_CFG=1 – do not copy config/yazi

set -euo pipefail

log() { printf '\033[1;32m[ergonomics]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[ergonomics]\033[0m %s\n' "$*" >&2; exit 1; }

resolve_repo_root() {
  if [[ -n "${DOTFILES_ROOT:-}" ]]; then
    printf '%s' "$DOTFILES_ROOT"
    return
  fi
  local script_dir repo
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo="$(cd "$script_dir/.." && pwd)"
  if [[ -f "$repo/config/zsh/base.zsh" && -f "$repo/config/zsh/zshrc.container" ]]; then
    printf '%s' "$repo"
    return
  fi
  die "Set DOTFILES_ROOT to your dotfiles repo root (need config/zsh/*.zsh and zshrc.container)."
}

REPO_ROOT="$(resolve_repo_root)"
OMZ_HEADER_SRC="$REPO_ROOT/config/zsh/omz-header.zsh"
BASE_SRC="$REPO_ROOT/config/zsh/base.zsh"
ZSHRC_CONTAINER_SRC="$REPO_ROOT/config/zsh/zshrc.container"
[[ -f "$OMZ_HEADER_SRC" && -f "$BASE_SRC" && -f "$ZSHRC_CONTAINER_SRC" ]] ||
  die "Missing config/zsh/omz-header.zsh, base.zsh, or zshrc.container under $REPO_ROOT"

if [[ -n "${INSTALL_USER:-}" ]]; then
  [[ "$(id -u)" -eq 0 ]] || die "INSTALL_USER requires running as root"
  command -v sudo >/dev/null || die "INSTALL_USER requires sudo"
  TARGET_HOME="$(getent passwd "$INSTALL_USER" | cut -d: -f6)"
  [[ -n "$TARGET_HOME" && -d "$TARGET_HOME" ]] || die "Invalid INSTALL_USER or home: $INSTALL_USER"
  run() { sudo -u "$INSTALL_USER" -H "$@"; }
else
  TARGET_HOME="$HOME"
  run() { "$@"; }
fi

PREFIX="${PREFIX:-$TARGET_HOME/.local}"
BIN="$PREFIX/bin"

if [[ "${SKIP_APT:-}" != 1 ]]; then
  if [[ "$(id -u)" -eq 0 ]]; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y --no-install-recommends zsh curl git ca-certificates unzip sudo
  else
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends zsh curl git ca-certificates unzip
  fi
fi

if [[ ! -d "$TARGET_HOME/.oh-my-zsh" ]]; then
  log "Oh My Zsh"
  if [[ -n "${INSTALL_USER:-}" ]]; then
    sudo -u "$INSTALL_USER" -H bash -c \
      'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  else
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
fi

OMZ_PLUGINS="$TARGET_HOME/.oh-my-zsh/custom/plugins"
run mkdir -p "$OMZ_PLUGINS"

log "Oh My Zsh custom plugins"
clone_omz_plugin() {
  local name="$1" url="$2" dir="$OMZ_PLUGINS/$name"
  if [[ ! -d "$dir/.git" ]]; then
    run git clone --depth 1 "$url" "$dir"
  fi
}
clone_omz_plugin zsh-vi-mode https://github.com/jeffreytse/zsh-vi-mode.git
clone_omz_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
clone_omz_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
clone_omz_plugin zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search.git

log "~/.zsh snippets (omz-header, base)"
run mkdir -p "$TARGET_HOME/.zsh"
if [[ -n "${INSTALL_USER:-}" ]]; then
  sudo install -m 0644 -o "$INSTALL_USER" "$OMZ_HEADER_SRC" "$TARGET_HOME/.zsh/omz-header.zsh"
  sudo install -m 0644 -o "$INSTALL_USER" "$BASE_SRC" "$TARGET_HOME/.zsh/base.zsh"
else
  install -m 0644 "$OMZ_HEADER_SRC" "$TARGET_HOME/.zsh/omz-header.zsh"
  install -m 0644 "$BASE_SRC" "$TARGET_HOME/.zsh/base.zsh"
fi

arch="$(uname -m)"
case "$arch" in
  x86_64) yazi_target=x86_64-unknown-linux-gnu ;;
  aarch64|arm64) yazi_target=aarch64-unknown-linux-gnu ;;
  *) die "Unsupported uname -m: $arch (extend script for another yazi triple)" ;;
esac

run mkdir -p "$BIN"

log "Yazi ($yazi_target)"
tmpdir="$(mktemp -d)"
_zshrc_tmp=''
cleanup() { rm -rf "${tmpdir:-}"; }
trap cleanup EXIT
curl -fsSL -o "$tmpdir/yazi.zip" "https://github.com/sxyazi/yazi/releases/latest/download/yazi-${yazi_target}.zip"
unzip -oq "$tmpdir/yazi.zip" -d "$tmpdir/extract"
shopt -s nullglob
extract_dirs=("$tmpdir/extract"/*/)
shopt -u nullglob
[[ ${#extract_dirs[@]} -eq 1 && -f "${extract_dirs[0]}/yazi" ]] || die "Unexpected yazi zip layout"
if [[ -n "${INSTALL_USER:-}" ]]; then
  sudo install -m 0755 -o "$INSTALL_USER" "${extract_dirs[0]}/yazi" "$BIN/yazi"
else
  install -m 0755 "${extract_dirs[0]}/yazi" "$BIN/yazi"
fi

log "Zoxide"
_zoxide_url=https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh
if [[ -n "${INSTALL_USER:-}" ]]; then
  sudo -u "$INSTALL_USER" -H bash <<INSTALL_ZOXIDE
set -euo pipefail
curl -fsSL '$_zoxide_url' | bash -s -- --bin-dir '$BIN' --man-dir '$PREFIX/share/man'
INSTALL_ZOXIDE
else
  curl -fsSL "$_zoxide_url" | bash -s -- --bin-dir "$BIN" --man-dir "$PREFIX/share/man"
fi

if [[ "${SKIP_YAZI_CFG:-}" != 1 && -d "$REPO_ROOT/config/yazi" ]]; then
  log "Yazi config from repo"
  run mkdir -p "$TARGET_HOME/.config/yazi"
  if [[ -n "${INSTALL_USER:-}" ]]; then
    sudo cp -a "$REPO_ROOT/config/yazi/." "$TARGET_HOME/.config/yazi/"
    sudo chown -R "$INSTALL_USER" "$TARGET_HOME/.config/yazi"
  else
    cp -a "$REPO_ROOT/config/yazi/." "$TARGET_HOME/.config/yazi/"
  fi
fi

log "~/.zshrc from config/zsh/zshrc.container"
if [[ -n "${INSTALL_USER:-}" ]]; then
  sudo install -m 0644 -o "$INSTALL_USER" "$ZSHRC_CONTAINER_SRC" "$TARGET_HOME/.zshrc"
else
  install -m 0644 "$ZSHRC_CONTAINER_SRC" "$TARGET_HOME/.zshrc"
fi

log "Done. To make zsh default: chsh -s \"\$(command -v zsh)\" \"${INSTALL_USER:-$USER}\""
log "Open zsh now: zsh"
