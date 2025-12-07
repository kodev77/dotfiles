" =============================================================================
" GENERAL SETTINGS
" =============================================================================
let mapleader = " "
set nocompatible

" Windows compatibility (shellslash set after plug#end due to vim-plug incompatibility)
if has('win32') || has('win64')
  " Add ~/.vim to runtimepath (Windows Vim defaults to vimfiles, not .vim)
  set runtimepath^=~/.vim
  " OmniSharp server path for Windows
  let g:OmniSharp_server_path = 'C:/Tools/omnisharp-roslyn/OmniSharp.exe'
  " Ripgrep config path (to ignore bin/obj folders)
  let $RIPGREP_CONFIG_PATH = expand('~/.ripgreprc')
  " Use ripgrep for fzf :Files command (respects .ripgreprc)
  let $FZF_DEFAULT_COMMAND = 'rg --files'
endif
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
set ignorecase
set smartcase

" Windows/buffers
set hidden
set nofixendofline
set nostartofline
set splitbelow
set splitright

" Misc
set mouse=a
set clipboard=unnamed,unnamedplus
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

call plug#begin('~/.vim/plugged')

" File explorer (vim-fern)
Plug 'lambdalisue/vim-fern'
Plug 'lambdalisue/vim-fern-git-status'
Plug 'lambdalisue/vim-fern-hijack'

" Nerd Font support for fern
Plug 'lambdalisue/vim-nerdfont'
Plug 'lambdalisue/vim-fern-renderer-nerdfont'
Plug 'lambdalisue/glyph-palette.vim'

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
Plug 'airblade/vim-gitgutter'

" C# / OmniSharp
Plug 'OmniSharp/omnisharp-vim'
Plug 'nickspoons/vim-sharpenup'

" Linting
Plug 'dense-analysis/ale'

" FZF (used as OmniSharp selector)
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" FZF layout: use true buffer instead of popup
let g:fzf_layout = { 'window': 'enew' }

" FZF options: clean up UI and add keybindings
let $FZF_DEFAULT_OPTS = '--no-separator --pointer=">" --marker=">" --no-scrollbar --multi --bind=ctrl-a:select-all,ctrl-d:deselect-all'

" FZF selected line highlight (VS Code blue)
highlight FzfSelected guibg=#0A7ACA guifg=#FFFFFF ctermbg=32 ctermfg=White

" FZF colors: match codedark colorscheme
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'FzfSelected'],
  \ 'bg+':     ['bg', 'FzfSelected'],
  \ 'gutter':  ['bg', 'Normal'],
  \ 'hl+':     ['fg', 'Keyword'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'VertSplit'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Keyword'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Comment'],
  \ 'header':  ['fg', 'Comment'] }

" Async completion (for OmniSharp)
Plug 'prabirshrestha/asyncomplete.vim'

" Colorschemes
Plug 'gruvbox-community/gruvbox'
Plug 'tomasiser/vim-code-dark'

" Utilities
Plug 'godlygeek/tabular'
Plug 'tpope/vim-vinegar'

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
let g:OmniSharp_start_server = 1
let g:OmniSharp_highlighting = 3
let g:OmniSharp_diagnostic_enable = 1
let g:OmniSharp_diagnostic_show_symbol = 1
let g:OmniSharp_selector_ui = 'fzf'

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

" C# file settings
autocmd FileType cs setlocal omnifunc=OmniSharp#Complete
autocmd FileType cs setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab
autocmd BufWritePre *.cs OmniSharpCodeFormat

" C#-specific keymaps (buffer-local to avoid conflicts with CoC)
augroup omnisharp_maps
  autocmd!
  autocmd FileType cs nnoremap <buffer> gd :OmniSharpGotoDefinition<CR>
  autocmd FileType cs nnoremap <buffer> gi :OmniSharpFindImplementations<CR>
  autocmd FileType cs nnoremap <buffer> gr :OmniSharpFindUsages<CR>
  autocmd FileType cs nnoremap <buffer> pi :OmniSharpPreviewImplementation<CR>
  autocmd FileType cs nnoremap <buffer> <leader>rn :OmniSharpRename<CR>
  autocmd FileType cs nnoremap <buffer> <leader>ca :OmniSharpCodeActions<CR>
  autocmd FileType cs nnoremap <buffer> <leader>fm :OmniSharpCodeFormat<CR>
  autocmd FileType cs nnoremap <buffer> K :OmniSharpDocumentation<CR>
  autocmd FileType cs nnoremap <buffer> <leader>os :OmniSharpStatus<CR>
augroup END

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
" VIM-GITGUTTER (GIT DIFF SIGNS)
" =============================================================================
let g:gitgutter_sign_added = '│'
let g:gitgutter_sign_modified = '│'
let g:gitgutter_sign_removed = '_'
let g:gitgutter_sign_removed_first_line = '‾'
let g:gitgutter_sign_modified_removed = '~'

" Toggle gitgutter
nnoremap <leader>gd :GitGutterToggle<CR>

" Navigate between hunks
nmap ]h <Plug>(GitGutterNextHunk)
nmap [h <Plug>(GitGutterPrevHunk)

" Hunk operations
nmap <leader>hp <Plug>(GitGutterPreviewHunk)
nmap <leader>hs <Plug>(GitGutterStageHunk)
nmap <leader>hu <Plug>(GitGutterUndoHunk)

" =============================================================================
" VIM-AIRLINE (STATUSBAR)
" =============================================================================
let g:airline_theme = 'codedark'

" =============================================================================
" CUSTOM TABLINE WITH TAB NAMING
" =============================================================================
" Command to rename current tab
command! -nargs=1 TabName let t:tab_name = <q-args> | redrawtabline
" Command to clear tab name
command! TabNameClear unlet! t:tab_name

function! MyTabLine()
  let s = ''
  for i in range(tabpagenr('$'))
    let tabnr = i + 1
    let s .= '%' . tabnr . 'T'
    let s .= (tabnr == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#')
    " Get custom name or fall back to filename
    let buflist = tabpagebuflist(tabnr)
    let winnr = tabpagewinnr(tabnr)
    let name = gettabvar(tabnr, 'tab_name', fnamemodify(bufname(buflist[winnr - 1]), ':t'))
    if name == ''
      let name = '[No Name]'
    endif
    let s .= ' ' . tabnr . ':' . name . ' '
  endfor
  let s .= '%#TabLineFill#%T'
  return s
endfunction

set showtabline=1
set tabline=%!MyTabLine()

" Tabline colors
hi TabLineSel guibg=#0A7ACA guifg=#FFFFFF ctermbg=32 ctermfg=White

" Tab keybindings
nnoremap tt :tabnew<CR>
nnoremap tr :TabName<Space>

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

" Attach to running .NET process by name
function! AttachToDotnetProcess(process_name)
  " Use PowerShell to get full process name (tasklist truncates to 25 chars)
  let l:cmd = 'powershell -NoProfile -Command "Get-Process -Name ''' . a:process_name . ''' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Id"'
  let l:output = system(l:cmd)
  let l:pid = str2nr(substitute(l:output, '\n\|\r', '', 'g'))

  if l:pid == 0
    echo "Could not find process: " . a:process_name
    return
  endif

  echo "Attaching to " . a:process_name . " (PID: " . l:pid . ")"
  call vimspector#LaunchWithConfigurations({
    \ "attach": {
    \   "adapter": "netcoredbg",
    \   "configuration": {
    \     "request": "attach",
    \     "processId": l:pid
    \   }
    \ }
  \ })
endfunction

" Find .vimspector.json by searching upward from current file or cwd
function! FindVimspectorFile()
  let l:dir = expand('%:p:h')
  if l:dir == ''
    let l:dir = getcwd()
  endif

  " Search upward for .vimspector.json
  while l:dir != '' && l:dir != '/'
    let l:file = l:dir . '/.vimspector.json'
    if filereadable(l:file)
      return l:file
    endif
    " Go to parent directory
    let l:parent = fnamemodify(l:dir, ':h')
    if l:parent == l:dir
      break
    endif
    let l:dir = l:parent
  endwhile

  return ''
endfunction

" Attach to .NET process using name from .vimspector.json
function! AttachToDotnetFromVimspector()
  let l:vimspector_file = FindVimspectorFile()
  if l:vimspector_file == ''
    echo "No .vimspector.json found in current directory or parents"
    return
  endif

  " Read and parse JSON
  let l:json = join(readfile(l:vimspector_file), '')
  let l:config = json_decode(l:json)

  " Get processName from attach configuration
  if !has_key(l:config, 'configurations') || !has_key(l:config.configurations, 'attach')
    echo "No 'attach' configuration found in .vimspector.json"
    return
  endif

  let l:attach = l:config.configurations.attach
  if !has_key(l:attach, 'processName')
    echo "No 'processName' field in attach configuration"
    return
  endif

  let l:process_name = l:attach.processName
  echo "Found " . l:vimspector_file
  call AttachToDotnetProcess(l:process_name)
endfunction

command! -nargs=1 AttachDotnet call AttachToDotnetProcess(<q-args>)
command! AttachDotnetAuto call AttachToDotnetFromVimspector()

" =============================================================================
" VIM-DADBOD (DATABASE)
" =============================================================================
nnoremap <leader>db :DBUIToggle<CR>

let g:db_ui_save_location = expand('~/.db_ui_queries')
let g:db_ui_execute_on_save = 0

let g:dbs = {
\ 'local_mysql': 'mysql://root:BestRock1234@localhost',
\ 'RPC_PI5_mysql': 'mysql://root:BestRock1234@192.168.254.115:3306',
\ 'aspire_mysql': 'mysql://root:BestRock1234@localhost:3307',
\ 'local_sqlserver': 'sqlserver://sa:letmein@KORTEGO-ROG-001/sqldb-jobtracker-dev-scus',
\ 'azure_dev': 'sqlserver://jtadmin:6PWXQFTFkDWbQJ@sql-jobtracker-dev-southcentralus.database.windows.net/sqldb-jobtracker-dev-scus',
\ }

" Safety nets for Windows weirdness
autocmd FileType dbui setlocal modifiable
autocmd FileType dbout setlocal modifiable

" Disable folding in Dadbod query results
autocmd FileType dbout setlocal nofoldenable

" =============================================================================
" VIM-FERN (FILE EXPLORER)
" =============================================================================
let g:fern#drawer_width = 30
let g:fern#default_hidden = 1
" let g:fern#renderer = "nerdfont"

" Clean tree display (remove |, +, - characters)
let g:fern#renderer#default#leading = '  '
let g:fern#renderer#default#leaf_symbol = '  '
let g:fern#renderer#default#collapsed_symbol = '▸ '
let g:fern#renderer#default#expanded_symbol = '▾ '
let g:fern#renderer#default#root_symbol = '~ '

" Highlight Fern header (root directory) in gold
highlight FernRootSymbol guifg=#FFAF00 ctermfg=214
highlight FernRootText guifg=#FFAF00 ctermfg=214

" Fern settings (vim-fern-hijack handles directory opening automatically)
let g:fern#disable_drawer_hover_popup = 1

" Toggle fern drawer at current file's directory (falls back to cwd if no file)
nnoremap <silent> <leader>n :execute 'Fern ' . fnameescape(expand('%:p:h') != '' ? expand('%:p:h') : getcwd()) . ' -drawer -toggle -reveal=%'<CR>

" Open fern in current window (split mode)
nnoremap <silent> <leader>N :execute 'Fern ' . fnameescape(expand('%:p:h') != '' ? expand('%:p:h') : getcwd()) . ' -reveal=%'<CR>

" Custom fern buffer mappings
function! s:init_fern() abort
  " Navigation
  nmap <buffer><expr> <CR> fern#smart#leaf(
        \ "\<Plug>(fern-action-open)",
        \ "\<Plug>(fern-action-enter)",
        \ )
  nmap <buffer> - <Plug>(fern-action-leave)
  nmap <buffer> l <Plug>(fern-action-expand)
  nmap <buffer> h <Plug>(fern-action-collapse)

  " File operations
  nmap <buffer> e <Plug>(fern-action-open)
  nmap <buffer> s <Plug>(fern-action-open:split)
  nmap <buffer> v <Plug>(fern-action-open:vsplit)
  nmap <buffer> t <Plug>(fern-action-open:tabedit)

  " File management
  nmap <buffer> N <Plug>(fern-action-new-file)
  nmap <buffer> K <Plug>(fern-action-new-dir)
  nmap <buffer> R <Plug>(fern-action-rename)
  nmap <buffer> D <Plug>(fern-action-remove)
  nmap <buffer> c <Plug>(fern-action-clipboard-copy)
  nmap <buffer> x <Plug>(fern-action-clipboard-move)
  nmap <buffer> p <Plug>(fern-action-clipboard-paste)

  " Mark operations
  nmap <buffer> m <Plug>(fern-action-mark:toggle)
  nmap <buffer> <Space>m <Plug>(fern-action-mark:clear)

  " Utility
  nmap <buffer> r <Plug>(fern-action-reload)
  nmap <buffer> . <Plug>(fern-action-hidden:toggle)
  nmap <buffer> y <Plug>(fern-action-yank:path)
  nmap <buffer> ? <Plug>(fern-action-help)
endfunction

augroup fern-custom
  autocmd!
  autocmd FileType fern call s:init_fern()
augroup END

" Apply glyph palette colors for file icons
augroup fern-glyph-palette
  autocmd!
  autocmd FileType fern call glyph_palette#apply()
augroup END

" Disable CoC for fern buffers
augroup FernCocFix
  autocmd!
  autocmd FileType fern let b:coc_enabled = 0
augroup END

" Override :Ex to use Fern instead of netrw
function! s:FernEx(dir) abort
  let l:dir = a:dir
  if l:dir ==# ''
    let l:dir = expand('%:p:h')
  endif
  if l:dir ==# ''
    let l:dir = getcwd()
  endif
  execute 'Fern ' . fnameescape(l:dir) . ' -reveal=%'
endfunction
command! -nargs=? -complete=dir Ex call s:FernEx(<q-args>)

" Clear search highlights
nnoremap <silent> <leader>nh :nohlsearch<CR>

" =============================================================================
" QUICKFIX WINDOW (VS Code-style left panel)
" =============================================================================
" Open quickfix vertically on the left
augroup QuickfixPosition
  autocmd!
  autocmd FileType qf wincmd H | vertical resize 50
augroup END

" Open quickfix entries in right split (keep quickfix open)
autocmd FileType qf nnoremap <buffer> <CR> <CR>:copen<CR>:wincmd H<CR>:vertical resize 50<CR>:wincmd l<CR>

" Toggle quickfix window
nnoremap <silent> <leader>q :call ToggleQuickfix()<CR>
function! ToggleQuickfix()
  if getqflist({'winid': 0}).winid
    cclose
  else
    copen
  endif
endfunction

" =============================================================================
" CUSTOM COMMANDS & FUNCTIONS
" =============================================================================
" Split commands that move cursor to new window
command! -nargs=* Vs vsplit <args> | wincmd l
command! -nargs=* Sp split <args> | wincmd j
cabbrev vs Vs
cabbrev sp Sp

" Toggle invisibles with F2
nnoremap <F2> :set list!<CR>

" Use Ctrl-C in visual mode to copy to system clipboard
vnoremap <C-c> "+y

" Ctrl-V paste from system clipboard (all modes)
nnoremap <C-v> "+p
vnoremap <C-v> "+p
inoremap <C-v> <C-r>+
cnoremap <C-v> <C-r>+

" -----------------------------------------------------------------------------
" Vim cd-on-quit functionality
" -----------------------------------------------------------------------------
" Opt-in commands to quit and cd to current directory in the terminal
if has('win32') || has('win64')
  let g:vim_cd_tmpfile = expand('~/.vim/lastdir')
else
  let g:vim_cd_tmpfile = expand(empty($XDG_CONFIG_HOME) ? '$HOME/.config/vim/.lastd' : '$XDG_CONFIG_HOME/vim/.lastd')
  " Ensure directory exists (Unix only)
  call system('mkdir -p ' . shellescape(fnamemodify(g:vim_cd_tmpfile, ':h')))
endif

" :Q - Quit and cd to current directory
command! Q call writefile([getcwd()], g:vim_cd_tmpfile) | quit

" :Wq - Write, quit and cd to current directory
command! Wq write | call writefile([getcwd()], g:vim_cd_tmpfile) | quit

" :WQ - Alias for :Wq (handle common typo)
command! WQ write | call writefile([getcwd()], g:vim_cd_tmpfile) | quit
