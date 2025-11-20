nnoremap <leader>db :DBUIToggle<CR>

let g:db_ui_save_location = expand('~/.db_ui_queries')
let g:db_ui_execute_on_save = 0

let g:dbs = {
\ 'local_mysql': 'mysql://root:BestRock1234@localhost',
\ 'local_sqlserver': 'sqlserver://sa:letmein@172.27.208.1/sqldb-jobtracker-dev-scus?encrypt=true&TrustServerCertificate=true',
\ 'azure_dev': 'sqlserver://<username>:<password>@sql-jobtracker-dev-southcentralus.database.windows.net/sqldb-jobtracker-dev-scus',
\ }

" Safety nets for Windows weirdness
autocmd FileType dbui setlocal modifiable
autocmd FileType dbout setlocal modifiable

" Disable folding in Dadbod query results
autocmd FileType dbout setlocal nofoldenable

" Not working right now, maybe I need to install the nerd fonts in Windows first??
" let g:db_ui_use_nerd_fonts = 1

" Add left border with pipe character for SQL Server results
function! s:AddLeftBorder()
  " Only process if this is a dbout buffer
  if &filetype !=# 'dbout'
    return
  endif

  " Check if we're connected to a SQL Server database
  if !exists('b:db') || b:db !~# 'sqlserver://'
    return
  endif

  " Make buffer modifiable
  setlocal modifiable

  " Add '| ' to the beginning of each non-empty line
  silent! %s/^\(.\+\)$/| \1/e

  " Return to top of buffer
  normal! gg

  " Make buffer read-only again (optional)
  " setlocal nomodifiable
endfunction

" Trigger the left border formatting after query results are loaded
autocmd BufReadPost,BufWritePost * if &filetype ==# 'dbout' | call s:AddLeftBorder() | endif
