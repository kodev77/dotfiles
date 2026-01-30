#!/bin/bash
# Minimal profile - core setup with basic tools
# Good for: servers, VMs, quick setups

set -e
cd "$(dirname "$0")"

echo "Installing minimal profile..."

# Core
./install.d/vim-core.sh
./install.d/bash-core.sh

# Git
./install.d/vim-fugitive.sh
./install.d/vim-gitgutter.sh
./install.d/bash-git-prompt.sh

# Basic tools
./install.d/vim-fzf.sh
./install.d/vim-ripgrep.sh
./install.d/bash-fzf.sh
./install.d/bash-bat.sh
./install.d/bash-ripgrep.sh

echo ""
echo "Minimal profile installed!"
echo "Run: vim -c ':PlugInstall' -c ':qa'"
echo "Run: source ~/.bashrc"
