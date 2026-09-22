# Shared core, sourced by both full.zsh and minimal.zsh.
# Anything here must work with zero external binaries and behave
# identically on every machine. Tool-gated things belong in full.zsh.

ZSH_DIR="${${(%):-%x}:A:h}"

# ============================================
# TERMINAL COLOR
# (docker exec -t hardcodes TERM=xterm regardless of the host terminal;
# xterm's terminfo only declares 8 colors, so zsh silently drops colors
# above that range instead of erroring - e.g. autosuggestions' grey text
# renders as unstyled default text. Upgrade only known 8-color TERMs, and
# only if the 256-color terminfo entry actually exists.)
# ============================================
case "$TERM" in
xterm | screen | tmux)
  if infocmp "${TERM}-256color" >/dev/null 2>&1; then
    export TERM="${TERM}-256color"
  fi
  ;;
esac

# ============================================
# HISTORY
# ============================================
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

# ============================================
# COMPLETION
# ============================================
autoload -Uz compinit
if [[ -n ${HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# ============================================
# VI MODE + HISTORY SUBSTRING SEARCH
# (order matters: vi-mode rebinds whole keymaps on init, so it must
# load first, and our own bindkeys must be applied *after* it via its
# init hook or they get silently clobbered)
# ============================================
source "$ZSH_DIR/vendor/zsh-vi-mode/zsh-vi-mode.zsh"
source "$ZSH_DIR/vendor/zsh-history-substring-search/zsh-history-substring-search.zsh"

HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=''
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND=''
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
HISTORY_SUBSTRING_SEARCH_PREFIXED=1

zb_bindkeys() {
  bindkey -a 'k' history-substring-search-up
  bindkey -a 'j' history-substring-search-down
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey -M viins '\e.' insert-last-word
  bindkey -M vicmd H beginning-of-line
  bindkey -M vicmd L end-of-line
}
zvm_after_init_commands+=(zb_bindkeys)

# ============================================
# SUGGESTIONS + HIGHLIGHTING
# (must load last: syntax-highlighting wraps whatever ZLE widgets
# already exist at source time)
# ============================================
source "$ZSH_DIR/vendor/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$ZSH_DIR/vendor/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ============================================
# EXPORTS
# ============================================
for zb_editor in nvim vim vi; do
  command -v $zb_editor >/dev/null 2>&1 && export EDITOR=$zb_editor && break
done
unset zb_editor
export VISUAL=$EDITOR

# ============================================
# CLIPBOARD (OSC52, works over ssh/containers with no clipboard bridge)
# ============================================
scopy() {
  local data
  if [ -t 0 ]; then data="$*"; else data="$(cat)"; fi
  local b64=$(printf "%s" "$data" | base64 | tr -d '\n')
  printf "\033]52;c;%s\a" "$b64"
}
