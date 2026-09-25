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
  printf 'Usage: %s <container_id>[:<location>]\n' "$(basename "$0")"
  printf 'Example: %s 6ea2c05d82b1\n' "$(basename "$0")"
  printf 'Example: %s 6ea2c05d82b1:/root\n' "$(basename "$0")"
  printf '\nLocation defaults to the home directory of the container'"'"'s default user.\n'
  exit 1
}

# ── Parse argument ─────────────────────────────────────────────────────────────
[[ $# -lt 1 ]] && usage

INPUT="$1"
CONTAINER_ID="${INPUT%%:*}"
if [[ "$INPUT" == *:* ]]; then
  LOCATION="${INPUT#*:}"
  [[ -z "$LOCATION" ]] && die "Location is empty"
else
  LOCATION=""
fi

[[ -z "$CONTAINER_ID" ]] && die "Container ID is empty"

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

# ── Resolve the container's default user and home ──────────────────────────────
# docker exec runs as the image's configured user (often non-root), so both the
# target directory and the file ownership have to follow that user, not root.
CONTAINER_UID="$(docker exec "$CONTAINER_ID" id -u)" || die "Failed to query container user"
CONTAINER_GID="$(docker exec "$CONTAINER_ID" id -g)" || die "Failed to query container group"
CONTAINER_USER="$(docker exec "$CONTAINER_ID" id -un)" || die "Failed to query container user"

if [[ -z "$LOCATION" ]]; then
  LOCATION="$(docker exec "$CONTAINER_ID" sh -c 'getent passwd "$(id -u)" | cut -d: -f6')"
  [[ -z "$LOCATION" ]] && die "Could not determine home directory for user '$CONTAINER_USER'"
  log "Using home directory of '$CONTAINER_USER': $LOCATION"
fi
LOCATION="${LOCATION%/}"

# ── Install zsh (as root) ──────────────────────────────────────────────────────
log "Installing zsh in container"
docker exec -u 0 "$CONTAINER_ID" sh -c \
  'command -v zsh >/dev/null 2>&1 || (apt-get update && apt-get install -y zsh)' ||
  die "Failed to install zsh"
ok "zsh installed"

# ── Copy config ─────────────────────────────────────────────────────────────────
log "Copying config/zsh to $CONTAINER_ID:$LOCATION/.config/zsh"
docker exec -u 0 "$CONTAINER_ID" mkdir -p "$LOCATION/.config/zsh" ||
  die "Failed to create $LOCATION/.config/zsh"
docker cp "$ZSH_SRC/." "$CONTAINER_ID:$LOCATION/.config/zsh" ||
  die "Failed to copy config/zsh"
# docker cp lands files owned by root; hand them back to the container user.
docker exec -u 0 "$CONTAINER_ID" chown -R "$CONTAINER_UID:$CONTAINER_GID" "$LOCATION/.config" ||
  die "Failed to chown $LOCATION/.config"
ok "Copied config/zsh"

log "Linking $LOCATION/.zshrc -> minimal.zsh"
docker exec -u 0 "$CONTAINER_ID" ln -sfn "$LOCATION/.config/zsh/minimal.zsh" "$LOCATION/.zshrc" ||
  die "Failed to link .zshrc"
docker exec -u 0 "$CONTAINER_ID" chown -h "$CONTAINER_UID:$CONTAINER_GID" "$LOCATION/.zshrc" ||
  die "Failed to chown $LOCATION/.zshrc"
ok "Linked .zshrc"

# ── Make zsh the default shell ─────────────────────────────────────────────────
log "Setting zsh as default shell for '$CONTAINER_USER'"
ZSH_PATH="$(docker exec "$CONTAINER_ID" sh -c 'command -v zsh')" ||
  die "Could not locate zsh in container"
docker exec -u 0 "$CONTAINER_ID" sh -c \
  'grep -qxF "$1" /etc/shells 2>/dev/null || echo "$1" >>/etc/shells' _ "$ZSH_PATH" ||
  die "Failed to register $ZSH_PATH in /etc/shells"
docker exec -u 0 "$CONTAINER_ID" chsh -s "$ZSH_PATH" "$CONTAINER_USER" ||
  die "Failed to set $ZSH_PATH as default shell for '$CONTAINER_USER'"
ok "Default shell is now $ZSH_PATH"

ok "All done — zsh configured in $CONTAINER_ID:$LOCATION. Run: docker exec -it $CONTAINER_ID zsh"
