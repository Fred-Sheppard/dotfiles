#!/usr/bin/env bash
set -euo pipefail

# ── Helpers ────────────────────────────────────────────────────────────────────
log() { printf '\n\033[1;34m▶ %s\033[0m\n' "$*"; }
ok() { printf '\033[1;32m✔ %s\033[0m\n' "$*"; }
die() {
  printf '\033[1;31m✘ %s\033[0m\n' "$*" >&2
  exit 1
}

# ── Usage ──────────────────────────────────────────────────────────────────────
usage() {
  printf 'Usage: %s <container_id>:<location>\n' "$(basename "$0")"
  printf 'Example: %s 6ea2c05d82b1:/root\n' "$(basename "$0")"
  exit 1
}

# ── Parse argument ─────────────────────────────────────────────────────────────
[[ $# -lt 1 ]] && usage

INPUT="$1"
CONTAINER_ID="${INPUT%%:*}"
LOCATION="${INPUT#*:}"

[[ -z "$CONTAINER_ID" ]] && die "Container ID is empty"
[[ -z "$LOCATION" ]] && die "Location is empty"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSH_SRC="$REPO_ROOT/config/zsh"

[[ -f "$ZSH_SRC/common.zsh" ]] || die "Missing: $ZSH_SRC/common.zsh"
[[ -f "$ZSH_SRC/minimal.zsh" ]] || die "Missing: $ZSH_SRC/minimal.zsh"
[[ -d "$ZSH_SRC/vendor/zsh-vi-mode" ]] || die "Vendored plugins missing — run: git submodule update --init $ZSH_SRC/vendor"

# ── Verify container is running ────────────────────────────────────────────────
log "Verifying container $CONTAINER_ID is running"
docker inspect --format '{{.State.Running}}' "$CONTAINER_ID" 2>/dev/null |
  grep -q 'true' || die "Container '$CONTAINER_ID' is not running"
ok "Container is running"

# ── Install zsh ────────────────────────────────────────────────────────────────
log "Installing zsh in container"
docker exec "$CONTAINER_ID" sh -c \
  'command -v zsh >/dev/null 2>&1 || (apt-get update && apt-get install -y zsh)' ||
  die "Failed to install zsh"
ok "zsh installed"

# ── Copy config ─────────────────────────────────────────────────────────────────
log "Copying config/zsh to $CONTAINER_ID:$LOCATION/.config/zsh"
docker exec "$CONTAINER_ID" mkdir -p "$LOCATION/.config/zsh"
docker cp "$ZSH_SRC/." "$CONTAINER_ID:$LOCATION/.config/zsh" ||
  die "Failed to copy config/zsh"
ok "Copied config/zsh"

log "Linking $LOCATION/.zshrc -> minimal.zsh"
docker exec "$CONTAINER_ID" ln -sfn "$LOCATION/.config/zsh/minimal.zsh" "$LOCATION/.zshrc" ||
  die "Failed to link .zshrc"
ok "Linked .zshrc"

ok "All done — zsh configured in $CONTAINER_ID:$LOCATION. Run: docker exec -it $CONTAINER_ID zsh"
