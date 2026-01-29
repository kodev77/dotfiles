#!/bin/bash
# bash-ripgrep - ripgrep aliases and functions
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing ripgrep bash config..."
    remove_files "$DOTFILES_DIR/.bashrc.d/31-ripgrep.sh"
    log_info "ripgrep removed - restart shell or source ~/.bashrc"
    log_warn "System package not removed (ripgrep)"
    exit 0
fi

log_info "Setting up ripgrep for bash..."

if ! check_cmd rg; then
    install_apt ripgrep
else
    log_info "ripgrep already installed"
fi

mkdir -p "$DOTFILES_DIR/.bashrc.d"
cp "$DOTFILES_DIR/src/bash/31-ripgrep.sh" "$DOTFILES_DIR/.bashrc.d/"

log_info "ripgrep ready - restart shell or source ~/.bashrc"
