"==============================================================================
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

" Disable swap files (prevents .swp clutter and recovery prompts)
set noswapfile

set encoding=utf-8
scriptencoding utf-8

" Visual settings
set number
set showcmd
set scrolloff=10
set title
set signcolumn=auto
set nowrap
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
let g:netrw_browse_split = 0
let g:netrw_nogx = 1

" Fix gx to use Windows default file associations
function! OpenWithDefault()
  if &filetype == 'netrw'
    let file = b:netrw_curdir . '/' . netrw#Call('NetrwGetWord')
  else
    let file = expand('<cfile>:p')
  endif
  " Normalize to backslashes for Windows
  let file = substitute(file, '/', '\', 'g')
  call system('explorer "' . file . '"')
endfunction
nnoremap <silent> gx :call OpenWithDefault()<CR>

" Netrw: <leader>e opens file in main buffer (window 2)
function! NetrwOpenInMainBuffer()
  let curfile = b:netrw_curdir . '/' . netrw#Call('NetrwGetWord')
  " Go to window 2 (first window right of Netrw)
  2wincmd w
  execute 'edit ' . fnameescape(curfile)
endfunction

augroup netrw_mappings
  autocmd!
  autocmd FileType netrw nmap <buffer> <leader>e :call NetrwOpenInMainBuffer()<CR>
augroup END

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

" FZF colors: use Vim highlight groups
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine'],
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
" (using default Vim colorscheme)

" Utilities
Plug 'godlygeek/tabular'
Plug 'vifm/vifm.vim'

" Statusline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Snippets (conditional)
if s:using_snippets
  Plug 'sirver/ultisnips'
endif

call plug#end()

" Set colorscheme
colorscheme koehler

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
" Disable default mappings (we define our own below)
let g:gitgutter_map_keys = 0

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

" Hunk operations (Capital H to avoid conflict with window navigation)
nmap <leader>Hp <Plug>(GitGutterPreviewHunk)
nmap <leader>Hs <Plug>(GitGutterStageHunk)
nmap <leader>Hu <Plug>(GitGutterUndoHunk)

" =============================================================================
" WINDOW NAVIGATION (Leader + HJKL)
" =============================================================================
nnoremap <leader>h <C-w>h
nnoremap <leader>j <C-w>j
nnoremap <leader>k <C-w>k
nnoremap <leader>l <C-w>l

" Leader+W as Ctrl-W prefix for all window commands
nnoremap <leader>w <C-w>

" =============================================================================
" VIM-AIRLINE (STATUSBAR)
" =============================================================================
" Using default airline theme

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

" Tab keybindings
nnoremap <leader>tt :tabnew<CR>
nnoremap <leader>tr :TabName<Space>
nnoremap <leader>tc :tabclose<CR>

" Tab navigation: <leader>{n} for direct tab access
nnoremap <leader>1 1gt
nnoremap <leader>2 2gt
nnoremap <leader>3 3gt
nnoremap <leader>4 4gt
nnoremap <leader>5 5gt
nnoremap <leader>6 6gt
nnoremap <leader>7 7gt
nnoremap <leader>8 8gt
nnoremap <leader>9 9gt

" Terminal mode: same mappings
tnoremap <leader>gt <C-\><C-n>gt
tnoremap <leader>gT <C-\><C-n>gT
tnoremap <leader>1 <C-\><C-n>1gt
tnoremap <leader>2 <C-\><C-n>2gt
tnoremap <leader>3 <C-\><C-n>3gt
tnoremap <leader>4 <C-\><C-n>4gt
tnoremap <leader>5 <C-\><C-n>5gt
tnoremap <leader>6 <C-\><C-n>6gt
tnoremap <leader>7 <C-\><C-n>7gt
tnoremap <leader>8 <C-\><C-n>8gt
tnoremap <leader>9 <C-\><C-n>9gt

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
vnoremap <leader>r :DB<CR>

let g:db_ui_save_location = expand('~/.db_ui_queries')
let g:db_ui_execute_on_save = 0

let g:dbs = {
\ 'local_mysql': 'mysql://root:BestRock1234@localhost/sqldb-jobtracker-dev-scus',
\ 'RPC_PI5_mysql': 'mysql://root:BestRock1234@192.168.254.115:3306',
\ 'aspire_mysql': 'mysql://root:BestRock1234@localhost:3307/sqldb-jobtracker-dev-scus',
\ 'local_sqlserver': 'sqlserver://sa:letmein@KORTEGO-ROG-001/sqldb-jobtracker-dev-scus',
\ 'azure_dev': 'sqlserver://jtadmin:6PWXQFTFkDWbQJ@sql-jobtracker-dev-southcentralus.database.windows.net/sqldb-jobtracker-dev-scus',
\ }

" Safety nets for Windows weirdness
autocmd FileType dbui setlocal modifiable
autocmd FileType dbout setlocal modifiable

" Disable folding in Dadbod query results
autocmd FileType dbout setlocal nofoldenable

" Dbout syntax highlighting (linked to colorscheme groups)
highlight link DboutString Include  " Purple/Magenta 
highlight link DboutNumber Statement      " Yellow
highlight link DboutGuid Type             " Green
highlight link DboutTimestamp Function    " Cyan
highlight link DboutTruncated Directory   " Dark Orange
highlight link DboutNull Comment          " Red

" Custom SQL output formatter (functions in autoload/dadbod_format.vim)
augroup dadbod_format
  autocmd!
  " Auto-format when filetype is set to dbout (uses polling to wait for content)
  autocmd FileType dbout call dadbod_format#auto_format()
  " Backup: format on BufEnter if not yet formatted
  autocmd BufEnter * if &filetype ==# 'dbout' && !get(b:, 'dbout_is_formatted', 0) | call dadbod_format#format() | endif
  " Manual format keybinding - works from any window
  nnoremap <leader>df :call dadbod_format#format_from_anywhere()<CR>
  autocmd FileType dbout nnoremap <buffer> <CR> :call dadbod_format#expand_cell()<CR>
  autocmd FileType dbout nnoremap <buffer> <leader>fr :call dadbod_format#toggle_raw()<CR>
  autocmd FileType dbout nnoremap <buffer> q :call dadbod_format#close_expand()<CR>
augroup END

" Select database connection using fzf
function! DBSelectConnection()
  let l:dbs = keys(g:dbs)
  call fzf#run(fzf#wrap({
    \ 'source': l:dbs,
    \ 'sink': {name -> execute('let b:db = g:dbs["' . name . '"] | echo "Connected to: ' . name . '"')},
    \ 'options': '--prompt="Select DB> "'
  \ }))
endfunction

command! DBSelect call DBSelectConnection()
nnoremap <leader>ds :DBSelect<CR>

" Clear search highlights
nnoremap <silent> <leader>nh :nohlsearch<CR>

" -----------------------------------------------------------------------------
" Black hole delete mappings (preserves clipboard)
" -----------------------------------------------------------------------------
" Use <leader>d to delete without affecting clipboard/registers
nnoremap <leader>d "_d
nnoremap <leader>dd "_dd
nnoremap <leader>D "_D
vnoremap <leader>d "_d
xnoremap <leader>d "_d

" Use <leader>p to paste from system clipboard (ignores Vim registers)
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
xnoremap <leader>p "+p

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

" Resize current window to 80% of screen width (useful for netrw)
nnoremap <leader>vr :execute 'vertical resize ' . float2nr(&columns * 0.8)<CR>

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
