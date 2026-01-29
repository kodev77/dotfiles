#!/bin/bash
# Personal profile - general use without dev tools
# Good for: personal machines, gaming rigs

set -e
cd "$(dirname "$0")"

echo "Installing personal profile..."

# Core
./install.d/vim-core.sh
./install.d/bash-core.sh

# Git
./install.d/vim-fugitive.sh
./install.d/vim-gitgutter.sh
./install.d/bash-git-prompt.sh

# UI enhancements
./install.d/vim-ko-statusbar.sh
./install.d/vim-ko-tabbar.sh
./install.d/vim-nerdfont.sh
./install.d/vim-fern.sh

# Search tools
./install.d/vim-fzf.sh
./install.d/vim-ripgrep.sh
./install.d/bash-fzf.sh
./install.d/bash-ripgrep.sh

# Shell enhancements
./install.d/bash-eza.sh
./install.d/bash-broot.sh

# Password manager
./install.d/vim-db2.sh

echo ""
echo "Personal profile installed!"
echo "Run: vim -c ':PlugInstall' -c ':qa'"
echo "Run: source ~/.bashrc"
