#!/bin/bash
# vim-vimspector - Debugging support
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing vimspector..."
    remove_files \
        "$DOTFILES_DIR/.vim/plugins/vimspector.vim" \
        "$DOTFILES_DIR/.vim/config/50-vimspector.vim"
    log_info "vimspector removed - run :PlugClean in vim"
    exit 0
fi

log_info "Setting up vimspector..."

"$(dirname "$0")/vim-csharp.sh"

mkdir -p "$DOTFILES_DIR/.vim/plugins"
cp "$DOTFILES_DIR/src/vim/plugins/vimspector.vim" "$DOTFILES_DIR/.vim/plugins/"

mkdir -p "$DOTFILES_DIR/.vim/config"
cp "$DOTFILES_DIR/src/vim/config/50-vimspector.vim" "$DOTFILES_DIR/.vim/config/"

log_info "vimspector ready - run :PlugInstall in vim"
log_info "NOTE: Run :VimspectorInstall netcoredbg in vim for .NET debugging"
