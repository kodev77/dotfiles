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

# Function to check if vim has +clipboard support
has_clipboard_support() {
  vim --version 2>/dev/null | grep -q "+clipboard"
}

if has_clipboard_support; then
  echo "✅ Full Vim with clipboard support already installed."
else
  echo "   Current Vim is missing clipboard or GUI features. Installing vim-gtk3..."

  if [ "$EUID" -ne 0 ]; then
    echo "🔑 Requesting sudo privileges..."
    sudo -v
  fi

  echo "🧹 Removing minimal Vim packages..."
  sudo apt remove -y vim-tiny vim-nox >/dev/null 2>&1 || true

  echo "📦 Installing full-featured Vim (vim-gtk3)..."
  sudo apt install -y vim-gtk3

  echo "🔄 Setting vim-gtk3 as the default alternative..."
  sudo update-alternatives --set vim /usr/bin/vim.gtk3 2>/dev/null || sudo update-alternatives --config vim

  echo "✅ Vim upgraded successfully!"
  vim --version | head -n 1
  vim --version | grep clipboard
fi

# -----------------------------------------------------------------------------
# Node.js setup for coc.nvim
# -----------------------------------------------------------------------------

echo "🔍 Checking for Node.js installation..."
if command -v node >/dev/null 2>&1; then
  echo "✅ Node.js is already installed: $(node -v)"
else
  echo "   Node.js not found. Installing LTS version..."

  # Require sudo
  if [ "$EUID" -ne 0 ]; then
    echo "🔑 Requesting sudo privileges..."
    sudo -v
  fi

  echo "📦 Adding NodeSource repository..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

  echo "   Installing Node.js..."
  sudo apt install -y nodejs
fi

# -----------------------------------------------------------------------------
# sqlcmd setup for vim-dadbod
# -----------------------------------------------------------------------------

echo ""
echo "🔍 Checking for sqlcmd installation..."

# Helper: Add /opt/mssql-tools18/bin to PATH for this session and persistently
add_sqlcmd_path() {
  if ! echo "$PATH" | grep -q "/opt/mssql-tools18/bin"; then
    export PATH="$PATH:/opt/mssql-tools18/bin"
    echo "   ✅ Added /opt/mssql-tools18/bin to PATH (temporary for this session)."
  fi

  # Make it permanent (safe append)
  if ! grep -q "/opt/mssql-tools18/bin" ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
    echo "   📁 Persisted PATH update to ~/.bashrc"
  fi
}

# Detect sqlcmd
if command -v sqlcmd >/dev/null 2>&1 || [ -x /opt/mssql-tools18/bin/sqlcmd ]; then
  echo "✅ sqlcmd is already installed."
  add_sqlcmd_path
else
  echo "   sqlcmd not found. Installing mssql-tools18..."

  if [ "$(id -u)" -ne 0 ]; then
    echo "🔑 Requesting sudo privileges..."
    sudo -v
  fi
  
  # Clean duplicate repo if needed
  if [ -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
    echo "🧹 Removing duplicate Microsoft repo..."
    sudo rm -f /etc/apt/sources.list.d/microsoft-prod.list
  fi

  # Add Microsoft repo only if missing
  if [ ! -f /etc/apt/sources.list.d/mssql-release.list ]; then
    echo "📦 Adding Microsoft repository..."
    curl -s https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - >/dev/null
    curl -s https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | \
      sudo tee /etc/apt/sources.list.d/mssql-release.list >/dev/null
  fi

  echo "🧰 Installing mssql-tools18 and dependencies..."
  sudo apt update -qq
  sudo ACCEPT_EULA=Y apt install -y mssql-tools18 unixodbc-dev >/dev/null

  add_sqlcmd_path

  if command -v sqlcmd >/dev/null 2>&1 || [ -x /opt/mssql-tools18/bin/sqlcmd ]; then
    echo "🎉 sqlcmd successfully installed and added to PATH!"
  else
    echo "❌ sqlcmd installation failed. Please check manually."
    exit 1
  fi
fi

# -----------------------------------------------------------------------------
# 3. Reminder to configure Windows Firewall for SQL Server access
# -----------------------------------------------------------------------------
echo ""
echo "🧱 If SQL Server is not accessible from WSL, run the following in a PowerShell (Admin) window on Windows:"
echo "──────────────────────────────────────────────────────────────────────────────"
echo "netsh advfirewall firewall show rule name=all | findstr /I 1433"
echo "netsh advfirewall firewall add rule name=\"SQL Server from WSL\" dir=in action=allow protocol=TCP localport=1433 remoteip=${WINDOWS_IP}/20"
echo "──────────────────────────────────────────────────────────────────────────────"
echo "💡 This allows WSL to reach your local SQL Server on port 1433."

# ------------------------------------------------------------
# OmniSharp Roslyn (net6.0) for Vim/Neovim (Ubuntu/WSL)
# ------------------------------------------------------------

# Insert a echo to use :PlugInstall or something

 
# ------------------------------------------------------------
# Install Microsoft’s credential provider in WSL
# ------------------------------------------------------------

wget https://aka.ms/install-artifacts-credprovider.sh -O ~/install-artifacts-credprovider.sh
bash ~/install-artifacts-credprovider.sh

# Now run this command to login: dotnet restore --interactive

# -----------------------------------------------------------------------------
echo ""
echo "✅ All dependencies installed and ready!"
