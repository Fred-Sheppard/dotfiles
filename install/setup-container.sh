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

# ── Validate source files exist ────────────────────────────────────────────────
SETUP_SCRIPT="./install/setup-zsh.sh"
CONTAINER_ZSH="./config/zsh/device/container.zsh"
BASE_ZSH="./config/zsh/base.zsh"

[[ -f "$SETUP_SCRIPT" ]] || die "Missing: $SETUP_SCRIPT"
[[ -f "$CONTAINER_ZSH" ]] || die "Missing: $CONTAINER_ZSH"
[[ -f "$BASE_ZSH" ]] || die "Missing: $BASE_ZSH"

# ── Verify container is running ────────────────────────────────────────────────
log "Verifying container $CONTAINER_ID is running"
docker inspect --format '{{.State.Running}}' "$CONTAINER_ID" 2>/dev/null |
  grep -q 'true' || die "Container '$CONTAINER_ID' is not running"
ok "Container is running"

# ── Copy and run setup script ──────────────────────────────────────────────────
log "Copying setup-zsh.sh to $CONTAINER_ID:$LOCATION"
docker cp "$SETUP_SCRIPT" "$CONTAINER_ID:$LOCATION/setup-zsh.sh" ||
  die "Failed to copy setup-zsh.sh"
ok "Copied setup-zsh.sh"

log "Running setup-zsh.sh inside container"
docker exec "$CONTAINER_ID" bash "$LOCATION/setup-zsh.sh" ||
  die "setup-zsh.sh failed"
ok "setup-zsh.sh completed"

# ── Copy config files ──────────────────────────────────────────────────────────
log "Copying container.sh to $CONTAINER_ID:$LOCATION/.zshrc"
docker cp "$CONTAINER_ZSH" "$CONTAINER_ID:$LOCATION/.zshrc" ||
  die "Failed to copy container.sh as .zshrc"
ok "Copied .zshrc"

log "Copying base.sh to $CONTAINER_ID:$LOCATION/base.sh"
docker cp "$BASE_ZSH" "$CONTAINER_ID:$LOCATION/base.sh" ||
  die "Failed to copy base.sh"
ok "Copied base.sh"

ok "All done — zsh configured in $CONTAINER_ID:$LOCATION"
