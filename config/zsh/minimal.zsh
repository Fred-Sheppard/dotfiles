# Short-lived containers. Deliberately short — anything added here must
# justify itself for a shell that may live minutes. No starship, zoxide,
# nvm, zellij, docker-compose helpers, or git workflow functions: those
# belong in full.zsh for long-term devices.

ZSH_DIR="${${(%):-%x}:A:h}"

path=(~/bin $path)

source "$ZSH_DIR/common.zsh"

# ============================================
# PROMPT
# (no starship binary here - a small starship-lookalike, pure zsh.
# No git info: this is a throwaway container shell, not a repo you're
# tracking state in. Just truncated path, exit-status arrow, time.)
# ============================================
setopt PROMPT_SUBST

zb_precmd() {
  # Capture $? before running anything else in this hook, in case a
  # later hook changes it before the prompt reads it.
  local exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    zb_arrow="%F{green}❯%f"
  else
    zb_arrow="%F{red}❯%f"
  fi
}
precmd_functions+=(zb_precmd)

PROMPT='%B%F{cyan}%3~%f%b
${zb_arrow} '
RPROMPT='%F{8}[%D{%H:%M}]%f'
