#!/bin/bash
# vim-ko-statusbar - Custom statusline (uses fugitive for git branch)
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing ko-statusbar..."
    remove_files "$DOTFILES_DIR/.vim/config/10-statusbar.vim"
    log_info "ko-statusbar removed"
    exit 0
fi

log_info "Setting up ko-statusbar..."

# Install dependency: fugitive (for git branch display)
"$(dirname "$0")/vim-fugitive.sh"

mkdir -p "$DOTFILES_DIR/.vim/config"
cp "$DOTFILES_DIR/src/vim/config/10-statusbar.vim" "$DOTFILES_DIR/.vim/config/"

log_info "ko-statusbar ready"
