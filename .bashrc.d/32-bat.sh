# bat - syntax highlighted cat
# Handle Ubuntu's batcat binary name
if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
    alias bat='batcat'
fi
