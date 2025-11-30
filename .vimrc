" =============================================================================
" GENERAL SETTINGS
" =============================================================================
let mapleader = " "
set nocompatible
set encoding=utf-8
scriptencoding utf-8

" Visual settings
set number
set showcmd
set scrolloff=10
set title
set signcolumn=yes
syntax on
filetype indent plugin on

" Colors
set background=dark
set t_Co=256
if has('termguicolors')
  set termguicolors
endif

" Indentation
set expandtab
set shiftround
set shiftwidth=4
set softtabstop=-1
set tabstop=8
set textwidth=80
set backspace=indent,eol,start

" Search
set hlsearch
set incsearch

" Windows/buffers
set hidden
set nofixendofline
set nostartofline
set splitbelow
set splitright

" Misc
set mouse=a
set updatetime=1000
set laststatus=2
set noshowmode
set noruler

" Netrw
let g:netrw_keepdir = 0

" Show invisibles (Notepad++-style)
set listchars=tab:→-,space:·,trail:·,nbsp:⍽,eol:¶,extends:›,precedes:‹
highlight NonText ctermfg=DarkGray guifg=#606060
highlight SpecialKey ctermfg=DarkGray guifg=#606060
highlight Conceal ctermfg=DarkGray guifg=#606060

" =============================================================================
" PLUGIN MANAGER (vim-plug)
" =============================================================================
" Set this to 1 to use ultisnips for snippet handling
let s:using_snippets = 0

" Disable nnn.vim default mappings so we can set our own
let g:nnn#set_default_mappings = 0

call plug#begin('~/.vim/plugged')

" File manager
Plug 'mcchrish/nnn.vim'

" Debugging
Plug 'puremourning/vimspector'

" LSP / Completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Database
Plug 'tpope/vim-dadbod'
Plug 'kristijanhusak/vim-dadbod-ui'
Plug 'kristijanhusak/vim-dadbod-completion'

" Git
Plug 'tpope/vim-fugitive'

" C# / OmniSharp
Plug 'OmniSharp/omnisharp-vim'
Plug 'nickspoons/vim-sharpenup'

" Linting
Plug 'dense-analysis/ale'

" FZF (used as OmniSharp selector)
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Async completion (for OmniSharp)
Plug 'prabirshrestha/asyncomplete.vim'

" Colorschemes
Plug 'gruvbox-community/gruvbox'
Plug 'tomasiser/vim-code-dark'

" Utilities
Plug 'godlygeek/tabular'
Plug 'tpope/vim-vinegar'

" Minimap
Plug 'wfxr/minimap.vim'

" Statusline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Snippets (conditional)
if s:using_snippets
  Plug 'sirver/ultisnips'
endif

call plug#end()

" =============================================================================
" COLORSCHEME & HIGHLIGHTS
" =============================================================================
augroup ColorschemePreferences
  autocmd!
  " Clear some background colours for transparency
  autocmd ColorScheme * highlight Normal     ctermbg=NONE guibg=NONE
  autocmd ColorScheme * highlight SignColumn ctermbg=NONE guibg=NONE
  autocmd ColorScheme * highlight Todo       ctermbg=NONE guibg=NONE
  " Link ALE sign highlights to similar equivalents without background colours
  autocmd ColorScheme * highlight link ALEErrorSign   WarningMsg
  autocmd ColorScheme * highlight link ALEWarningSign ModeMsg
  autocmd ColorScheme * highlight link ALEInfoSign    Identifier
augroup END

colorscheme codedark

" Fix dadbod-ui command line readability
highlight Question guifg=#ebdbb2 guibg=#1d2021 ctermfg=223 ctermbg=234
highlight MoreMsg guifg=#ebdbb2 guibg=#1d2021 ctermfg=223 ctermbg=234

" =============================================================================
" COC.NVIM CONFIGURATION
" =============================================================================
" Completion options (CoC specific)
set completeopt=menuone,noinsert,noselect

" Navigate popup/confirm
inoremap <silent><expr> <CR> pumvisible() ? coc#pum#confirm() : "\<CR>"
inoremap <silent><expr> <Tab> pumvisible() ? coc#pum#next(1) : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? coc#pum#prev(1) : "\<C-h>"

" Trigger (reopen) CoC completion popup manually
inoremap <silent><expr> <C-Space> coc#refresh()

" Go to definition / type definition / implementation / references
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Rename symbol
nmap <leader>rn <Plug>(coc-rename)

" Code actions (quick fixes, imports)
nmap <leader>ca <Plug>(coc-codeaction)

" Hover documentation
nnoremap <silent> K :call CocActionAsync('doHover')<CR>

" Jump between diagnostics (errors/warnings)
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Format file or selection
command! -nargs=0 Format :call CocAction('format')

" =============================================================================
" OMNISHARP / C# DEVELOPMENT
" =============================================================================
let g:OmniSharp_server_use_net6 = 1

" Completion options (OmniSharp specific - extends CoC settings)
set completeopt+=popuphidden
set completepopup=highlight:Pmenu,border:off

" OmniSharp popup position
let g:OmniSharp_popup_position = 'peek'
if has('nvim')
  let g:OmniSharp_popup_options = {
  \ 'winblend': 30,
  \ 'winhl': 'Normal:Normal,FloatBorder:ModeMsg',
  \ 'border': 'rounded'
  \}
else
  let g:OmniSharp_popup_options = {
  \ 'highlight': 'Normal',
  \ 'padding': [0],
  \ 'border': [1],
  \ 'borderchars': ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
  \ 'borderhighlight': ['ModeMsg']
  \}
endif

let g:OmniSharp_popup_mappings = {
\ 'sigNext': '<C-n>',
\ 'sigPrev': '<C-p>',
\ 'pageDown': ['<C-f>', '<PageDown>'],
\ 'pageUp': ['<C-b>', '<PageUp>']
\}

if s:using_snippets
  let g:OmniSharp_want_snippet = 1
endif

let g:OmniSharp_highlight_groups = {
\ 'ExcludedCode': 'NonText'
\}

" Sharpenup: mappings begin with `<Space>os`, e.g. `<Space>osgd` for :OmniSharpGotoDefinition
let g:sharpenup_map_prefix = '<Space>os'
let g:sharpenup_statusline_opts = { 'Text': '%s (%p/%P)' }
let g:sharpenup_statusline_opts.Highlight = 0

" Asyncomplete
let g:asyncomplete_auto_popup = 1
let g:asyncomplete_auto_completeopt = 0

" =============================================================================
" ALE (LINTING)
" =============================================================================
let g:ale_sign_error = '•'
let g:ale_sign_warning = '•'
let g:ale_sign_info = '·'
let g:ale_sign_style_error = '·'
let g:ale_sign_style_warning = '·'

let g:ale_linters = { 'cs': ['OmniSharp'] }

" =============================================================================
" VIM-AIRLINE (STATUSBAR)
" =============================================================================
let g:airline_theme = 'codedark'

" =============================================================================
" VIMSPECTOR (DEBUGGING)
" =============================================================================
" Ensure Python3 support for Vimspector
if has('python3')
  let s:vimspector_python = expand('~/.vim/plugged/vimspector/python3')
  if isdirectory(s:vimspector_python)
    execute 'python3 import sys; sys.path.append(r"' . s:vimspector_python . '")'
  endif
endif

" Use Visual Studio-style keybindings (F5 to run, F9 to toggle breakpoint, etc.)
let g:vimspector_enable_mappings = 'VISUAL_STUDIO'

" =============================================================================
" VIM-DADBOD (DATABASE)
" =============================================================================
nnoremap <leader>db :DBUIToggle<CR>

let g:db_ui_save_location = expand('~/.db_ui_queries')
let g:db_ui_execute_on_save = 0

let g:dbs = {
\ 'local_mysql': 'mysql://root:BestRock1234@172.27.208.1',
\ 'local_sqlserver': 'sqlserver://sa:letmein@172.27.208.1/sqldb-jobtracker-dev-scus?encrypt=true&TrustServerCertificate=true',
\ 'azure_dev': 'sqlserver://<username>:<password>@sql-jobtracker-dev-southcentralus.database.windows.net/sqldb-jobtracker-dev-scus',
\ }

" Safety nets for Windows weirdness
autocmd FileType dbui setlocal modifiable
autocmd FileType dbout setlocal modifiable

" Disable folding in Dadbod query results
autocmd FileType dbout setlocal nofoldenable

" Add left border with pipe character for SQL Server results
function! s:AddLeftBorder()
  if &filetype !=# 'dbout'
    return
  endif
  if !exists('b:db') || b:db !~# 'sqlserver://'
    return
  endif
  setlocal modifiable
  silent! %s/^\(.\+\)$/| \1/e
  normal! gg
endfunction

autocmd BufReadPost,BufWritePost * if &filetype ==# 'dbout' | call s:AddLeftBorder() | endif

" =============================================================================
" NNN.VIM (FILE MANAGER)
" =============================================================================
nnoremap <leader>n :NnnPicker %:p:h<CR>

" Easy escape from terminal mode in nnn buffers
autocmd FileType nnn tnoremap <buffer> <Esc> <C-\><C-n>

" Quick command line access from nnn terminal
autocmd FileType nnn tnoremap <buffer> <C-o> <C-\><C-n>:

" =============================================================================
" MINIMAP
" =============================================================================
let g:minimap_width = 10
let g:minimap_auto_start = 0
let g:minimap_auto_start_win_enter = 1
let g:minimap_highlight_search = 1
let g:minimap_highlight_range = 1
let g:minimap_git_colors = 1

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

" Clear search highlights (minimap + vim)
nnoremap <silent> <leader>nh :nohlsearch<CR>:call minimap#vim#ClearColorSearch()<CR>

" =============================================================================
" CUSTOM COMMANDS & FUNCTIONS
" =============================================================================
" Split commands that move cursor to new window
command! -nargs=* Vs vsplit <args> | wincmd l
command! -nargs=* Sp split <args> | wincmd j
cabbrev vs Vs
cabbrev sp Sp

" -----------------------------------------------------------------------------
" Vim cd-on-quit functionality
" -----------------------------------------------------------------------------
" Opt-in commands to quit and cd to current directory in the terminal
let g:vim_cd_tmpfile = expand(empty($XDG_CONFIG_HOME) ? '$HOME/.config/vim/.lastd' : '$XDG_CONFIG_HOME/vim/.lastd')

" Ensure directory exists
call system('mkdir -p ' . shellescape(fnamemodify(g:vim_cd_tmpfile, ':h')))

" :Q - Quit and cd to current directory
command! Q call writefile(['cd ' . shellescape(getcwd())], g:vim_cd_tmpfile) | quit

" :Wq - Write, quit and cd to current directory
command! Wq write | call writefile(['cd ' . shellescape(getcwd())], g:vim_cd_tmpfile) | quit

" :WQ - Alias for :Wq (handle common typo)
command! WQ write | call writefile(['cd ' . shellescape(getcwd())], g:vim_cd_tmpfile) | quit
