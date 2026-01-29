#!/bin/bash
# vim-csharp - C# development (dotnet, csharp-ls, azure cli)
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing vim-csharp..."
    remove_files "$DOTFILES_DIR/.vim/plugins/csharp.vim"
    log_info "vim-csharp removed - run :PlugClean in vim"
    log_warn "System packages not removed (dotnet, csharp-ls, az)"
    exit 0
fi

log_info "Setting up C# development..."

if ! check_cmd dotnet; then
    log_info "Installing .NET SDK..."

    if [ ! -f /usr/share/keyrings/microsoft-prod.gpg ]; then
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
    fi

    if [ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/$(lsb_release -rs)/prod $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/microsoft-prod.list
        sudo apt update
    fi

    sudo apt install -y dotnet-sdk-10.0 || sudo apt install -y dotnet-sdk-9.0
else
    log_info ".NET SDK already installed"
fi

if ! check_cmd csharp-ls; then
    log_info "Installing csharp-ls..."
    dotnet tool install --global csharp-ls

    add_to_file 'export PATH="$PATH:$HOME/.dotnet/tools"' ~/.bashrc
else
    log_info "csharp-ls already installed"
fi

if ! check_cmd az; then
    log_info "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
else
    log_info "Azure CLI already installed"
fi

if [ ! -d ~/.nuget/plugins/netcore/CredentialProvider.Microsoft ]; then
    log_info "Installing Azure Artifacts Credential Provider..."
    wget -qO- https://aka.ms/install-artifacts-credprovider.sh | bash
else
    log_info "Azure Artifacts Credential Provider already installed"
fi

mkdir -p "$DOTFILES_DIR/.vim/plugins"
cp "$DOTFILES_DIR/src/vim/plugins/csharp.vim" "$DOTFILES_DIR/.vim/plugins/"

log_info "C# development ready - run :PlugInstall in vim"
