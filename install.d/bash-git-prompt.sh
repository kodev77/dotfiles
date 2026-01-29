#!/bin/bash
# bash-git-prompt - Git branch in PS1
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing git prompt..."
    remove_files "$DOTFILES_DIR/.bashrc.d/10-git-prompt.sh"
    log_info "git prompt removed - restart shell or source ~/.bashrc"
    exit 0
fi

log_info "Setting up git prompt..."

mkdir -p "$DOTFILES_DIR/.bashrc.d"
cp "$DOTFILES_DIR/src/bash/10-git-prompt.sh" "$DOTFILES_DIR/.bashrc.d/"

log_info "git prompt ready - restart shell or source ~/.bashrc"
