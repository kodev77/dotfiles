" Custom tabline functions

function! NetrwTabOpen()
    if tabpagenr('$') >= 10
        echo "Max 10 tabs"
        return
    endif
    let curline = getline('.')
    let fname = substitute(curline, '^\s*\|\s*$', '', 'g')
    execute 'tabnew ' . b:netrw_curdir . '/' . fname
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
            let s .= ' ' . tablabel . ':' . toupper(tabname) . ' '
        else
            let bufnr = tabpagebuflist(tabnr)[tabpagewinnr(tabnr) - 1]
            let buftype = getbufvar(bufnr, '&buftype')
            let filetype = getbufvar(bufnr, '&filetype')
            let fname = bufname(bufnr)
            if filetype == 'netrw'
                let label = 'FILES'
            elseif filetype == 'fugitive' || fname =~# '^fugitive://'
                let label = 'GIT'
            elseif filetype == 'help'
                let label = 'HELP'
            elseif buftype == 'terminal'
                let label = 'TERMINAL'
            elseif buftype == 'quickfix'
                let label = 'QUICKFIX'
            elseif fname != ''
                let label = toupper(fnamemodify(fname, ':t'))
            else
                let label = '[NO NAME]'
            endif
            let s .= ' ' . tablabel . ':' . label . ' '
        endif
    endfor
    let s .= '%#TabLineFill#'
    return s
endfunction
