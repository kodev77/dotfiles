call plug#begin('~/.vim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'lambdalisue/fern.vim'
Plug 'lambdalisue/nerdfont.vim'
Plug 'lambdalisue/fern-renderer-nerdfont.vim'

call plug#end()

" fzf settings
let g:fzf_layout = { 'down': '40%' }

" fern.vim settings
let g:fern#renderer = 'nerdfont'

" disable netrw
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

" open fern instead of netrw when opening a directory
augroup FernHijack
  autocmd!
  autocmd BufEnter * ++nested if isdirectory(expand('%')) | bd | exe 'Fern . -drawer -reveal=%' | endif
augroup END

" netrw replacement commands
command! Ex Fern . -drawer -reveal=%
command! Explore Fern . -drawer -reveal=%
command! Vex Fern . -drawer -reveal=%
command! Sex Fern . -drawer -reveal=%

" fern custom keybindings
let g:fern#default_hidden = 1
let g:fern#renderer#nerdfont#indent_markers = 1
let g:fern#renderer#nerdfont#root_symbol = "\uf07c  "


let g:fern_project_root = getcwd()

function! s:fern_enter_and_cd() abort
  let helper = fern#helper#new()
  let node = helper.sync.get_cursor_node()
  let path = node._path
  if isdirectory(path)
    let g:fern_project_root = path
    windo lcd `=path`
    wincmd p
    echo 'Working dir: ' . path
  endif
  call fern#action#call('enter')
endfunction

function! s:fern_leave_and_cd() abort
  call fern#action#call('leave')
  sleep 100m
  let g:fern_project_root = fern#helper#new().sync.get_root_node()._path
  windo lcd `=g:fern_project_root`
  wincmd p
  echo 'Working dir: ' . g:fern_project_root
endfunction

function! s:fern_init() abort
  setlocal nonumber signcolumn=no
  nmap <buffer> <CR> :call <SID>fern_enter_and_cd()<CR>
  nmap <buffer> o <Plug>(fern-action-open)
  nmap <buffer> l <Plug>(fern-action-expand)
  nmap <buffer> h <Plug>(fern-action-collapse)
  nmap <buffer> - :call <SID>fern_leave_and_cd()<CR>
  nmap <buffer> m <Plug>(fern-action-mark:toggle)
endfunction

augroup fern-custom
  autocmd!
  autocmd FileType fern call s:fern_init()
augroup END

" colorscheme
set background=dark
colorscheme koehler

" retro tab colors (orange theme)
hi TabLineSel  ctermfg=232 ctermbg=208  cterm=bold guifg=#000000 guibg=#ff8800 gui=bold
hi TabLine     ctermfg=232 ctermbg=208  cterm=none guifg=#000000 guibg=#ff8800 gui=none
hi TabLineFill ctermfg=NONE ctermbg=208 cterm=none guifg=#000000 guibg=#ff8800 gui=none

" fern root styling
hi FernRootSymbol ctermfg=51 guifg=#00ffff cterm=bold gui=bold
hi FernRootText ctermfg=51 guifg=#00ffff cterm=bold gui=bold



" leader key
let mapleader = " "

" line numbers
set number


" tabs and indentation
set expandtab
set tabstop=4
set shiftwidth=4
set smartindent

" search
set ignorecase
set smartcase
set incsearch
set hlsearch

" quality of life
set splitbelow
set splitright
set scrolloff=8
set signcolumn=auto
set nowrap
set clipboard=unnamedplus
set noswapfile
" statusline
source ~/repo/dotfiles/.vim/config/ko-statusbar.vim

" performance
set updatetime=300
set timeoutlen=500

" auto reload files changed outside vim
set autoread
au FocusGained,BufEnter * silent! checktime

" show full path with Ctrl-g
nnoremap <C-g> 1<C-g>

" window navigation
nnoremap <leader>h <C-w>h
nnoremap <leader>j <C-w>j
nnoremap <leader>k <C-w>k
nnoremap <leader>l <C-w>l

" fzf keybindings
nnoremap <leader>ff :FilesG<CR>
nnoremap <leader>fg :RgG<CR>

" fern keybindings
nnoremap <leader>e :Fern . -drawer -toggle -reveal=%<CR>
nnoremap <leader>E :execute 'Fern ' . fnameescape(g:fern_project_root) . ' -drawer -reveal=%'<CR>

" custom grouped ripgrep (vscode-style)
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

" custom grouped files (vscode-style)
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

" tab management
source ~/repo/dotfiles/.vim/config/ko-tabbar.vim
command! -nargs=* Tabnew if tabpagenr('$') < 10 | tabnew <args> | else | echo "Max 10 tabs" | endif
cabbrev tabnew Tabnew
cabbrev tabe Tabnew
cabbrev tabedit Tabnew
nnoremap <leader>tt :Tabnew<CR>
autocmd FileType netrw nmap <buffer> <silent> t :call NetrwTabOpen()<CR>
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
set tabline=%!CustomTabLine()
set showtabline=1
