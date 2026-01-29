#!/bin/bash
# vim-ko-tabbar - Custom tabline
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing ko-tabbar..."
    remove_files "$DOTFILES_DIR/.vim/config/11-tabbar.vim"
    log_info "ko-tabbar removed"
    exit 0
fi

log_info "Setting up ko-tabbar..."

mkdir -p "$DOTFILES_DIR/.vim/config"
cp "$DOTFILES_DIR/src/vim/config/11-tabbar.vim" "$DOTFILES_DIR/.vim/config/"

log_info "ko-tabbar ready"
