# fzf aliases
alias ff='fzf --height 40% --layout=reverse --border --preview "head -100 {}" --bind "ctrl-o:become(vim {})" --bind "ctrl-y:execute-silent(echo -n {} | xclip -selection clipboard)+abort"'
alias fcd='cd $(find . -type d 2>/dev/null | fzf --height 40% --layout=reverse --border --preview "eza --tree --icons --level=2 {}")'
alias ffd='cd "$(dirname "$(fzf --height 40% --layout=reverse --border --preview "head -100 {}")")"'

# fuzzy history search and run
unalias fh 2>/dev/null
function fh {
    local cmd
    cmd=$(history | fzf --height 40% --layout=reverse --border --tac | sed "s/^[ ]*[0-9]*[ ]*//")
    if [ -n "$cmd" ]; then
        printf '> %s\n' "$cmd"
        eval "$cmd"
    fi
}
