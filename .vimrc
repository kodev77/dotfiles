call plug#begin('~/.vim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

call plug#end()

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
set scrolloff=8
set signcolumn=auto
set nowrap
set clipboard=unnamedplus

" performance
set updatetime=300
set timeoutlen=500

" auto reload files changed outside vim
set autoread
au FocusGained,BufEnter * silent! checktime
