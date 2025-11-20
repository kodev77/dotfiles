#!/usr/bin/env bash
# ~/.vim/config/init.sh
# Minimal setup script to ensure Node.js is installed for coc.nvim

set -e

echo "🚀 Vim environment setup starting..."

# -----------------------------------------------------------------------------
# Detect Windows host IP
# -----------------------------------------------------------------------------
WINDOWS_IP=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | head -n 1)
echo "🖥️  Detected Windows host IP: $WINDOWS_IP"

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
  if [ "$EUID" -ne 0 ]; then
    echo "🔑 Requesting sudo privileges..."
    sudo -v
  fi

  echo "🧹 Removing minimal Vim packages..."
  sudo apt remove -y vim-tiny vim-nox >/dev/null 2>&1 || true

  echo "📦 Installing vim-gtk3..."
  sudo apt install -y vim-gtk3 >/dev/null

  echo "🔄 Setting vim-gtk3 as default..."
  sudo update-alternatives --set vim /usr/bin/vim.gtk3 2>/dev/null || sudo update-alternatives --config vim

  echo "✅ Vim upgraded successfully!"
  vim --version | head -n 1
  vim --version | grep clipboard
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
  if [ "$EUID" -ne 0 ]; then
    echo "🔑 Requesting sudo privileges..."
    sudo -v
  fi
  sudo apt update -qq
  sudo apt install -y fzf >/dev/null
  if command -v fzf >/dev/null 2>&1; then
    echo "🎉 fzf installed successfully: $(fzf --version)"
  else
    echo "❌ fzf installation failed."
  fi
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
  if [ "$EUID" -ne 0 ]; then
    echo "🔑 Requesting sudo privileges..."
    sudo -v
  fi
  sudo apt update -qq
  sudo apt install -y ripgrep >/dev/null
  if command -v rg >/dev/null 2>&1; then
    echo "🎉 ripgrep installed successfully: $(rg --version | head -n 1)"
  else
    echo "❌ ripgrep installation failed."
  fi
fi

# -----------------------------------------------------------------------------
# Node.js setup for coc.nvim
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for Node.js..."
if command -v node >/dev/null 2>&1; then
  echo "✅ Node.js detected: $(node -v)"
else
  echo "📦 Installing Node.js LTS..."
  if [ "$EUID" -ne 0 ]; then
    echo "🔑 Requesting sudo privileges..."
    sudo -v
  fi
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - >/dev/null
  sudo apt install -y nodejs >/dev/null
  echo "✅ Node.js installed: $(node -v)"
fi

# -----------------------------------------------------------------------------
# sqlcmd setup for vim-dadbod
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
  if [ "$(id -u)" -ne 0 ]; then
    echo "🔑 Requesting sudo privileges..."
    sudo -v
  fi

  if [ -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
    echo "🧹 Removing duplicate Microsoft repo..."
    sudo rm -f /etc/apt/sources.list.d/microsoft-prod.list
  fi

  if [ ! -f /etc/apt/sources.list.d/mssql-release.list ]; then
    echo "➕ Adding Microsoft repo..."
    curl -s https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - >/dev/null
    curl -s https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | \
      sudo tee /etc/apt/sources.list.d/mssql-release.list >/dev/null
  fi

  echo "📦 Installing mssql-tools18 and unixodbc-dev..."
  sudo apt update -qq
  sudo ACCEPT_EULA=Y apt install -y mssql-tools18 unixodbc-dev >/dev/null

  add_sqlcmd_path

  if command -v sqlcmd >/dev/null 2>&1; then
    echo "🎉 sqlcmd installed successfully!"
  else
    echo "❌ sqlcmd installation failed."
    # exit 1
  fi
fi

# -----------------------------------------------------------------------------
# SQL Server WSL Firewall reminder
# -----------------------------------------------------------------------------
echo ""
echo "🧱 To allow WSL SQL Server access, run in PowerShell (Admin):"
echo "──────────────────────────────────────────────────────────────"
echo "netsh advfirewall firewall show rule name=all | findstr /I 1433"
echo "netsh advfirewall firewall add rule name=\"SQL Server from WSL\" dir=in action=allow protocol=TCP localport=1433 remoteip=${WINDOWS_IP}/20"
echo "──────────────────────────────────────────────────────────────"

# -----------------------------------------------------------------------------
# OmniSharp Roslyn (C# Language Server)
# -----------------------------------------------------------------------------
echo ""
echo "⚙️  Reminder: Run :PlugInstall inside Vim to set up all plugins."
echo "   If using OmniSharp, ensure the Roslyn server (net6.0) is available."

# -----------------------------------------------------------------------------
# Microsoft Credential Provider for NuGet (optional)
# -----------------------------------------------------------------------------
echo ""
echo "🔍 Checking for Microsoft Artifact Credential Provider..."

# The provider usually installs under this path
CRED_PROVIDER_PATH="$HOME/.nuget/plugins/netcore/CredentialProvider.Microsoft"

if [ -d "$CRED_PROVIDER_PATH" ]; then
  echo "✅ Credential Provider already installed at: $CRED_PROVIDER_PATH"
else
  echo "🔐 Installing Microsoft Artifact Credential Provider..."
  wget -q https://aka.ms/install-artifacts-credprovider.sh -O ~/install-artifacts-credprovider.sh
  bash ~/install-artifacts-credprovider.sh >/dev/null 2>&1
  if [ -d "$CRED_PROVIDER_PATH" ]; then
    echo "✅ Credential Provider installed successfully."
  else
    echo "⚠️  Installation completed, but provider path not found — verify manually if needed."
  fi
fi

echo ""
echo "✅ All dependencies installed and environment ready!"

