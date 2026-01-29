#!/bin/bash
# vim-gitgutter - Git diff signs in gutter
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing vim-gitgutter..."
    remove_files "$DOTFILES_DIR/.vim/plugins/gitgutter.vim"
    log_info "vim-gitgutter removed - run :PlugClean in vim"
    exit 0
fi

log_info "Setting up vim-gitgutter..."

mkdir -p "$DOTFILES_DIR/.vim/plugins"
cp "$DOTFILES_DIR/src/vim/plugins/gitgutter.vim" "$DOTFILES_DIR/.vim/plugins/"

log_info "vim-gitgutter ready - run :PlugInstall in vim"
