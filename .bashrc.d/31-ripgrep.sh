# ripgrep with grouped results (like vscode)
alias rgs='rg --heading --line-number --color=always --colors "path:fg:cyan" --colors "path:style:bold"'

# resolve bat binary path (Ubuntu installs it as batcat)
# type -P returns the file path, ignoring aliases
_bat_cmd=$(type -P bat || type -P batcat)

# search file contents: fg <pattern>
# Single view with grouped results (file headers + indented matches)
fg() {
    local result
    result=$(rg --heading --line-number "$@" 2>/dev/null | \
        awk '
            /^$/ { next }
            !/^[0-9]+[:-]/ {
                file = $0
                printf "%s\t\033[36;1m%s\033[0m\n", file, file
                next
            }
            {
                match($0, /^[0-9]+/)
                num = substr($0, 1, RLENGTH)
                printf "%s:%s\t  \033[32m%s\033[0m\n", file, num, $0
            }
        ' | \
        fzf --ansi --height 80% --layout=reverse --border \
            --with-nth=2.. --delimiter=$'\t' \
            --preview '
                info=$(printf "%s" {1} | sed "s/\x1b\[[0-9;]*m//g")
                case "$info" in
                    *:*) file="${info%%:*}"; num="${info##*:}"; start=$((num > 5 ? num - 5 : 1))
                         '"$_bat_cmd"' --color=always --highlight-line "$num" --line-range "$start:" --style=numbers "$file" ;;
                    *)   '"$_bat_cmd"' --color=always --style=numbers "$info" ;;
                esac' \
            --preview-window='right:60%')
    [ -z "$result" ] && return

    local clean=$(printf "%s" "$result" | sed 's/\x1b\[[0-9;]*m//g' | cut -f1)
    case "$clean" in
        *:*) vim "+${clean##*:}" "${clean%%:*}" ;;
        *)   vim "$clean" ;;
    esac
}
