#!/bin/bash
# Shared functions for install scripts

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if command exists
check_cmd() {
    command -v "$1" &> /dev/null
}

# Install apt package if not present
install_apt() {
    local pkg="$1"
    if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
        log_info "Installing $pkg..."
        sudo apt install -y "$pkg"
    else
        log_info "$pkg already installed"
    fi
}

# Create symlink safely (backs up existing files)
make_symlink() {
    local src="$1"
    local dest="$2"
    if [ -L "$dest" ]; then
        rm "$dest"
    elif [ -e "$dest" ]; then
        mv "$dest" "${dest}.backup.$(date +%s)"
        log_warn "Backed up existing $dest"
    fi
    ln -sf "$src" "$dest"
    log_info "Linked $dest -> $src"
}

# Add line to file if not present
add_to_file() {
    local line="$1"
    local file="$2"
    if ! grep -qF "$line" "$file" 2>/dev/null; then
        echo "$line" >> "$file"
    fi
}

# Add block to file if marker not present
add_block_to_file() {
    local marker="$1"
    local block="$2"
    local file="$3"
    if ! grep -qF "$marker" "$file" 2>/dev/null; then
        echo "$block" >> "$file"
    fi
}

# Ensure ~/.local/bin exists and is in PATH
ensure_local_bin() {
    mkdir -p ~/.local/bin
    add_to_file 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc
}

# Check if --remove flag was passed
is_remove() {
    [ "$1" = "--remove" ]
}

# Remove files from .vim/plugins/, .vim/config/, .vim/autoload/, .vim/plugin/, .bashrc.d/
remove_files() {
    for f in "$@"; do
        if [ -f "$f" ]; then
            rm -f "$f"
            log_info "Removed $f"
        fi
    done
}
