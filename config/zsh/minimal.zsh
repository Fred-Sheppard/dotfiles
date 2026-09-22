# Short-lived containers. Deliberately short — anything added here must
# justify itself for a shell that may live minutes. No starship, zoxide,
# nvm, zellij, docker-compose helpers, or git workflow functions: those
# belong in full.zsh for long-term devices.

ZSH_DIR="${${(%):-%x}:A:h}"

path=(~/bin $path)

source "$ZSH_DIR/common.zsh"

export PS1='%~ %# '
