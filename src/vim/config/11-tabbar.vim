" Custom tabbar configuration

" Tab colors (orange theme)
hi TabLineSel  ctermfg=232 ctermbg=208  cterm=bold guifg=#000000 guibg=#ff8800 gui=bold
hi TabLine     ctermfg=130 ctermbg=208  cterm=bold guifg=#af5f00 guibg=#ff8800 gui=bold
hi TabLineFill ctermfg=NONE ctermbg=208 cterm=none guifg=#000000 guibg=#ff8800 gui=none

" Tab navigation
nnoremap <leader>tt :Tabnew<CR>
nnoremap <leader>tc :tabclose<CR>
nnoremap <leader>to :call CloseOtherTabs()<CR>
nnoremap <leader>tr :call RenameTab()<CR>
nnoremap <leader>1 1gt
nnoremap <leader>2 2gt
nnoremap <leader>3 3gt
nnoremap <leader>4 4gt
nnoremap <leader>5 5gt
nnoremap <leader>6 6gt
nnoremap <leader>7 7gt
nnoremap <leader>8 8gt
nnoremap <leader>9 9gt
nnoremap <leader>0 10gt

" Limit to 10 tabs
command! -nargs=* Tabnew if tabpagenr('$') < 10 | tabnew <args> | else | echo "Max 10 tabs" | endif
cabbrev tabnew Tabnew
cabbrev tabe Tabnew
cabbrev tabedit Tabnew

" Use custom tabline
set showtabline=1
set tabline=%!CustomTabLine()

" Functions

function! NetrwTabOpen()
    if tabpagenr('$') >= 10
        echo "Max 10 tabs"
        return
    endif
    let curline = getline('.')
    let fname = substitute(curline, '^\s*\|\s*$', '', 'g')
    execute 'tabnew ' . b:netrw_curdir . '/' . fname
    echo ''
endfunction

function! CloseOtherTabs()
    let current_buf = bufnr('%')
    let buffers_to_delete = []
    for i in range(1, tabpagenr('$'))
        if i != tabpagenr()
            let bufnr = tabpagebuflist(i)[tabpagewinnr(i) - 1]
            if bufnr != current_buf
                call add(buffers_to_delete, bufnr)
            endif
        endif
    endfor
    tabonly
    for buf in buffers_to_delete
        silent! execute 'bdelete ' . buf
    endfor
endfunction

function! RenameTab()
    let name = input('Tab name: ')
    if name != ''
        let t:tabname = name
        redrawtabline
    endif
endfunction

function! CustomTabLine()
    let s = ''
    for i in range(tabpagenr('$'))
        let tabnr = i + 1
        let s .= (tabnr == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#')
        let s .= '%' . tabnr . 'T'
        let tablabel = tabnr == 10 ? '0' : tabnr
        let tabname = gettabvar(tabnr, 'tabname', '')
        if tabname != ''
            let s .= ' ' . tablabel . ':' . tabname . ' '
        else
            let bufnr = tabpagebuflist(tabnr)[tabpagewinnr(tabnr) - 1]
            let buftype = getbufvar(bufnr, '&buftype')
            let filetype = getbufvar(bufnr, '&filetype')
            let fname = bufname(bufnr)
            if filetype == 'netrw'
                let label = 'NETRW'
            elseif filetype == 'fugitive' || fname =~# '^fugitive://'
                let label = 'GIT'
            elseif filetype == 'help'
                let label = 'HELP'
            elseif buftype == 'terminal'
                let label = 'TERMINAL'
            elseif buftype == 'quickfix'
                let label = 'QUICKFIX'
            else
                let basename = fnamemodify(fname, ':t')
                if basename != ''
                    let label = toupper(basename)
                elseif filetype != ''
                    let label = toupper(filetype)
                else
                    let label = '[NO NAME]'
                endif
            endif
            let s .= ' ' . tablabel . ':' . label . ' '
        endif
    endfor
    let s .= '%#TabLineFill#'
    return s
endfunction
