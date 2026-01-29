#!/bin/bash
# vim-dadbod - Database tools
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing vim-dadbod..."
    remove_files \
        "$DOTFILES_DIR/.vim/plugins/dadbod.vim" \
        "$DOTFILES_DIR/.vim/config/40-dadbod.vim"
    log_info "vim-dadbod removed - run :PlugClean in vim"
    log_warn "System packages not removed (mssql-tools, mysql-client)"
    exit 0
fi

log_info "Setting up vim-dadbod..."

if ! check_cmd sqlcmd; then
    log_info "Installing mssql-tools (sqlcmd)..."

    if [ ! -f /usr/share/keyrings/microsoft-prod.gpg ]; then
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
    fi

    if [ ! -f /etc/apt/sources.list.d/mssql-release.list ]; then
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/$(lsb_release -rs)/prod $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mssql-release.list
        sudo apt update
    fi

    ACCEPT_EULA=Y sudo apt install -y mssql-tools18 unixodbc-dev

    add_to_file 'export PATH="$PATH:/opt/mssql-tools18/bin"' ~/.bashrc
else
    log_info "mssql-tools already installed"
fi

if ! check_cmd mysql; then
    install_apt mysql-client
else
    log_info "mysql-client already installed"
fi

mkdir -p "$DOTFILES_DIR/.vim/plugins"
cp "$DOTFILES_DIR/src/vim/plugins/dadbod.vim" "$DOTFILES_DIR/.vim/plugins/"

mkdir -p "$DOTFILES_DIR/.vim/config"
cp "$DOTFILES_DIR/src/vim/config/40-dadbod.vim" "$DOTFILES_DIR/.vim/config/"

log_info "vim-dadbod ready - run :PlugInstall in vim"
