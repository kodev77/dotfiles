" Custom tabline functions

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
        let tabname = gettabvar(tabnr, 'tabname', '')
        if tabname != ''
            let s .= ' ' . toupper(tabname) . ' '
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
            let s .= ' ' . label . ' '
        endif
    endfor
    let s .= '%#TabLineFill#'
    return s
endfunction
