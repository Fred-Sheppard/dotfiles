# Short-lived containers. Deliberately short — anything added here must
# justify itself for a shell that may live minutes.
ZSH_DIR="${${(%):-%x}:A:h}"

path=(~/bin $path)

source "$ZSH_DIR/common.zsh"

# ============================================
# PROMPT
# Red/green arrow, time on right
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
