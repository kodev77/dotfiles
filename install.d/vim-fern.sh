#!/bin/bash
# vim-fern - File tree explorer with nerd font icons
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing fern..."
    remove_files \
        "$DOTFILES_DIR/.vim/plugins/fern.vim" \
        "$DOTFILES_DIR/.vim/config/20-fern.vim"
    log_info "fern removed - run :PlugClean in vim"
    exit 0
fi

log_info "Setting up fern..."

"$(dirname "$0")/vim-nerdfont.sh"

mkdir -p "$DOTFILES_DIR/.vim/plugins"
cp "$DOTFILES_DIR/src/vim/plugins/fern.vim" "$DOTFILES_DIR/.vim/plugins/"

mkdir -p "$DOTFILES_DIR/.vim/config"
cp "$DOTFILES_DIR/src/vim/config/20-fern.vim" "$DOTFILES_DIR/.vim/config/"

log_info "fern ready - run :PlugInstall in vim"
