#!/bin/bash
# vim-core - Base vim setup with symlinks and vim-plug
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing vim core..."

    # Remove symlinks
    for link in ~/.vimrc ~/.gitconfig ~/.tmux.conf; do
        if [ -L "$link" ]; then
            rm "$link"
            log_info "Removed symlink $link"
        fi
    done
    if [ -L ~/.vim ]; then
        rm ~/.vim
        log_info "Removed symlink ~/.vim"
    fi

    # Clean up files copied by install scripts
    rm -rf "$DOTFILES_DIR/.vim/plugins"
    rm -rf "$DOTFILES_DIR/.vim/config"
    rm -f "$DOTFILES_DIR/.vim/autoload/dadbod_format.vim"
    rm -f "$DOTFILES_DIR/.vim/plugin/db2.vim"
    log_info "Cleaned installed configs from .vim/"

    # Remove vim-plug and installed plugins
    rm -f "$DOTFILES_DIR/.vim/autoload/plug.vim"
    if [ -d "$DOTFILES_DIR/.vim/plugged" ]; then
        rm -rf "$DOTFILES_DIR/.vim/plugged"
        log_info "Removed installed plugins"
    fi

    log_info "vim core removed"
    exit 0
fi

log_info "Setting up vim core..."

# Ensure ~/.local/bin is set up
ensure_local_bin

# Create symlinks
log_info "Creating symlinks..."
rm -rf ~/.vim
ln -sf "$DOTFILES_DIR/.vim" ~/.vim
log_info "Linked ~/.vim -> $DOTFILES_DIR/.vim"

make_symlink "$DOTFILES_DIR/.vimrc" ~/.vimrc
make_symlink "$DOTFILES_DIR/.gitconfig" ~/.gitconfig
make_symlink "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf

# Ensure vim-plug is installed
if [ ! -f ~/.vim/autoload/plug.vim ]; then
    log_info "Installing vim-plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
else
    log_info "vim-plug already installed"
fi

log_info "vim core ready - run :PlugInstall in vim to install plugins"
