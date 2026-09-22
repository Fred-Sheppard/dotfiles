# Short-lived containers. Deliberately short — anything added here must
# justify itself for a shell that may live minutes. No starship, zoxide,
# nvm, zellij, docker-compose helpers, or git workflow functions: those
# belong in full.zsh for long-term devices.

ZSH_DIR="${${(%):-%x}:A:h}"

path=(~/bin $path)

source "$ZSH_DIR/common.zsh"

# ============================================
# PROMPT
# (no starship binary here - a small starship-lookalike using vcs_info,
# built into zsh. Mirrors config/starship.toml: truncated path, git
# branch/dirty state, the WIP warning, exit-status arrow, time on the
# right. Degrades gracefully with no git installed.)
# ============================================
autoload -Uz vcs_info
setopt PROMPT_SUBST

zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '✘'
zstyle ':vcs_info:git:*' stagedstr '✚'
zstyle ':vcs_info:git:*' formats ' %F{magenta} %b%u%c%f'
zstyle ':vcs_info:git:*' actionformats ' %F{magenta} %b|%a%u%c%f'

zb_precmd() {
  # Capture $? before running anything else in this hook - vcs_info/git
  # below would otherwise overwrite it before the prompt reads it.
  local exit_code=$?

  vcs_info

  zb_wip=""
  if git log -1 --pretty=%s 2>/dev/null | grep -qF -- '--wip--'; then
    zb_wip=" %F{yellow}⚠ WIP%f"
  fi

  if [[ $exit_code -eq 0 ]]; then
    zb_arrow="%F{green}❯%f"
  else
    zb_arrow="%F{red}❯%f"
  fi
}
precmd_functions+=(zb_precmd)

PROMPT='%B%F{cyan}%3~%f%b${vcs_info_msg_0_}${zb_wip}
${zb_arrow} '
RPROMPT='%F{8}[%D{%H:%M}]%f'
