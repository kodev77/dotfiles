#!/usr/bin/env bash
# ~/.vim/config/install.sh
# Minimal setup script to ensure required tools for Vim plugins (like coc.nvim, vim-dadbod, etc.)

set -e

echo "🚀 Vim environment setup starting..."

# -----------------------------------------------------------------------------
# Basic environment info
# -----------------------------------------------------------------------------
echo "🖥️  Running on native Linux environment (Ubuntu detected)."

# -----------------------------------------------------------------------------
# Full-featured Vim installation (vim-gtk3)
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for full Vim installation (vim-gtk3)..."

has_clipboard_support() {
  vim --version 2>/dev/null | grep -q "+clipboard"
}

if has_clipboard_support; then
  echo "✅ Full Vim with clipboard support already installed."
else
  echo "⚙️  Installing full-featured Vim (vim-gtk3)..."

  echo "🧹 Removing minimal Vim packages (vim-tiny, vim-nox)..."
  sudo apt-get remove -y vim-tiny vim-nox >/dev/null 2>&1 || true

  echo "📦 Installing vim-gtk3..."
  sudo apt-get update -qq
  sudo apt-get install -y vim-gtk3 >/dev/null

  echo "🔄 Setting vim-gtk3 as default system vim..."
  if update-alternatives --list vim >/dev/null 2>&1; then
    sudo update-alternatives --set vim /usr/bin/vim.gtk3 2>/dev/null || true
  fi

  echo "✅ Vim upgraded successfully!"
  vim --version | head -n 1
  vim --version | grep clipboard
fi

# -----------------------------------------------------------------------------
# vim-plug setup (plugin manager)
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for vim-plug (Vim plugin manager)..."

if [ ! -f ~/.vim/autoload/plug.vim ]; then
  echo "📦 Installing vim-plug..."
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim >/dev/null 2>&1

  if [ -f ~/.vim/autoload/plug.vim ]; then
    echo "✅ vim-plug installed successfully!"
  else
    echo "❌ Failed to install vim-plug. Please check your internet connection."
  fi
else
  echo "✅ vim-plug already installed at ~/.vim/autoload/plug.vim"
fi

# -----------------------------------------------------------------------------
# fzf setup (for fuzzy file finding)
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for fzf..."

if command -v fzf >/dev/null 2>&1; then
  echo "✅ fzf already installed: $(fzf --version)"
else
  echo "📦 Installing fzf (fuzzy finder)..."
  sudo apt-get update -qq
  sudo apt-get install -y fzf >/dev/null
  echo "🎉 fzf installed successfully: $(fzf --version)"
fi

# -----------------------------------------------------------------------------
# ripgrep setup (for fast file content searching)
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for ripgrep..."

if command -v rg >/dev/null 2>&1; then
  echo "✅ ripgrep already installed: $(rg --version | head -n 1)"
else
  echo "📦 Installing ripgrep (fast search tool)..."
  sudo apt-get update -qq
  sudo apt-get install -y ripgrep >/dev/null
  echo "🎉 ripgrep installed successfully: $(rg --version | head -n 1)"
fi

# -----------------------------------------------------------------------------
# nnn file manager setup (for nnn.vim integration)
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for nnn file manager..."

if command -v nnn >/dev/null 2>&1; then
  echo "✅ nnn already installed: $(nnn -V 2>&1 | head -n 1)"
else
  echo "📦 Installing nnn (file manager)..."
  sudo apt-get update -qq
  sudo apt-get install -y nnn >/dev/null
  echo "🎉 nnn installed successfully: $(nnn -V 2>&1 | head -n 1)"
fi

# -----------------------------------------------------------------------------
# fd-find setup (optional, for better nnn plugin performance)
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for fd (fd-find)..."

if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then
  echo "✅ fd already installed"
else
  echo "📦 Installing fd-find (fast file finder)..."
  sudo apt-get update -qq
  sudo apt-get install -y fd-find >/dev/null

  # Create symlink if fd is installed as fdfind (Ubuntu naming)
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    mkdir -p ~/.local/bin
    ln -sf $(which fdfind) ~/.local/bin/fd
    echo "   🔗 Created symlink: fd -> fdfind"
  fi

  echo "✅ fd-find installed successfully"
fi

# -----------------------------------------------------------------------------
# code-minimap setup (for minimap.vim plugin)
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for code-minimap..."

if command -v code-minimap >/dev/null 2>&1; then
  echo "✅ code-minimap already installed: $(code-minimap --version 2>/dev/null | head -n 1)"
else
  echo "📦 Installing code-minimap (minimap binary for vim)..."

  # Create ~/.local/bin if it doesn't exist
  mkdir -p ~/.local/bin

  # Download and install pre-built binary
  MINIMAP_VERSION="v0.6.4"
  MINIMAP_URL="https://github.com/wfxr/code-minimap/releases/download/${MINIMAP_VERSION}/code-minimap-${MINIMAP_VERSION}-x86_64-unknown-linux-musl.tar.gz"

  cd /tmp
  curl -sL "$MINIMAP_URL" -o code-minimap.tar.gz
  tar -xzf code-minimap.tar.gz --strip-components=1
  mv code-minimap ~/.local/bin/
  rm code-minimap.tar.gz

  # Ensure ~/.local/bin is in PATH
  if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc 2>/dev/null; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
      echo "   📁 Added ~/.local/bin to PATH in ~/.bashrc"
    fi
    export PATH="$HOME/.local/bin:$PATH"
  fi

  echo "✅ code-minimap installed successfully: $(code-minimap --version 2>/dev/null | head -n 1)"
fi

# -----------------------------------------------------------------------------
# nnn plugins setup
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for nnn plugins..."

if [ -d ~/.config/nnn/plugins ] && [ "$(ls -A ~/.config/nnn/plugins 2>/dev/null)" ]; then
  echo "✅ nnn plugins already installed at ~/.config/nnn/plugins/"
else
  echo "📦 Setting up nnn plugins..."
  mkdir -p ~/.config/nnn/plugins

  # Download official nnn plugins
  curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh >/dev/null 2>&1
  echo "🎉 nnn plugins installed to ~/.config/nnn/plugins/"
fi

# -----------------------------------------------------------------------------
# nnn .bashrc configuration
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking nnn configuration in ~/.bashrc..."

add_nnn_config() {
  if ! grep -q "NNN_PLUG=" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# nnn file manager configuration" >> ~/.bashrc
    echo "export NNN_PLUG='f:finder;d:fzcd;o:fzopen'" >> ~/.bashrc
    echo "export NNN_OPENER='vim'" >> ~/.bashrc
    echo "   📁 Added nnn configuration to ~/.bashrc"
  else
    echo "   ✅ nnn configuration already in ~/.bashrc"
  fi
}

add_nnn_config

# -----------------------------------------------------------------------------
# vim cd-on-exit wrapper function
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking vim cd-on-exit wrapper in ~/.bashrc..."

add_vim_cd_wrapper() {
  if ! grep -q "# vim cd-on-exit wrapper" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# vim cd-on-exit wrapper" >> ~/.bashrc
    echo "vim() {" >> ~/.bashrc
    echo "    /usr/bin/vim \"\$@\"" >> ~/.bashrc
    echo "    if [ -f ~/.config/vim/.lastd ]; then" >> ~/.bashrc
    echo "        source ~/.config/vim/.lastd" >> ~/.bashrc
    echo "        rm -f ~/.config/vim/.lastd" >> ~/.bashrc
    echo "    fi" >> ~/.bashrc
    echo "}" >> ~/.bashrc
    echo "   📁 Added vim cd-on-exit wrapper to ~/.bashrc"
  else
    echo "   ✅ vim cd-on-exit wrapper already in ~/.bashrc"
  fi
}

add_vim_cd_wrapper

# -----------------------------------------------------------------------------
# Microsoft Repository Setup (shared for .NET SDK and SQL tools)
# -----------------------------------------------------------------------------
setup_microsoft_repo() {
  if [ ! -f /usr/share/keyrings/microsoft.gpg ]; then
    echo ""
    echo "➕ Setting up Microsoft package repository..."

    # Download and install Microsoft GPG key
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | \
      gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null

    # Add Microsoft repository for Ubuntu version
    UBUNTU_VERSION=$(lsb_release -rs)
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/${UBUNTU_VERSION}/prod noble main" | \
      sudo tee /etc/apt/sources.list.d/microsoft.list > /dev/null

    sudo apt-get update -qq
    echo "✅ Microsoft repository configured"
  fi
}

# -----------------------------------------------------------------------------
# Node.js setup (for coc.nvim and other dev tools)
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for Node.js..."

if command -v node >/dev/null 2>&1; then
  echo "✅ Node.js detected: $(node -v)"
else
  echo "📦 Installing Node.js LTS..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - >/dev/null
  sudo apt-get install -y nodejs >/dev/null
  echo "✅ Node.js installed: $(node -v)"
fi

# -----------------------------------------------------------------------------
# .NET SDK setup (for OmniSharp and C# development)
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for .NET SDK..."

if command -v dotnet >/dev/null 2>&1; then
  echo "✅ .NET SDK detected: $(dotnet --version)"
else
  echo "📦 Installing .NET 8.0 SDK..."

  # Ensure Microsoft repository is configured
  setup_microsoft_repo

  # Install .NET 8.0 SDK
  sudo apt-get install -y dotnet-sdk-8.0 >/dev/null

  echo "✅ .NET SDK installed: $(dotnet --version)"
fi

# -----------------------------------------------------------------------------
# sqlcmd setup (for vim-dadbod and SQL work)
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for sqlcmd..."

add_sqlcmd_path() {
  if ! echo "$PATH" | grep -q "/opt/mssql-tools18/bin"; then
    export PATH="$PATH:/opt/mssql-tools18/bin"
    echo "   ✅ Added /opt/mssql-tools18/bin to PATH (temporary)."
  fi

  if ! grep -q "/opt/mssql-tools18/bin" ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
    echo "   📁 Persisted PATH update to ~/.bashrc"
  fi
}

if command -v sqlcmd >/dev/null 2>&1 || [ -x /opt/mssql-tools18/bin/sqlcmd ]; then
  echo "✅ sqlcmd already installed."
  add_sqlcmd_path
else
  echo "📦 Installing mssql-tools18..."

  # Ensure Microsoft repository is configured
  setup_microsoft_repo

  sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev >/dev/null
  add_sqlcmd_path
  echo "✅ sqlcmd installed successfully."
fi

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo ""
echo "🎯 Vim environment setup complete!"
echo "   - fzf: $(fzf --version 2>/dev/null || echo 'not found')"
echo "   - rg: $(rg --version | head -n 1 2>/dev/null || echo 'not found')"
echo "   - nnn: $(nnn -V 2>&1 | head -n 1 2>/dev/null || echo 'not found')"
echo "   - fd: $(fd --version 2>/dev/null | head -n 1 || fdfind --version 2>/dev/null | head -n 1 || echo 'not found')"
echo "   - code-minimap: $(code-minimap --version 2>/dev/null | head -n 1 || echo 'not found')"
echo "   - node: $(node -v 2>/dev/null || echo 'not found')"
echo "   - dotnet: $(dotnet --version 2>/dev/null || echo 'not found')"
echo "   - sqlcmd: $(sqlcmd -? 2>/dev/null | head -n 1 || echo 'not found')"

