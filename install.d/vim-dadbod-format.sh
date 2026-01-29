#!/bin/bash
# vim-dadbod-format - Custom SQL output formatter
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing dadbod-format..."
    remove_files \
        "$DOTFILES_DIR/.vim/autoload/dadbod_format.vim" \
        "$DOTFILES_DIR/.vim/config/41-dadbod-format.vim"
    log_info "dadbod-format removed"
    exit 0
fi

log_info "Setting up dadbod-format..."

"$(dirname "$0")/vim-dadbod.sh"

mkdir -p "$DOTFILES_DIR/.vim/autoload"
cp "$DOTFILES_DIR/src/vim/autoload/dadbod_format.vim" "$DOTFILES_DIR/.vim/autoload/"

mkdir -p "$DOTFILES_DIR/.vim/config"
cp "$DOTFILES_DIR/src/vim/config/41-dadbod-format.vim" "$DOTFILES_DIR/.vim/config/"

log_info "dadbod-format ready"
