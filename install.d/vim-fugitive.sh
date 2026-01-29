#!/bin/bash
# vim-fugitive - Git integration for vim
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing vim-fugitive..."
    remove_files "$DOTFILES_DIR/.vim/plugins/fugitive.vim"
    log_info "vim-fugitive removed - run :PlugClean in vim"
    exit 0
fi

log_info "Setting up vim-fugitive..."

mkdir -p "$DOTFILES_DIR/.vim/plugins"
cp "$DOTFILES_DIR/src/vim/plugins/fugitive.vim" "$DOTFILES_DIR/.vim/plugins/"

log_info "vim-fugitive ready - run :PlugInstall in vim"
