#!/bin/bash
# bash-broot - File browser
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing broot config..."
    remove_files "$DOTFILES_DIR/.bashrc.d/21-broot.sh"
    log_info "broot removed - restart shell or source ~/.bashrc"
    log_warn "System binary not removed (~/.local/bin/broot)"
    exit 0
fi

log_info "Setting up broot..."

ensure_local_bin

if ! check_cmd broot; then
    log_info "Installing broot..."
    curl -o ~/.local/bin/broot -L https://dystroy.org/broot/download/x86_64-linux/broot
    chmod +x ~/.local/bin/broot
else
    log_info "broot already installed"
fi

if [ ! -f ~/.config/broot/launcher/bash/br ]; then
    log_info "Setting up broot shell function..."
    broot --install
else
    log_info "broot shell function already set up"
fi

if [ -f ~/.config/broot/conf.hjson ] && ! grep -q '^icon_theme:' ~/.config/broot/conf.hjson; then
    log_info "Enabling nerdfont icons in broot..."
    sed -i 's/# icon_theme: vscode/icon_theme: nerdfont/' ~/.config/broot/conf.hjson
else
    log_info "broot icons already configured"
fi

"$(dirname "$0")/vim-nerdfont.sh"

mkdir -p "$DOTFILES_DIR/.bashrc.d"
cp "$DOTFILES_DIR/src/bash/21-broot.sh" "$DOTFILES_DIR/.bashrc.d/"

log_info "broot ready - restart shell or source ~/.bashrc"
