#!/bin/bash
# vim-ripgrep - Fast search with ripgrep
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing ripgrep vim config..."
    log_warn "System package not removed (ripgrep)"
    log_info "ripgrep removed"
    exit 0
fi

log_info "Setting up ripgrep..."

if ! check_cmd rg; then
    install_apt ripgrep
else
    log_info "ripgrep already installed"
fi

log_info "ripgrep ready"
