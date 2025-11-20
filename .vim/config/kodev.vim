let g:netrw_keepdir = 0
set nocompatible
set scrolloff=10 " Optional UI tweaks set number
set showcmd
set number
syntax on
filetype plugin indent on

set background=dark
set t_Co=256
set termguicolors

" Set leader key
" let mapleader = " "

" Custom commands 
command! -nargs=* Vs vsplit <args> | wincmd l
command! -nargs=* Sp split <args> | wincmd j
cabbrev vs Vs
cabbrev sp Sp

" Show Notepad++-style invisibles
set listchars=tab:→-,space:·,trail:·,nbsp:⍽,eol:¶,extends:›,precedes:‹

" Highlight all spaces, tabs, etc.
highlight NonText ctermfg=DarkGray guifg=#606060
highlight SpecialKey ctermfg=DarkGray guifg=#606060
highlight Conceal ctermfg=DarkGray guifg=#606060


