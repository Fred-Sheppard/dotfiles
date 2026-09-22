# dotfiles

A collection of my machine's configuration files.

Zsh has two configs (`config/zsh/full.zsh` and `config/zsh/minimal.zsh`),
sharing `config/zsh/common.zsh` for plugins/keybindings so both behave
identically. See `config/zsh/common.zsh` for details.

## Long-term devices (macOS, WSL, Linux, devcontainers)

Prerequisites: win32yank must be on your PATH (WSL only, installed by the script below).

```bash
git submodule update --init --recursive
cd install
bash install.sh
```

This links `~/.zshrc` to `config/zsh/full.zsh`.

## Short-lived containers

From the host, against a running container:

```bash
bash install/setup-container.sh <container_id>:<path-in-container>
```

This installs zsh and links `.zshrc` to `config/zsh/minimal.zsh` inside the container.
