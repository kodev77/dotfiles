" =============================================================================
" Plugin declarations (vim-plug)
" Plugins are loaded from ~/.vim/plugins/*.vim
" =============================================================================

call plug#begin('~/.vim/plugged')

for f in glob('~/.vim/plugins/*.vim', 0, 1)
  execute 'source' f
endfor

call plug#end()

" =============================================================================
" Core settings (always loaded)
" =============================================================================

" Leader key
let mapleader = " "

" Colorscheme
set background=dark
colorscheme koehler

" Line numbers
set number

" Tabs and indentation
set expandtab
set tabstop=4
set shiftwidth=4
set smartindent

" Search
set ignorecase
set smartcase
set incsearch
set hlsearch

" Quality of life
set splitbelow
set splitright
set scrolloff=8
set signcolumn=auto
set nowrap
set clipboard=unnamedplus
set noswapfile

" Performance
set updatetime=300
set timeoutlen=500

" Auto reload files changed outside vim
set autoread
au FocusGained,BufEnter * silent! checktime

" Show full path with Ctrl-g
nnoremap <C-g> 1<C-g>

" Window navigation
nnoremap <leader>h <C-w>h
nnoremap <leader>j <C-w>j
nnoremap <leader>k <C-w>k
nnoremap <leader>l <C-w>l

" =============================================================================
" Feature configs (loaded from ~/.vim/config/*.vim)
" =============================================================================

for f in glob('~/.vim/config/*.vim', 0, 1)
  execute 'source' f
endfor
