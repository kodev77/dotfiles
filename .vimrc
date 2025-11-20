let mapleader = " "

" Disable nnn.vim default mappings so we can set our own
let g:nnn#set_default_mappings = 0

call plug#begin('~/.vim/plugged')

Plug 'mcchrish/nnn.vim'
Plug 'puremourning/vimspector'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'tpope/vim-dadbod'
Plug 'kristijanhusak/vim-dadbod-ui'
Plug 'kristijanhusak/vim-dadbod-completion'
Plug 'tpope/vim-fugitive'

source ~/.vim/config/omnisharp-vim_FULL.plug

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'godlygeek/tabular'

Plug 'tpope/vim-vinegar'

" Minimap with search highlights
Plug 'wfxr/minimap.vim'

" Statusline plugins
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

call plug#end()

" Configure nnn to open in current file's directory
nnoremap <leader>n :NnnPicker %:p:h<CR>

" Easy escape from terminal mode in nnn buffers
autocmd FileType nnn tnoremap <buffer> <Esc> <C-\><C-n>

" Quick command line access from nnn terminal
autocmd FileType nnn tnoremap <buffer> <C-o> <C-\><C-n>:

source ~/.vim/config/vimspector.vim
source ~/.vim/config/coc.nvim
source ~/.vim/config/vim-dadbod-ui.vim
" source ~/.vim/config/vim-dadbod-sql-format.vim
 
source ~/.vim/config/omnisharp-vim_FULL.vim

source ~/.vim/config/kodev.vim
source ~/.vim/config/statusbar.vim

" -----------------------------------------------------------------------------
" Minimap configuration (minimap.vim)
" -----------------------------------------------------------------------------
let g:minimap_width = 10
let g:minimap_auto_start = 0
let g:minimap_auto_start_win_enter = 1
let g:minimap_highlight_search = 1
let g:minimap_highlight_range = 1
let g:minimap_git_colors = 1

" Minimap <-> Fugitive Fix
" Do not auto-open minimap on diff windows or in fugitive buffers
augroup MinimapFugitiveFix
    au!
    au BufWinEnter * call s:CloseMinimapInDiff()
    au BufEnter fugitive://* silent! MinimapClose
augroup END

function! s:CloseMinimapInDiff()
    if &diff && exists(':MinimapClose')
        MinimapClose
    endif
endfunction

" Helper mapping to clear search highlights (minimap + vim)
" Using <leader>nh since <leader>n opens nnn file manager
nnoremap <silent> <leader>nh :nohlsearch<CR>:call minimap#vim#ClearColorSearch()<CR>

" Fix dadbod-ui command line readability - apply directly after colorscheme
highlight Question guifg=#ebdbb2 guibg=#1d2021 ctermfg=223 ctermbg=234
highlight MoreMsg guifg=#ebdbb2 guibg=#1d2021 ctermfg=223 ctermbg=234

" -----------------------------------------------------------------------------
" Vim cd-on-quit functionality
" -----------------------------------------------------------------------------
" Opt-in commands to quit and cd to current directory in the terminal
" This captures either:
"   1. The last netrw browsing directory (thanks to g:netrw_keepdir = 0)
"   2. The directory where Vim was started
"   3. Any directory set via :cd/:lcd commands
"
" Set tmpfile location 
let g:vim_cd_tmpfile = expand(empty($XDG_CONFIG_HOME) ? '$HOME/.config/vim/.lastd' : '$XDG_CONFIG_HOME/vim/.lastd')

" Ensure directory exists
call system('mkdir -p ' . shellescape(fnamemodify(g:vim_cd_tmpfile, ':h')))

" :Q - Quit and cd to current directory
command! Q call writefile(['cd ' . shellescape(getcwd())], g:vim_cd_tmpfile) | quit

" :Wq - Write, quit and cd to current directory
command! Wq write | call writefile(['cd ' . shellescape(getcwd())], g:vim_cd_tmpfile) | quit

" :WQ - Alias for :Wq (handle common typo)
command! WQ write | call writefile(['cd ' . shellescape(getcwd())], g:vim_cd_tmpfile) | quit

