" Custom statusline

set laststatus=2
set noshowmode
set shortmess+=F
set statusline=%!BuildStatusLine()

hi StatusLine     ctermfg=White ctermbg=233 cterm=none guifg=#ffffff guibg=#121212 gui=none
hi StatusLineNC   ctermfg=Gray  ctermbg=233 cterm=none guifg=#808080 guibg=#121212 gui=none
hi StatusFile     ctermfg=Cyan  ctermbg=233 cterm=none guifg=#00ffff guibg=#121212 gui=none
hi StatusFlags    ctermfg=DarkGray ctermbg=233 cterm=none guifg=#666666 guibg=#121212 gui=none
hi StatusBranch   ctermfg=White ctermbg=236 cterm=bold guifg=#ffffff guibg=#303030 gui=bold
hi StatusFileType ctermfg=Cyan  ctermbg=236 cterm=bold guifg=#00ffff guibg=#303030 gui=bold
hi StatusModeNormal  ctermfg=232 ctermbg=Yellow    cterm=bold guifg=#000000 guibg=#ffff00 gui=bold
hi StatusModeInsert  ctermfg=232 ctermbg=Cyan     cterm=bold guifg=#000000 guibg=#00ffff gui=bold
hi StatusModeVisual  ctermfg=232 ctermbg=DarkYellow cterm=bold guifg=#000000 guibg=#aa8800 gui=bold
hi StatusModeReplace ctermfg=232 ctermbg=Red      cterm=bold guifg=#000000 guibg=#ff0000 gui=bold
hi StatusModeCommand ctermfg=232 ctermbg=Green    cterm=bold guifg=#000000 guibg=#00ff00 gui=bold
" Inactive window highlights (muted)
hi StatusModeNC      ctermfg=240 ctermbg=235 cterm=none guifg=#585858 guibg=#262626 gui=none
hi StatusBranchNC    ctermfg=240 ctermbg=234 cterm=none guifg=#585858 guibg=#1c1c1c gui=none
hi StatusFileNC      ctermfg=240 ctermbg=233 cterm=none guifg=#585858 guibg=#121212 gui=none
hi StatusFileTypeNC  ctermfg=240 ctermbg=234 cterm=none guifg=#585858 guibg=#1c1c1c gui=none
hi StatusFlagsNC     ctermfg=236 ctermbg=233 cterm=none guifg=#303030 guibg=#121212 gui=none

function! BuildStatusLine()
    let is_active = g:statusline_winid == win_getid()
    if is_active
        let s = '%#StatusMode#%{GetMode()}%#StatusBranch#%{GetBranch()}%#StatusLine# '
        let s .= '%#StatusFile#%{GetFilePath()}%#StatusFlags# %m%r%h%w%#StatusLine#'
        let s .= '%=%#StatusFileType#%{GetFileType()}%#StatusLine#%{GetSearchCount()}'
        let s .= '%#StatusMode# %p%% %l/%L:%c '
    else
        let s = '%#StatusBranchNC#%{GetBranch()}%#StatusLineNC# '
        let s .= '%#StatusFileNC#%{GetFilePath()}%#StatusFlagsNC# %m%r%h%w'
        let s .= '%=%#StatusFileTypeNC#%{GetFileType()}%#StatusLineNC#'
        let s .= '%#StatusModeNC# %p%% %l/%L:%c '
    endif
    return s
endfunction

function! GetModeNC()
    return ''
endfunction

function! TruncateName(name)
    let width = winwidth(0)
    let mode_len = 12
    let branch_len = exists('*FugitiveHead') && FugitiveHead() != '' ? len(FugitiveHead()) + 5 : 0
    let filetype_len = &filetype != '' ? len(&filetype) + 6 : 0
    let right_side = 20
    let flags_len = 0
    if &modified | let flags_len += 3 | endif
    if &readonly | let flags_len += 4 | endif
    let reserved = mode_len + branch_len + filetype_len + right_side + flags_len
    let maxwidth = width - reserved
    if maxwidth < 8
        let maxwidth = 8
    endif
    if len(a:name) > maxwidth
        return '...' . strpart(a:name, len(a:name) - maxwidth + 3)
    endif
    return a:name
endfunction

function! GetFilePath()
    let ft = &filetype
    let fname = expand('%:p')
    if ft == 'netrw'
        let path = exists('b:netrw_curdir') ? b:netrw_curdir : getcwd()
        return TruncateName(fnamemodify(substitute(path, '/$', '', ''), ':t'))
    elseif ft == 'fugitive'
        return 'Git Status'
    elseif ft == 'help'
        return TruncateName(expand('%:t'))
    elseif ft == 'qf'
        return 'Quickfix'
    elseif fname =~# '^fugitive://'
        return TruncateName('Git: ' . fnamemodify(fname, ':t'))
    elseif fname == ''
        return '[No Name]'
    else
        return TruncateName(expand('%:t'))
    endif
endfunction

function! GetBranch()
    if exists('*FugitiveHead')
        let branch = FugitiveHead()
        if branch != ''
            return '   ' . branch . ' '
        endif
    endif
    return ''
endfunction

function! GetFileType()
    let ft = &filetype
    if ft == ''
        return ''
    endif
    let icons = {
        \ 'vim': "\ue62b",
        \ 'python': "\ue73c",
        \ 'javascript': "\ue74e",
        \ 'typescript': "\ue628",
        \ 'html': "\ue736",
        \ 'css': "\ue749",
        \ 'json': "\ue60b",
        \ 'markdown': "\ue73e",
        \ 'sh': "\ue795",
        \ 'bash': "\ue795",
        \ 'zsh': "\ue795",
        \ 'c': "\ue61e",
        \ 'cpp': "\ue61d",
        \ 'go': "\ue626",
        \ 'rust': "\ue7a8",
        \ 'lua': "\ue620",
        \ 'ruby': "\ue791",
        \ 'yaml': "\ue60b",
        \ 'toml': "\ue60b",
        \ 'sql': "\ue706",
        \ 'git': "\ue702",
        \ 'fugitive': "\ue702",
        \ }
    let icon = get(icons, ft, "\uf15c")
    return '  ' . icon . ' ' . ft . ' '
endfunction

function! GetSearchCount()
    if v:hlsearch == 0
        return ''
    endif
    let result = searchcount({'maxcount': 999})
    if empty(result)
        return ''
    endif
    if result.total == 0
        return '/' . @/ . ' [No matches]'
    endif
    if result.incomplete == 1
        return '/' . @/ . ' [?/??]'
    endif
    return '/' . @/ . ' [' . result.current . '/' . result.total . ']'
endfunction

function! GetMode()
    let mode = mode()
    if mode == 'n'
        hi! link StatusMode StatusModeNormal
        return '  NORMAL '
    elseif mode == 'i'
        hi! link StatusMode StatusModeInsert
        return '  INSERT '
    elseif mode == 'v' || mode == 'V' || mode == "\<C-v>"
        hi! link StatusMode StatusModeVisual
        if mode == 'v'
            return '  VISUAL '
        elseif mode == 'V'
            return '  V-LINE '
        else
            return '  V-BLOCK '
        endif
    elseif mode == 'R'
        hi! link StatusMode StatusModeReplace
        return '  REPLACE '
    elseif mode == 'c'
        hi! link StatusMode StatusModeCommand
        return '  COMMAND '
    else
        hi! link StatusMode StatusModeNormal
        return '  ' . mode . ' '
    endif
endfunction
