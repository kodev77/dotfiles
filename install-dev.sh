#!/bin/bash
# Dev profile - full development setup
# Good for: development machines

set -e
cd "$(dirname "$0")"

echo "Installing dev profile..."

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

# Completion/LSP
./install.d/vim-coc.sh

# Database tools
./install.d/vim-dadbod.sh
./install.d/vim-dadbod-format.sh

# C# development
./install.d/vim-csharp.sh
./install.d/vim-vimspector.sh

# Password manager
./install.d/vim-db2.sh

echo ""
echo "Dev profile installed!"
echo "Run: vim -c ':PlugInstall' -c ':qa'"
echo "Run: vim -c ':VimspectorInstall netcoredbg' -c ':qa'  (for .NET debugging)"
echo "Run: source ~/.bashrc"
