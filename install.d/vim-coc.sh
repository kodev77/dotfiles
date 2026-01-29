#!/bin/bash
# vim-coc - Completion engine (coc.nvim)
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing coc.nvim..."
    remove_files \
        "$DOTFILES_DIR/.vim/plugins/coc.vim" \
        "$DOTFILES_DIR/.vim/config/30-coc.vim"
    log_info "coc.nvim removed - run :PlugClean in vim"
    log_warn "System packages not removed (nodejs, pipx, sqlfluff)"
    exit 0
fi

log_info "Setting up coc.nvim..."

if ! check_cmd node; then
    log_info "Installing nodejs..."
    install_apt nodejs
    install_apt npm
else
    log_info "nodejs already installed"
fi

if ! check_cmd pipx; then
    log_info "Installing pipx..."
    install_apt pipx
    pipx ensurepath
else
    log_info "pipx already installed"
fi

if ! check_cmd sqlfluff; then
    log_info "Installing sqlfluff..."
    pipx install sqlfluff
else
    log_info "sqlfluff already installed"
fi

mkdir -p "$DOTFILES_DIR/.vim/plugins"
cp "$DOTFILES_DIR/src/vim/plugins/coc.vim" "$DOTFILES_DIR/.vim/plugins/"

mkdir -p "$DOTFILES_DIR/.vim/config"
cp "$DOTFILES_DIR/src/vim/config/30-coc.vim" "$DOTFILES_DIR/.vim/config/"

log_info "coc.nvim ready - run :PlugInstall in vim"
