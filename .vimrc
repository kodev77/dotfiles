call plug#begin('~/.vim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

call plug#end()

" colorscheme
set background=dark
colorscheme koehler

" retro tab colors (msdos style)
hi TabLineSel  ctermfg=232 ctermbg=Cyan  cterm=bold guifg=#000000 guibg=#00ffff gui=bold
hi TabLine     ctermfg=37 ctermbg=23    cterm=bold guifg=#008888 guibg=#002222 gui=bold
hi TabLineFill ctermfg=NONE ctermbg=NONE cterm=none guifg=#000000 guibg=#000000 gui=none

" leader key
let mapleader = " "

" line numbers
set number

" highlight current line (only in active window)
set cursorline
augroup CursorLineOnlyInActiveWindow
    autocmd!
    autocmd WinEnter * set cursorline
    autocmd WinLeave * set nocursorline
augroup END

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
