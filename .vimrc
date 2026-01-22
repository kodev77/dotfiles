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

" highlight current line
set cursorline

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
set scrolloff=8
set signcolumn=auto
set nowrap
set clipboard=unnamedplus
set noswapfile

" performance
set updatetime=300
set timeoutlen=500

" auto reload files changed outside vim
set autoread
au FocusGained,BufEnter * silent! checktime

" tab management
source ~/repo/dotfiles/.vim/config/ko-tabbar.vim
nnoremap <leader>tt :tabnew<CR>
nnoremap <leader>tc :tabclose<CR>
nnoremap <leader>tr :call RenameTab()<CR>
set tabline=%!CustomTabLine()
set showtabline=2
