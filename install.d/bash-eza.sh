#!/bin/bash
# bash-eza - Modern ls replacement
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing eza config..."
    remove_files "$DOTFILES_DIR/.bashrc.d/20-eza.sh"
    log_info "eza removed - restart shell or source ~/.bashrc"
    log_warn "System package not removed (eza)"
    exit 0
fi

log_info "Setting up eza..."

if ! check_cmd eza; then
    log_info "Installing eza..."
    install_apt gpg
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
else
    log_info "eza already installed"
fi

mkdir -p "$DOTFILES_DIR/.bashrc.d"
cp "$DOTFILES_DIR/src/bash/20-eza.sh" "$DOTFILES_DIR/.bashrc.d/"

log_info "eza ready - restart shell or source ~/.bashrc"
