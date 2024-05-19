#!/bin/bash

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
dotfile $1
