if [[ -z "$ZELLIJ" ]]; then
    if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
        zellij attach -c
    else
        zellij
    fi

    if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
        exit
    fi
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="muse"

plugins=(git)
plugins+=(zsh-vi-mode)

source $ZSH/oh-my-zsh.sh

zvm_after_init_commands+=("
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey -a 'k' up-line-or-beginning-search
bindkey -a 'j' down-line-or-beginning-search
")
# zvm_after_init_commands+=("bindkey -a 'k' up-line-or-beginning-search bindkey -a 'j' down-line-or-beginning-search")
bindkey -M viins '\e.' insert-last-word



# PATH
path+="$HOME/.cargo/bin"
path+="$HOME/bin"
path+="$HOME/bin/javapath"
path+="$HOME/.anaconda3/bin"

# EXPORT
export VISUAL='/usr/bin/nvim'
export EDITOR=$VISUAL
export ZVM_VI_EDITOR=$VISUAL
export NO_AT_BRIDGE=1
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export NNN_PLUG='d:!trash put "$nnn"*;l:!~/scripts/nnn_dotfile.sh "$nnn"*'

# ALIAS
alias ls="eza --icons --group-directories-first"
alias ll="eza -alF"
alias la="eza -a"
alias li="eza"
alias intellij="/home/fred/Apps/idea-IU-232.9921.47/bin/idea.sh"
alias ij="intellij"
alias rmr="rm -r"
alias rmrf="rm -rf"
alias copy="xclip -sel clip"
alias cat="bat"
alias grep="rg"
alias find="fd"
alias zj="zellij"
alias clock="tty-clock -cBC 0"
alias layout="zellij action new-tab --layout"
alias :wq="exit"
alias :q="exit"
alias forall="awk {'print $1'} | xargs"
alias steam="/usr/bin/steam %U -vgui"
alias tree="eza --tree"
alias rr="trash put"
# Coloured help pages
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'
alias catcode="tail -n +1"

# FUNCTIONS
tldr-less() {
  if [ $# -eq 0 ]; then
    echo "Usage: tldr-less <command>"
    return 1
  fi

  tldr "$1" --color=always | less -R
}
alias tl="tldr-less"



dkrstart() {
    sudo docker ps -a | fzf | awk '{print $1}' | xargs sudo docker start
}

dkrstop() {
    sudo docker ps | fzf | awk '{print $1}' | xargs sudo docker stop
}

copycode() {
  if [ $# -eq 0 ]; then
    echo "Usage: copycode <file>"
    return 1
  fi

  (tree; tail -n +1 $@) | copy
}

runbg() {
    "$@" > /dev/null 2>& 1 & disown
}

nemo() {
    runbg /usr/bin/nemo
}

dotfile() {
  if [ $# -eq 0 ]; then
    echo "Usage: dotfile <file>"
    return 1
  fi

  # Ensure the .dotfiles directory exists
  mkdir -p ~/.dotfiles

  for file in "$@"; do
    if [ ! -e "$file" ]; then
      echo "File $file does not exist."
      continue
    fi

    # Get the absolute path of the file
    local abs_path=$(realpath "$file")
    local filename=$(basename "$file")

    # Move the file to the .dotfiles directory
    mv "$abs_path" ~/.dotfiles/

    # Create a symlink at the old location pointing to the new location
    ln -s ~/.dotfiles/"$filename" "$abs_path"

    # Echo the new file location
    echo "Moved to ~/.dotfiles/$filename"
  done
}

n ()
{
    # Block nesting of nnn in subshells
    [ "${NNNLVL:-0}" -eq 0 ] || {
        echo "nnn is already running"
        return
    }

    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
    # see. To cd on quit only on ^G, remove the "export" and make sure not to
    # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
    #      NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    # The command builtin allows one to alias nnn to n, if desired, without
    # making an infinitely recursive alias
    command nnn "$@"

    [ ! -f "$NNN_TMPFILE" ] || {
        . "$NNN_TMPFILE"
        rm -f -- "$NNN_TMPFILE" > /dev/null
    }
}

################################

eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"
eval $(thefuck --alias)
[ -f "/home/fred/.ghcup/env" ] && . "/home/fred/.ghcup/env" # ghcup-env


