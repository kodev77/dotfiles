" fern.vim configuration

" Use nerdfont renderer
let g:fern#renderer = 'nerdfont'

" Disable netrw
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

" Open fern instead of netrw when opening a directory
augroup FernHijack
  autocmd!
  autocmd BufEnter * ++nested if isdirectory(expand('%')) | exe 'Fern ' . expand('%') | endif
augroup END

" netrw replacement commands (open in current file's directory)
command! Ex Fern %:h
command! Explore Fern %:h
command! Rex Fern %:h -reveal=%
command! Vex call s:fern_split('vsplit')
command! Sex call s:fern_split('split')

function! s:fern_split(cmd) abort
  let dir = expand('%:h')
  execute a:cmd
  execute 'Fern ' . dir
endfunction

" Git status settings (disable some noise)
let g:fern_git_status#disable_ignored = 1
let g:fern_git_status#disable_untracked = 1

" Display settings
let g:fern#default_hidden = 1
let g:fern#renderer#nerdfont#indent_markers = 1
let g:fern#renderer#nerdfont#root_symbol = "\uf07c  "

function! s:fern_rename_prompt() abort
  let helper = fern#helper#new()
  let node = helper.sync.get_cursor_node()
  let old_path = node._path
  let old_name = fnamemodify(old_path, ':t')
  let dir = fnamemodify(old_path, ':h')
  let new_name = input('Rename: ', old_name)
  if new_name != '' && new_name != old_name
    let new_path = dir . '/' . new_name
    call rename(old_path, new_path)
    call fern#action#call('reload:all')
  endif
endfunction

function! s:fern_init() abort
  setlocal nonumber signcolumn=no
  nmap <buffer> <CR> <Plug>(fern-action-open-or-enter)
  nmap <buffer> o <Plug>(fern-action-open)
  nmap <buffer> v <Plug>(fern-action-open:vsplit)
  nmap <buffer> s <Plug>(fern-action-open:split)
  nmap <buffer> l <Plug>(fern-action-expand)
  nmap <buffer> h <Plug>(fern-action-collapse)
  nmap <buffer> - <Plug>(fern-action-leave)
  nmap <buffer> m <Plug>(fern-action-mark:toggle)
  nmap <buffer> D <Plug>(fern-action-remove)
  nmap <buffer> R :call <SID>fern_rename_prompt()<CR>
endfunction

augroup fern-custom
  autocmd!
  autocmd FileType fern call s:fern_init()
augroup END

" Fern root styling
hi FernRootSymbol ctermfg=51 guifg=#00ffff cterm=bold gui=bold
hi FernRootText ctermfg=51 guifg=#00ffff cterm=bold gui=bold
