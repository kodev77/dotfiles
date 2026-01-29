" fzf.vim configuration

let g:fzf_layout = { 'down': '40%' }

" Keybindings
nnoremap <leader>ff :FilesG<CR>
nnoremap <leader>fg :RgG<CR>

" Custom grouped ripgrep (vscode-style)
function! s:rg_grouped_handler(line) abort
    let parts = split(a:line, '\t')
    if len(parts) >= 2
        let file = parts[0]
        let linenum = matchstr(parts[1], '^\s*\zs\d\+')
        if !empty(linenum) && !empty(file)
            execute 'edit +' . linenum . ' ' . fnameescape(file)
        endif
    endif
endfunction

function! RgGrouped(query) abort
    let awk_script = '/^$/ { next } !/^[0-9]+:/ { file=$0; print "\t\033[1;90m" file "\033[0m" } /^[0-9]+:/ { print file "\t    " $0 }'
    let initial_cmd = 'rg --heading --line-number ' . shellescape(a:query) . " | awk '" . awk_script . "'"
    let reload_cmd = "rg --heading --line-number {q} | awk '" . awk_script . "'"
    call fzf#run(fzf#wrap({
        \ 'source': initial_cmd,
        \ 'options': ['--ansi', '--with-nth=2..', '--delimiter=\t', '--height=80%', '--layout=reverse', '--border',
        \             '--disabled', '--query', a:query,
        \             '--bind', 'change:reload:' . reload_cmd],
        \ 'sink': function('s:rg_grouped_handler')
    \ }))
endfunction

command! -nargs=* RgG call RgGrouped(<q-args>)

" Custom grouped files (vscode-style)
function! s:files_grouped_handler(line) abort
    let parts = split(a:line, '\t')
    if len(parts) >= 2
        let file = parts[0]
        if !empty(file) && filereadable(file)
            execute 'edit ' . fnameescape(file)
        endif
    endif
endfunction

function! FilesGrouped() abort
    let awk_script = '{ dir=$0; gsub(/[^\/]+$/, "", dir); file=$0; gsub(/.*\//, "", file); if (dir != lastdir) { print "\t\033[1;90m" dir "\033[0m"; lastdir=dir } print $0 "\t    " file }'
    let initial_cmd = "find . -type f -not -path '*/\\.git/*' | sort | awk '" . awk_script . "'"
    let reload_cmd = "find . -type f -not -path '*/\\.git/*' | grep -i {q} | sort | awk '" . awk_script . "'"
    call fzf#run(fzf#wrap({
        \ 'source': initial_cmd,
        \ 'options': ['--ansi', '--with-nth=2..', '--delimiter=\t', '--height=80%', '--layout=reverse', '--border',
        \             '--disabled', '--bind', 'change:reload:' . reload_cmd],
        \ 'sink': function('s:files_grouped_handler')
    \ }))
endfunction

command! FilesG call FilesGrouped()
