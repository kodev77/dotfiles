#!/bin/bash
# bash-core - Base bashrc.local setup
source "$(dirname "$0")/_lib.sh"

if is_remove "$1"; then
    log_info "Removing bash core..."

    # Remove .bashrc.d contents
    if [ -d "$DOTFILES_DIR/.bashrc.d" ]; then
        rm -rf "$DOTFILES_DIR/.bashrc.d"
        log_info "Removed .bashrc.d/"
    fi

    # Remove .bashrc.local
    rm -f "$DOTFILES_DIR/.bashrc.local"
    log_info "Removed .bashrc.local"

    # Remove sourcing block from ~/.bashrc
    if grep -q "repo/dotfiles/.bashrc.local" ~/.bashrc; then
        sed -i '/# load custom dotfiles config/,/^fi$/d' ~/.bashrc
        sed -i '/^$/N;/^\n$/d' ~/.bashrc
        log_info "Removed dotfiles sourcing from ~/.bashrc"
    fi

    log_info "bash core removed - restart shell"
    exit 0
fi

log_info "Setting up bash core..."

# Ensure ~/.local/bin is set up
ensure_local_bin

# Create .bashrc.d directory
mkdir -p "$DOTFILES_DIR/.bashrc.d"

# Update .bashrc.local to source all .bashrc.d/*.sh files
cat > "$DOTFILES_DIR/.bashrc.local" << 'EOF'
# Source all bashrc.d scripts
for f in ~/repo/dotfiles/.bashrc.d/*.sh; do
    [ -r "$f" ] && source "$f"
done
EOF

# Add .bashrc.local sourcing to .bashrc if not present
if ! grep -q "repo/dotfiles/.bashrc.local" ~/.bashrc; then
    log_info "Adding .bashrc.local to .bashrc..."
    echo "" >> ~/.bashrc
    echo "# load custom dotfiles config" >> ~/.bashrc
    echo "if [ -f ~/repo/dotfiles/.bashrc.local ]; then" >> ~/.bashrc
    echo "    source ~/repo/dotfiles/.bashrc.local" >> ~/.bashrc
    echo "fi" >> ~/.bashrc
else
    log_info ".bashrc.local already sourced in .bashrc"
fi

log_info "bash core ready"
