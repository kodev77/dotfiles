call plug#begin('~/.vim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'lambdalisue/fern.vim'
Plug 'lambdalisue/nerdfont.vim'
Plug 'lambdalisue/fern-renderer-nerdfont.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'tpope/vim-dadbod'
Plug 'kristijanhusak/vim-dadbod-ui'
Plug 'kristijanhusak/vim-dadbod-completion'
Plug 'OrangeT/vim-csharp'
Plug 'puremourning/vimspector'

call plug#end()

" coc.nvim extensions (auto-installed on startup)
let g:coc_global_extensions = ['coc-json', 'coc-tsserver', 'coc-sql', 'coc-sqlfluff', '@yaegassy/coc-csharp-ls']

" coc.nvim settings
" Use tab for trigger completion with characters ahead and navigate
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
      \ : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion
inoremap <silent><expr> <c-space> coc#refresh()

" Navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Show documentation in preview window
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Symbol renaming
nmap <leader>rn <Plug>(coc-rename)

" Code actions
nmap <leader>ca <Plug>(coc-codeaction-cursor)
xmap <leader>ca <Plug>(coc-codeaction-selected)

" vim-dadbod-ui settings
let g:db_ui_use_nerd_fonts = 1
let g:db_ui_show_database_icon = 1
let g:db_ui_win_position = 'left'
let g:db_ui_winwidth = 40

" Execute query with ROW_COUNT() appended for MySQL UPDATE/DELETE/INSERT
function! ExecuteDBQuery(query) abort
  let l:query = trim(a:query)
  if empty(l:query)
    return
  endif

  " Get current DB connection
  let l:db = get(b:, 'db', get(g:, 'db', ''))
  let l:is_mysql = l:db =~? '^mysql:'

  " Check if it's a modifying query (UPDATE/DELETE/INSERT)
  let l:is_modify = l:query =~? '\v^\s*(UPDATE|DELETE|INSERT)\s'

  " For MySQL modifying queries, append ROW_COUNT() to get affected rows
  if l:is_mysql && l:is_modify
    " Remove trailing semicolon if present, then add our appended query
    let l:query = substitute(l:query, '\s*;\s*$', '', '')
    let l:query = l:query . "; SELECT ROW_COUNT() as rows_affected;"
  endif

  execute 'DB ' . l:query
endfunction

let g:db_ui_save_location = expand('~/.local/share/db_ui')
let g:db_ui_execute_on_save = 0

" Grab text from visible popup and put in clipboard
function! CopyPopupContent()
  let popups = popup_list()
  if empty(popups)
    echo "No popups visible"
    return
  endif
  for id in popups
    let lines = getbufline(winbufnr(id), 1, '$')
    if !empty(lines)
      let @+ = join(lines, "\n")
      echo "Copied " . len(lines) . " lines to clipboard"
      return
    endif
  endfor
endfunction

" Select database connection using fzf (reads from dadbod-ui saved connections)
function! DBSelectConnection()
  let l:save_loc = get(g:, 'db_ui_save_location', expand('~/.local/share/db_ui'))
  let l:conn_file = l:save_loc . '/connections.json'

  if !filereadable(l:conn_file)
    echo "No saved connections found at " . l:conn_file
    return
  endif

  let l:json = join(readfile(l:conn_file), '')
  let l:connections = json_decode(l:json)

  if empty(l:connections)
    echo "No connections configured"
    return
  endif

  " Build list of connection names and store URLs
  let s:db_urls = {}
  for conn in l:connections
    let l:name = get(conn, 'name', '')
    let l:url = get(conn, 'url', '')
    if !empty(l:name) && !empty(l:url)
      let s:db_urls[l:name] = l:url
    endif
  endfor

  call fzf#run(fzf#wrap({
    \ 'source': keys(s:db_urls),
    \ 'sink': function('s:set_db_connection'),
    \ 'options': '--prompt="Select DB> "'
  \ }))
endfunction

function! s:set_db_connection(name)
  let b:db = s:db_urls[a:name]
  echo "Connected to: " . a:name
endfunction

command! DBSelect call DBSelectConnection()

" dadbod-completion setup
autocmd FileType sql,mysql,plsql,typescript setlocal omnifunc=vim_dadbod_completion#omni
autocmd FileType dbui nmap <buffer> o <Plug>(DBUI_SelectLine)

" Custom SQL output formatter (autoload/dadbod_format.vim)
augroup dadbod_format
  autocmd!
  autocmd FileType dbui setlocal modifiable
  autocmd FileType dbout setlocal modifiable
  autocmd FileType dbout setlocal nofoldenable
  autocmd FileType dbout call dadbod_format#auto_format()
  autocmd BufEnter * if &filetype ==# 'dbout' && !get(b:, 'dbout_is_formatted', 0) | call dadbod_format#format() | endif
  autocmd FileType dbout nnoremap <buffer> <CR> :call dadbod_format#expand_cell()<CR>
  autocmd FileType dbout nnoremap <buffer> <leader>fr :call dadbod_format#toggle_raw()<CR>
  autocmd FileType dbout nnoremap <buffer> q :call dadbod_format#close_expand()<CR>
augroup END

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
command! Ex Fern %:h -reveal=%
command! Explore Fern %:h -reveal=%
command! Vex vsplit | Fern %:h -reveal=%
command! Sex split | Fern %:h -reveal=%

" fern custom keybindings
let g:fern#default_hidden = 1
let g:fern#renderer#nerdfont#indent_markers = 1
let g:fern#renderer#nerdfont#root_symbol = "\uf07c  "


function! s:fern_rename_prompt() abort
  let helper = fern#helper#new()
  let node = helper.sync.get_cursor_node()
  let old_path = node._path
  let old_name = fnamemodify(old_path, ':t')
  let dir = fnamemodify(old_path, ':h')
  let new_name = input('Rename: ', old_name)
  if new_name != '' && new_name != old_name
    let new_path = dir . '/' . new_name
    call rename(old_path, new_path)
    call fern#action#call('reload:all')
  endif
endfunction

function! s:fern_init() abort
  setlocal nonumber signcolumn=no
  nmap <buffer> <CR> <Plug>(fern-action-open-or-enter)
  nmap <buffer> o <Plug>(fern-action-open)
  nmap <buffer> l <Plug>(fern-action-expand)
  nmap <buffer> h <Plug>(fern-action-collapse)
  nmap <buffer> - <Plug>(fern-action-leave)
  nmap <buffer> m <Plug>(fern-action-mark:toggle)
  nmap <buffer> D <Plug>(fern-action-remove)
  nmap <buffer> R :call <SID>fern_rename_prompt()<CR>
endfunction

augroup fern-custom
  autocmd!
  autocmd FileType fern call s:fern_init()
augroup END

" colorscheme
set background=dark
colorscheme koehler

" Dbout syntax highlighting (for dadbod_format.vim)
highlight link DboutBorder Normal
highlight DboutHeader ctermfg=White cterm=bold guifg=fg gui=bold
highlight link DboutString Include
highlight link DboutNumber Statement
highlight link DboutGuid Type
highlight link DboutTimestamp Function
highlight link DboutTruncated Directory
highlight link DboutNull Comment
highlight link DboutRowCount Comment

" retro tab colors (orange theme)
hi TabLineSel  ctermfg=232 ctermbg=208  cterm=bold guifg=#000000 guibg=#ff8800 gui=bold
hi TabLine     ctermfg=232 ctermbg=208  cterm=none guifg=#000000 guibg=#ff8800 gui=none
hi TabLineFill ctermfg=NONE ctermbg=208 cterm=none guifg=#000000 guibg=#ff8800 gui=none

" fern root styling
hi FernRootSymbol ctermfg=51 guifg=#00ffff cterm=bold gui=bold
hi FernRootText ctermfg=51 guifg=#00ffff cterm=bold gui=bold



" leader key
let mapleader = " "

" vimspector settings
" Additional vimspector keybindings (avoid F10/F11/F12 terminal conflicts)
nmap <leader>vl :call vimspector#Launch()<CR>
nmap <leader>vr :VimspectorReset<CR>
nmap <leader>vc :call vimspector#Continue()<CR>
nmap <leader>vs :VimspectorStop<CR>
nmap <leader>vR :VimspectorRestart<CR>
nmap <leader>vp :VimspectorPause<CR>
nmap <leader>vb :call vimspector#ToggleBreakpoint()<CR>
nmap <leader>vB :call vimspector#ToggleConditionalBreakpoint()<CR>
nmap <leader>vi :VimspectorBalloonEval<CR>
xmap <leader>vi :VimspectorBalloonEval<CR>
nmap <leader>vo :call vimspector#StepOver()<CR>
nmap <leader>vn :call vimspector#StepInto()<CR>
nmap <leader>vu :call vimspector#StepOut()<CR>

" dadbod keybindings
nnoremap <leader>db :DBUIToggle<CR>
nnoremap <leader>df :DBUIFindBuffer<CR>
nnoremap <leader>dl :DBUILastQueryInfo<CR>
nnoremap <leader>ds :DBSelect<CR>
nnoremap <leader>dF :call dadbod_format#format_from_anywhere()<CR>
nnoremap <leader>r :call ExecuteDBQuery(getline('.'))<CR>
vnoremap <leader>r "ry:call ExecuteDBQuery(@r)<CR>
nnoremap <leader>cp :call CopyPopupContent()<CR>

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
nnoremap <leader>E :Fern %:h -reveal=%<CR>

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
