#!/bin/bash
# vim-db2 - Custom password manager
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing db2 password manager..."
    remove_files "$DOTFILES_DIR/.vim/plugin/db2.vim"
    log_info "db2 removed"
    exit 0
fi

log_info "Setting up db2 password manager..."

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    if ! check_cmd wl-copy; then
        install_apt wl-clipboard
    else
        log_info "wl-clipboard already installed"
    fi
else
    if ! check_cmd xclip; then
        install_apt xclip
    else
        log_info "xclip already installed"
    fi
fi

mkdir -p "$DOTFILES_DIR/.vim/plugin"
cp "$DOTFILES_DIR/src/vim/plugin/db2.vim" "$DOTFILES_DIR/.vim/plugin/"

log_info "db2 ready - use :Db2 or <leader>d2 to open"
