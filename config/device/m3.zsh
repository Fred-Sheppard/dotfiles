# Device Specific zshrc options
# Device: m3

# LAZY LOAD NVM
export NVM_DIR="$HOME/.nvm"

# Add nvm binaries to PATH without loading nvm
if [ -d "$NVM_DIR/versions/node" ]; then
  # Find the default or current node version
  NODE_VERSION_DIR="$NVM_DIR/versions/node"
  if [ -f "$NVM_DIR/alias/default" ]; then
    DEFAULT_NODE=$(cat "$NVM_DIR/alias/default")
    NODE_PATH="$NODE_VERSION_DIR/$DEFAULT_NODE/bin"
  else
    # Use the latest version if no default is set
    NODE_PATH="$(find "$NODE_VERSION_DIR" -maxdepth 1 -type d | sort -V | tail -n 1)/bin"
  fi
  [ -d "$NODE_PATH" ] && path=($NODE_PATH $path)
fi

# Lazy load nvm - only initialize when nvm command is called
nvm() {
  unset -f nvm node npm npx
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
  nvm "$@"
}

# Lazy load node, npm, and npx as well
node() {
  unset -f nvm node npm npx
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
  node "$@"
}

npm() {
  unset -f nvm node npm npx
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
  npm "$@"
}

npx() {
  unset -f nvm node npm npx
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
  npx "$@"
}

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/fred/.docker/completions $fpath)

# Optimize compinit - only rebuild cache once per day
autoload -Uz compinit
if [[ -n ${HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
# End of Docker CLI completions

rellij
# Set MAXIM_PATH to point to the MSDK
export MAXIM_PATH=/Users/fred/lib

# Add Arm Embedded GCC to path (v10.3)
export ARM_GCC_ROOT=$MAXIM_PATH/Tools/GNUTools/10.3
export PATH=$ARM_GCC_ROOT/bin:$PATH

# Add xPack RISC-V GCC to path (v12.2)
export XPACK_GCC_ROOT=$MAXIM_PATH/Tools/xPack/riscv-none-elf-gcc/12.2.0-3.1
export PATH=$XPACK_GCC_ROOT/bin:$PATH

# Add OpenOCD to path
export OPENOCD_ROOT=$MAXIM_PATH/Tools/OpenOCD
export PATH=$OPENOCD_ROOT:$PATH

export MAKE_ROOT=$MAXIM_PATH/Tools/GNUTools/Make
export PATH=$MAKE_ROOT:$PATH

export PATH=/opt/homebrew/opt/ccache/libexec:$PATH
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
