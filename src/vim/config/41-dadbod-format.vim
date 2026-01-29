" dadbod-format configuration (requires dadbod_format.vim in autoload/)

" Format keybinding
nnoremap <leader>dF :call dadbod_format#format_from_anywhere()<CR>

" Auto-format and keybindings for dbout buffers
augroup dadbod_format
  autocmd!
  autocmd FileType dbui setlocal modifiable
  autocmd FileType dbout setlocal modifiable
  autocmd FileType dbout setlocal nofoldenable
  autocmd FileType dbout call dadbod_format#auto_format()
  autocmd BufEnter * if &filetype ==# 'dbout' && !get(b:, 'dbout_is_formatted', 0) | call dadbod_format#format() | endif
  autocmd FileType dbout nnoremap <buffer> <CR> :call dadbod_format#expand_cell()<CR>
  autocmd FileType dbout nnoremap <buffer> <leader>fr :call dadbod_format#toggle_raw()<CR>
  autocmd FileType dbout nnoremap <buffer> q :call dadbod_format#close_expand()<CR>
augroup END
