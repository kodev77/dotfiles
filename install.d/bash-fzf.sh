#!/bin/bash
# bash-fzf - fzf aliases and functions
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing fzf bash config..."
    remove_files "$DOTFILES_DIR/.bashrc.d/30-fzf.sh"
    log_info "fzf removed - restart shell or source ~/.bashrc"
    log_warn "System package not removed (fzf)"
    exit 0
fi

log_info "Setting up fzf for bash..."

if ! check_cmd fzf; then
    install_apt fzf
else
    log_info "fzf already installed"
fi

mkdir -p "$DOTFILES_DIR/.bashrc.d"
cp "$DOTFILES_DIR/src/bash/30-fzf.sh" "$DOTFILES_DIR/.bashrc.d/"

log_info "fzf ready - restart shell or source ~/.bashrc"
