" fzf.vim configuration

let g:fzf_layout = { 'down': '80%' }

" Keybindings
nnoremap <leader>ff :FilesG<CR>
nnoremap <leader>fg :RgG<CR>

" Custom grouped ripgrep (vscode-style) with bat preview
let s:bat_cmd = executable('bat') ? 'bat' : (executable('batcat') ? 'batcat' : '')
let s:search_dir = ''

" Get search root: git root of current buffer, or buffer dir, or cwd
function! s:get_search_root() abort
    let buf_name = expand('%')
    if buf_name =~ '^fern://'
        " Get the directory under cursor in Fern's tree
        try
            let node = fern#helper#new().sync.get_cursor_node()
            let buf_dir = isdirectory(node._path) ? node._path : fnamemodify(node._path, ':h')
        catch
            let buf_dir = substitute(buf_name, 'fern://.\{-}/file://', '', '')
        endtry
    else
        let buf_dir = expand('%:p:h')
    endif
    if empty(buf_dir) || !isdirectory(buf_dir)
        return getcwd()
    endif
    let git_root = trim(system('git -C ' . shellescape(buf_dir) . ' rev-parse --show-toplevel 2>/dev/null'))
    if v:shell_error == 0 && !empty(git_root)
        return git_root
    endif
    return buf_dir
endfunction

function! s:rg_grouped_handler(line) abort
    let info = substitute(split(a:line, '\t')[0], '\e\[[0-9;]*m', '', 'g')
    if info =~ ':'
        let file = substitute(info, ':.*', '', '')
        let linenum = substitute(info, '.*:', '', '')
        execute 'edit +' . linenum . ' ' . fnameescape(s:search_dir . '/' . file)
    elseif !empty(info)
        execute 'edit ' . fnameescape(s:search_dir . '/' . info)
    endif
endfunction

function! RgGrouped(query) abort
    let s:search_dir = s:get_search_root()
    let cd_prefix = 'cd ' . shellescape(s:search_dir) . ' && '
    let awk_script = '/^$/ { next } !/^[0-9]+[:-]/ { file=$0; printf "%s\t\033[36;1m%s\033[0m\n", file, file; next } { match($0, /^[0-9]+/); num=substr($0,1,RLENGTH); printf "%s:%s\t  \033[32m%s\033[0m\n", file, num, $0 }'
    let initial_cmd = cd_prefix . 'rg --heading --line-number ' . shellescape(a:query) . " | awk '" . awk_script . "'"
    let reload_cmd = cd_prefix . "rg --heading --line-number {q} | awk '" . awk_script . "'"

    let opts = ['--ansi', '--with-nth=2..', '--delimiter=\t', '--height=80%', '--layout=reverse', '--border',
        \       '--disabled', '--query', a:query,
        \       '--bind', 'change:reload:' . reload_cmd]

    if !empty(s:bat_cmd)
        let preview_cmd = cd_prefix . 'info=$(printf "%s" {1} | sed "s/\x1b\[[0-9;]*m//g"); case "$info" in *:*) file="${info%%:*}"; num="${info##*:}"; start=$((num > 5 ? num - 5 : 1)); ' . s:bat_cmd . ' --color=always --highlight-line "$num" --line-range "$start:" --style=numbers "$file" ;; *) ' . s:bat_cmd . ' --color=always --style=numbers "$info" ;; esac'
        let opts += ['--preview', preview_cmd, '--preview-window', 'right:60%']
    endif

    call fzf#run(fzf#wrap({
        \ 'source': initial_cmd,
        \ 'options': opts,
        \ 'sink': function('s:rg_grouped_handler')
    \ }))
endfunction

command! -nargs=* RgG call RgGrouped(<q-args>)
command! -nargs=* Rg call RgGrouped(<q-args>)

" Custom grouped files (vscode-style)
function! s:files_grouped_handler(line) abort
    let parts = split(a:line, '\t')
    if len(parts) >= 2
        let file = parts[0]
        if !empty(file)
            execute 'edit ' . fnameescape(s:search_dir . '/' . file)
        endif
    endif
endfunction

function! FilesGrouped() abort
    let s:search_dir = s:get_search_root()
    let cd_prefix = 'cd ' . shellescape(s:search_dir) . ' && '
    let awk_script = '{ dir=$0; gsub(/[^\/]+$/, "", dir); file=$0; gsub(/.*\//, "", file); if (dir != lastdir) { print "\t\033[1;90m" dir "\033[0m"; lastdir=dir } print $0 "\t    " file }'
    let initial_cmd = cd_prefix . "find . -type f -not -path '*/\\.git/*' | sort | awk '" . awk_script . "'"
    let reload_cmd = cd_prefix . "find . -type f -not -path '*/\\.git/*' | grep -i {q} | sort | awk '" . awk_script . "'"
    call fzf#run(fzf#wrap({
        \ 'source': initial_cmd,
        \ 'options': ['--ansi', '--with-nth=2..', '--delimiter=\t', '--height=80%', '--layout=reverse', '--border',
        \             '--disabled', '--bind', 'change:reload:' . reload_cmd],
        \ 'sink': function('s:files_grouped_handler')
    \ }))
endfunction

command! FilesG call FilesGrouped()
