# ripgrep with grouped results (like vscode)
alias rgs='rg --heading --line-number --color=always --colors "path:fg:cyan" --colors "path:style:bold"'

# search file contents: fg <pattern>
fg() {
    local result
    result=$(rg --line-number --color=always --colors 'path:fg:cyan' --colors 'path:style:bold' "$1" 2>/dev/null | fzf --ansi --height 80% --layout=reverse --border)
    if [ -n "$result" ]; then
        local clean=$(echo "$result" | sed 's/\x1b\[[0-9;]*m//g')
        local file=$(echo "$clean" | cut -d: -f1)
        local line=$(echo "$clean" | cut -d: -f2)
        vim "+$line" "$file"
    fi
}
