#!/bin/bash
# vim-nerdfont - JetBrains Mono Nerd Font + nerdfont.vim plugin
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing vim-nerdfont..."
    remove_files "$DOTFILES_DIR/.vim/plugins/nerdfont.vim"
    log_info "vim-nerdfont removed - run :PlugClean in vim"
    log_warn "System font not removed (JetBrains Mono Nerd)"
    exit 0
fi

log_info "Setting up nerd fonts..."

if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
    log_info "Installing JetBrains Mono Nerd Font..."
    mkdir -p ~/.local/share/fonts

    if [ "$(stat -c '%U' ~/.local/share/fonts)" = "root" ]; then
        sudo chown -R "$USER:$USER" ~/.local/share/fonts
    fi

    curl -fLo /tmp/JetBrainsMono.tar.xz -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
    mkdir -p /tmp/jetbrains-nerd-font
    tar -xf /tmp/JetBrainsMono.tar.xz -C /tmp/jetbrains-nerd-font
    mv /tmp/jetbrains-nerd-font/*.ttf ~/.local/share/fonts/
    rm -rf /tmp/JetBrainsMono.tar.xz /tmp/jetbrains-nerd-font
    fc-cache -fv
else
    log_info "JetBrains Mono Nerd Font already installed"
fi

mkdir -p "$DOTFILES_DIR/.vim/plugins"
cp "$DOTFILES_DIR/src/vim/plugins/nerdfont.vim" "$DOTFILES_DIR/.vim/plugins/"

log_info "nerd fonts ready - run :PlugInstall in vim"
