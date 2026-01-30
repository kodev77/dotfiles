" vim-dadbod configuration

" UI settings
let g:db_ui_use_nerd_fonts = 1
let g:db_ui_show_database_icon = 1
let g:db_ui_win_position = 'left'
let g:db_ui_winwidth = 40
let g:db_ui_save_location = expand('~/.local/share/db_ui')
let g:db_ui_execute_on_save = 0

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

" Completion setup
autocmd FileType sql,mysql,plsql,typescript setlocal omnifunc=vim_dadbod_completion#omni
autocmd FileType dbui nmap <buffer> o <Plug>(DBUI_SelectLine)

" Syntax highlighting for dbout
highlight link DboutBorder Normal
highlight DboutHeader ctermfg=White cterm=bold guifg=fg gui=bold
highlight link DboutString Include
highlight link DboutNumber Statement
highlight link DboutGuid Type
highlight link DboutTimestamp Function
highlight link DboutTruncated Directory
highlight link DboutNull Comment
highlight link DboutRowCount Comment

" Keybindings
nnoremap <leader>db :DBUIToggle<CR>
nnoremap <leader>df :DBUIFindBuffer<CR>
nnoremap <leader>dl :DBUILastQueryInfo<CR>
nnoremap <leader>ds :DBSelect<CR>
nnoremap <leader>r :call ExecuteDBQuery(getline('.'))<CR>
vnoremap <leader>r "ry:call ExecuteDBQuery(@r)<CR>
nnoremap <leader>cp :call CopyPopupContent()<CR>
