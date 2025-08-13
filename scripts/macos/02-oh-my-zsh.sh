#!/bin/bash

set -euo pipefail

# Check if the .oh-my-zsh directory exists in the user's home directory
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "Oh My Zsh is already installed. Skipping."
else
  echo "Oh My Zsh not found. Installing now..."
  # Run the installer without sudo.
  # The empty string "" at the end prevents the "unsupported" argument error.
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" ""
fi