#!/bin/bash
# vim-fzf - Fuzzy finder
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing fzf vim config..."
    remove_files \
        "$DOTFILES_DIR/.vim/plugins/fzf.vim" \
        "$DOTFILES_DIR/.vim/config/21-fzf.vim"
    log_info "fzf removed - run :PlugClean in vim"
    exit 0
fi

log_info "Setting up fzf..."

if ! check_cmd fzf; then
    install_apt fzf
else
    log_info "fzf already installed"
fi

mkdir -p "$DOTFILES_DIR/.vim/plugins"
cp "$DOTFILES_DIR/src/vim/plugins/fzf.vim" "$DOTFILES_DIR/.vim/plugins/"

mkdir -p "$DOTFILES_DIR/.vim/config"
cp "$DOTFILES_DIR/src/vim/config/21-fzf.vim" "$DOTFILES_DIR/.vim/config/"

log_info "fzf ready - run :PlugInstall in vim"
