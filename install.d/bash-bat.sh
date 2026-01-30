#!/bin/bash
# bash-bat - bat syntax highlighting
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing bat bash config..."
    remove_files "$DOTFILES_DIR/.bashrc.d/32-bat.sh"
    log_info "bat removed - restart shell or source ~/.bashrc"
    exit 0
fi

log_info "Setting up bat..."

if ! check_cmd bat && ! check_cmd batcat; then
    install_apt bat
else
    log_info "bat already installed"
fi

mkdir -p "$DOTFILES_DIR/.bashrc.d"
cp "$DOTFILES_DIR/src/bash/32-bat.sh" "$DOTFILES_DIR/.bashrc.d/"

log_info "bat ready - restart shell or source ~/.bashrc"
