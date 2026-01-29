" db2.vim - a vim password manager
" usage: :Db2 or <leader>d2 to open, or :Db2 /path/to/data.json
"
" configuration:
"   set g:db2_path in your vimrc to specify your data file location:
"     let g:db2_path = '~/path/to/your/passwords.json'
"
"   default: ~/Documents/db2.json
"
" note: your data file (db2.json) contains sensitive passwords.
"       do NOT commit it to version control. add it to .gitignore.
"
" keybindings:
"   j/k       move up/down
"   gg/G      top/bottom
"   Enter/l   select entry
"   h         back to list
"   y         yank password
"   Y         yank username
"   s         show/hide password
"   a         add new entry
"   A         add additional entry
"   dd        delete entry
"   e         edit field
"   /         search
"   Esc       clear search
"   q         close
"   ?         help

if exists('g:loaded_db2')
  finish
endif
let g:loaded_db2 = 1

" default db2 path (same directory as plugin or specify with g:db2_path)
if !exists('g:db2_path')
  let g:db2_path = expand('~/Documents/db2.json')
endif

" store db2 data
let s:db2_entries = []
let s:current_entry = {}
let s:current_entry_index = -1
let s:list_bufnr = -1
let s:detail_bufnr = -1
let s:notes_expanded = 0
let s:additional_expanded = 0
let s:notes_line = 0
let s:additional_line = 0
let s:db2_file_path = ''
let s:field_lines = {}
let s:additional_entry_lines = {}
let s:additional_field_lines = {}
let s:edit_additional_index = -1

" main command
command! -nargs=? Db2 call s:Db2Open(<q-args>)
nnoremap <leader>d2 :Db2<CR>

function! s:Db2Open(path) abort
  let l:path = empty(a:path) ? g:db2_path : a:path

  if !filereadable(l:path)
    echohl ErrorMsg
    echo 'db2: file not found: ' . l:path
    echohl None
    return
  endif

  " load json data
  try
    let l:content = join(readfile(l:path), "\n")
    let s:db2_entries = json_decode(l:content)
    let s:db2_file_path = l:path
  catch
    echohl ErrorMsg
    echo 'db2: failed to parse json'
    echohl None
    return
  endtry

  " create layout
  call s:CreateLayout()
endfunction

function! s:CreateLayout() abort
  " close existing db2 buffers
  call s:CloseDb2()

  " use current window for list buffer
  enew
  let s:list_bufnr = bufnr('%')
  call s:SetupListBuffer()

  " create detail buffer on right
  vnew
  let s:detail_bufnr = bufnr('%')
  call s:SetupDetailBuffer()

  " go back to list and resize
  wincmd h
  vertical resize 40

  " populate list
  call s:PopulateList()

  " show first entry details but stay in list
  if len(s:db2_entries) > 0
    call cursor(1, 1)
    let s:current_entry = s:db2_entries[0]
    let s:current_entry_index = 0
    let s:show_password = 0
    let s:notes_expanded = 0
    let s:additional_expanded = 0
    call s:RenderDetail()
  endif
endfunction

function! s:SetupListBuffer() abort
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nowrap
  setlocal nomodifiable
  setlocal cursorline
  setlocal filetype=db2-list

  " set buffer name
  file [Db2]

  " keybindings
  nnoremap <buffer> <CR> :call <SID>ShowEntryDetail()<CR>
  nnoremap <buffer> l :call <SID>ShowEntryDetail()<CR>
  nnoremap <buffer> q :call <SID>CloseDb2()<CR>
  nnoremap <buffer> y :call <SID>YankPassword()<CR>
  nnoremap <buffer> Y :call <SID>YankUsername()<CR>
  nnoremap <buffer> s :call <SID>TogglePassword()<CR>
  nnoremap <buffer> / :call <SID>SearchDb2()<CR>
  nnoremap <buffer> <Esc> :call <SID>ClearSearch()<CR>
  nnoremap <buffer> ? :call <SID>ShowHelp()<CR>
  nnoremap <buffer> a :call <SID>AddEntry()<CR>
  nnoremap <buffer> dd :call <SID>DeleteEntry()<CR>
endfunction

function! s:SetupDetailBuffer() abort
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nowrap
  setlocal nomodifiable
  setlocal filetype=db2-detail

  file [Db2-Detail]

  " keybindings for detail pane
  nnoremap <buffer> q :call <SID>CloseDb2()<CR>
  nnoremap <buffer> h :wincmd h<CR>
  nnoremap <buffer> y :call <SID>YankPassword()<CR>
  nnoremap <buffer> Y :call <SID>YankUsername()<CR>
  nnoremap <buffer> s :call <SID>TogglePassword()<CR>
  nnoremap <buffer> ? :call <SID>ShowHelp()<CR>
  nnoremap <buffer> <CR> :call <SID>ToggleSection()<CR>
  nnoremap <buffer> e :call <SID>EditField()<CR>
  nnoremap <buffer> a :call <SID>AddEntry()<CR>
  nnoremap <buffer> A :call <SID>AddAdditionalEntry()<CR>
  nnoremap <buffer> dd :call <SID>DeleteEntry()<CR>
endfunction

function! s:PopulateList(...) abort
  let l:entries = a:0 > 0 ? a:1 : s:db2_entries
  let l:winid = bufwinid(s:list_bufnr)

  if l:winid == -1
    return
  endif

  let l:lines = []
  for entry in l:entries
    let l:marker = len(get(entry, 'additionalEntries', [])) > 0 ? '+' : ' '
    call add(l:lines, l:marker . ' ' . get(entry, 'name', '(unnamed)'))
  endfor

  call win_execute(l:winid, 'setlocal modifiable')
  call deletebufline(s:list_bufnr, 1, '$')
  call setbufline(s:list_bufnr, 1, l:lines)
  call win_execute(l:winid, 'setlocal nomodifiable')
endfunction

function! s:ShowEntryDetail() abort
  let l:lnum = line('.')
  let l:entries = get(s:, 'search_active', 0) ? s:filtered_entries : s:db2_entries

  if l:lnum < 1 || l:lnum > len(l:entries)
    return
  endif

  let s:current_entry = l:entries[l:lnum - 1]
  " find actual index in main db2_entries
  let s:current_entry_index = index(s:db2_entries, s:current_entry)
  let s:show_password = 0
  let s:notes_expanded = 0
  let s:additional_expanded = 0
  call s:RenderDetail()
  wincmd l
endfunction

function! s:RenderDetail() abort
  let l:winid = bufwinid(s:detail_bufnr)

  if l:winid == -1
    return
  endif

  let l:e = s:current_entry
  if empty(l:e)
    return
  endif

  let l:pwd = get(l:e, 'password', '')
  let l:pwd_display = get(s:, 'show_password', 0) ? l:pwd : repeat('*', len(l:pwd))
  if empty(l:pwd)
    let l:pwd_display = '(none)'
  endif

  let s:field_lines = {}
  let l:lines = [
    \ '═══════════════════════════════════════',
    \ ' ' . get(l:e, 'name', ''),
    \ '═══════════════════════════════════════',
    \ '',
    \ ]
  let s:field_lines['name'] = 2
  let s:field_lines['url'] = len(l:lines) + 1
  call add(l:lines, '  url:      ' . get(l:e, 'url', ''))
  let s:field_lines['username'] = len(l:lines) + 1
  call add(l:lines, '  username: ' . get(l:e, 'username', ''))
  let s:field_lines['password'] = len(l:lines) + 1
  call add(l:lines, '  password: ' . l:pwd_display)
  let s:field_lines['totp'] = len(l:lines) + 1
  call add(l:lines, '  totp:     ' . (empty(get(l:e, 'totp', '')) ? '(none)' : get(l:e, 'totp', '')))
  let s:field_lines['groupings'] = len(l:lines) + 1
  call add(l:lines, '  group:    ' . get(l:e, 'groupings', ''))
  let s:field_lines['user'] = len(l:lines) + 1
  call add(l:lines, '  owner:    ' . get(l:e, 'user', ''))
  call add(l:lines, '')
  call add(l:lines, '───────────────────────────────────────')
  call add(l:lines, '  [s] show/hide  [y] yank  [e] edit  [?] help')
  call add(l:lines, '───────────────────────────────────────')

  " add extra notes section
  let l:extra = get(l:e, 'extra', '')
  let l:extra_lines = empty(l:extra) ? [] : split(s:CleanHtml(l:extra), "\n")
  let l:extra_count = len(l:extra_lines)
  call add(l:lines, '')
  let s:notes_line = len(l:lines) + 1
  if s:notes_expanded
    call add(l:lines, '[-] notes: (' . l:extra_count . ' lines)')
    if empty(l:extra_lines)
      call add(l:lines, '  (none)')
    else
      for line in l:extra_lines
        call add(l:lines, '  ' . line)
      endfor
    endif
  else
    call add(l:lines, '[+] notes: (' . l:extra_count . ' lines)')
  endif

  " add additional entries section
  let l:entries = get(l:e, 'additionalEntries', [])
  call add(l:lines, '')
  let s:additional_line = len(l:lines) + 1
  let s:additional_entry_lines = {}
  let s:additional_field_lines = {}
  if s:additional_expanded
    call add(l:lines, '[-] additional entries: ' . len(l:entries))
    if empty(l:entries)
      call add(l:lines, '  (none)')
    else
      let l:idx = 0
      for entry in l:entries
        call add(l:lines, '')
        let l:entry_start = len(l:lines) + 1
        call add(l:lines, '  ' . (l:idx + 1) . '. ' . get(entry, 'name', '(unnamed)'))
        let s:additional_entry_lines[l:entry_start] = l:idx
        let s:additional_field_lines[l:entry_start] = 'name'
        call add(l:lines, '     url:  ' . get(entry, 'url', ''))
        let s:additional_entry_lines[len(l:lines)] = l:idx
        let s:additional_field_lines[len(l:lines)] = 'url'
        call add(l:lines, '     user: ' . get(entry, 'username', ''))
        let s:additional_entry_lines[len(l:lines)] = l:idx
        let s:additional_field_lines[len(l:lines)] = 'username'
        let l:apwd = get(entry, 'password', '')
        let l:apwd_display = get(s:, 'show_password', 0) ? l:apwd : repeat('*', len(l:apwd))
        call add(l:lines, '     pass: ' . l:apwd_display)
        let s:additional_entry_lines[len(l:lines)] = l:idx
        let s:additional_field_lines[len(l:lines)] = 'password'
        if !empty(get(entry, 'extra', ''))
          call add(l:lines, '     note: ' . get(entry, 'extra', ''))
          let s:additional_entry_lines[len(l:lines)] = l:idx
          let s:additional_field_lines[len(l:lines)] = 'extra'
        endif
        let l:idx += 1
      endfor
    endif
  else
    call add(l:lines, '[+] additional entries: ' . len(l:entries))
  endif

  call win_execute(l:winid, 'setlocal modifiable')
  call deletebufline(s:detail_bufnr, 1, '$')
  call setbufline(s:detail_bufnr, 1, l:lines)
  call win_execute(l:winid, 'setlocal nomodifiable')
endfunction

function! s:TogglePassword() abort
  let l:pos = getcurpos()
  let s:show_password = !get(s:, 'show_password', 0)
  call s:RenderDetail()
  call setpos('.', l:pos)
endfunction

function! s:ToggleSection() abort
  let l:lnum = line('.')
  if l:lnum == s:notes_line
    let s:notes_expanded = !s:notes_expanded
    call s:RenderDetail()
    call cursor(s:notes_line, 1)
  elseif l:lnum == s:additional_line
    let s:additional_expanded = !s:additional_expanded
    call s:RenderDetail()
    call cursor(s:additional_line, 1)
  endif
endfunction

function! s:EditField() abort
  let l:lnum = line('.')
  let l:field = ''
  let l:field_key = ''

  " check if on additional entry line first
  if has_key(s:additional_entry_lines, l:lnum)
    let l:add_idx = s:additional_entry_lines[l:lnum]
    let l:add_field = get(s:additional_field_lines, l:lnum, '')
    if !empty(l:add_field)
      call s:EditAdditionalField(l:add_idx, l:add_field)
      return
    endif
  endif

  " find which field we're on
  for [key, line] in items(s:field_lines)
    if l:lnum == line
      let l:field_key = key
      break
    endif
  endfor

  " check if on notes line
  if l:lnum == s:notes_line
    let l:field_key = 'extra'
  endif

  if empty(l:field_key)
    echo 'db2: not on an editable field'
    return
  endif

  " get current value
  let l:value = get(s:current_entry, l:field_key, '')
  if l:field_key == 'extra'
    let l:value = s:CleanHtml(l:value)
  endif

  " open edit buffer
  belowright new
  let s:edit_bufnr = bufnr('%')
  let s:edit_field = l:field_key
  let s:edit_additional_index = -1

  setlocal buftype=acwrite
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal filetype=db2-edit

  execute 'file [Db2-Edit:' . l:field_key . ']'

  " set buffer content
  if empty(l:value)
    call setline(1, '')
  else
    call setline(1, split(l:value, "\n"))
  endif

  " keybindings
  nnoremap <buffer> q :call <SID>CancelEdit()<CR>
  nnoremap <buffer> <Esc> :call <SID>CancelEdit()<CR>

  " save on :w
  autocmd BufWriteCmd <buffer> call s:SaveField()

  echo 'db2: editing ' . l:field_key . ' (q to cancel, :w to save)'
endfunction

function! s:EditAdditionalField(index, field) abort
  let l:additional = get(s:current_entry, 'additionalEntries', [])

  if a:index < 0 || a:index >= len(l:additional)
    echo 'db2: invalid additional entry'
    return
  endif

  let l:entry = l:additional[a:index]
  let l:value = get(l:entry, a:field, '')
  let l:entry_name = get(l:entry, 'name', '(unnamed)')

  " open edit buffer
  belowright new
  let s:edit_bufnr = bufnr('%')
  let s:edit_field = a:field
  let s:edit_additional_index = a:index

  setlocal buftype=acwrite
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal filetype=db2-edit

  execute 'file [Db2-Edit:' . l:entry_name . ':' . a:field . ']'

  " set buffer content
  if empty(l:value)
    call setline(1, '')
  else
    call setline(1, split(l:value, "\n"))
  endif

  " keybindings
  nnoremap <buffer> q :call <SID>CancelEdit()<CR>
  nnoremap <buffer> <Esc> :call <SID>CancelEdit()<CR>

  " save on :w
  autocmd BufWriteCmd <buffer> call s:SaveField()

  echo 'db2: editing ' . l:entry_name . ' ' . a:field . ' (q to cancel, :w to save)'
endfunction

function! s:SaveField() abort
  let l:lines = getline(1, '$')
  let l:value = join(l:lines, "\n")

  if s:edit_additional_index >= 0
    " editing additional entry field
    let l:additional = get(s:current_entry, 'additionalEntries', [])
    if s:edit_additional_index < len(l:additional)
      let l:additional[s:edit_additional_index][s:edit_field] = l:value
      let s:current_entry['additionalEntries'] = l:additional

      " update in db2_entries
      if s:current_entry_index >= 0
        let s:db2_entries[s:current_entry_index]['additionalEntries'] = l:additional
      endif
    endif
  else
    " editing main entry field
    let s:current_entry[s:edit_field] = l:value

    " update in db2_entries
    if s:current_entry_index >= 0
      let s:db2_entries[s:current_entry_index][s:edit_field] = l:value
    endif
  endif

  " save to file
  call s:SaveDb2()

  " close edit buffer
  bwipeout!

  " refresh detail view
  call s:RenderDetail()

  " update list if name changed
  if s:edit_field == 'name' && s:edit_additional_index < 0
    call s:PopulateList()
  endif

  echo 'db2: saved ' . s:edit_field
endfunction

function! s:CancelEdit() abort
  bwipeout!
  echo 'db2: edit cancelled'
endfunction

function! s:DeleteEntry() abort
  if empty(s:current_entry)
    echo 'db2: no entry selected'
    return
  endif

  " check if on an additional entry line
  let l:lnum = line('.')
  if has_key(s:additional_entry_lines, l:lnum)
    call s:DeleteAdditionalEntry(s:additional_entry_lines[l:lnum])
    return
  endif

  let l:name = get(s:current_entry, 'name', '(unnamed)')
  let l:confirm = input('delete "' . l:name . '"? (y/n): ')

  if l:confirm !=? 'y'
    echo ' cancelled'
    return
  endif

  " remove from list
  if s:current_entry_index >= 0
    call remove(s:db2_entries, s:current_entry_index)
  endif

  " save to file
  call s:SaveDb2()

  " refresh list
  call s:PopulateList()

  " select next entry or previous if at end
  let l:new_index = s:current_entry_index
  if l:new_index >= len(s:db2_entries)
    let l:new_index = len(s:db2_entries) - 1
  endif

  if l:new_index >= 0 && len(s:db2_entries) > 0
    let s:current_entry = s:db2_entries[l:new_index]
    let s:current_entry_index = l:new_index
    call s:RenderDetail()
    " move cursor in list
    let l:winid = bufwinid(s:list_bufnr)
    if l:winid != -1
      call win_execute(l:winid, 'call cursor(' . (l:new_index + 1) . ', 1)')
    endif
  else
    let s:current_entry = {}
    let s:current_entry_index = -1
    call s:RenderDetail()
  endif

  echo 'db2: deleted "' . l:name . '"'
endfunction

function! s:AddEntry() abort
  let l:name = input('name: ')
  if empty(l:name)
    echo ' cancelled'
    return
  endif

  " create new entry with default structure
  let l:new_entry = {
    \ 'id': string(len(s:db2_entries) + 1),
    \ 'name': l:name,
    \ 'url': '',
    \ 'username': '',
    \ 'password': '',
    \ 'totp': '',
    \ 'extra': '',
    \ 'groupings': 'Passwords',
    \ 'fav': '0.00',
    \ 'user': '',
    \ 'additionalEntries': []
    \ }

  " add to list
  call add(s:db2_entries, l:new_entry)

  " save to file
  call s:SaveDb2()

  " refresh list
  call s:PopulateList()

  " select the new entry
  let s:current_entry = l:new_entry
  let s:current_entry_index = len(s:db2_entries) - 1
  let s:show_password = 0
  let s:notes_expanded = 0
  let s:additional_expanded = 0
  call s:RenderDetail()

  " move cursor to new entry in list
  let l:winid = bufwinid(s:list_bufnr)
  if l:winid != -1
    call win_execute(l:winid, 'call cursor(' . len(s:db2_entries) . ', 1)')
  endif

  echo 'db2: created "' . l:name . '"'
endfunction

function! s:AddAdditionalEntry() abort
  if empty(s:current_entry)
    echo 'db2: no entry selected'
    return
  endif

  let l:name = input('additional entry name: ')
  if empty(l:name)
    echo ' cancelled'
    return
  endif

  " create new additional entry
  let l:additional = get(s:current_entry, 'additionalEntries', [])
  let l:new_additional = {
    \ 'ID': string(len(l:additional) + 1),
    \ 'name': l:name,
    \ 'url': '',
    \ 'username': '',
    \ 'password': '',
    \ 'extra': ''
    \ }

  " add to current entry
  call add(l:additional, l:new_additional)
  let s:current_entry['additionalEntries'] = l:additional

  " update in db2_entries
  if s:current_entry_index >= 0
    let s:db2_entries[s:current_entry_index]['additionalEntries'] = l:additional
  endif

  " save to file
  call s:SaveDb2()

  " refresh detail and expand additional section
  let s:additional_expanded = 1
  call s:RenderDetail()

  " refresh list (marker may have changed)
  call s:PopulateList()

  echo 'db2: added additional entry "' . l:name . '"'
endfunction

function! s:DeleteAdditionalEntry(index) abort
  let l:additional = get(s:current_entry, 'additionalEntries', [])

  if a:index < 0 || a:index >= len(l:additional)
    echo 'db2: invalid additional entry'
    return
  endif

  let l:name = get(l:additional[a:index], 'name', '(unnamed)')
  let l:confirm = input('delete additional "' . l:name . '"? (y/n): ')

  if l:confirm !=? 'y'
    echo ' cancelled'
    return
  endif

  " remove from list
  call remove(l:additional, a:index)
  let s:current_entry['additionalEntries'] = l:additional

  " update in db2_entries
  if s:current_entry_index >= 0
    let s:db2_entries[s:current_entry_index]['additionalEntries'] = l:additional
  endif

  " save to file
  call s:SaveDb2()

  " refresh detail
  call s:RenderDetail()

  " refresh list (marker may have changed)
  call s:PopulateList()

  echo 'db2: deleted additional entry "' . l:name . '"'
endfunction

function! s:SaveDb2() abort
  if empty(s:db2_file_path)
    echohl ErrorMsg
    echo 'db2: no file path'
    echohl None
    return
  endif

  try
    let l:json = json_encode(s:db2_entries)
    " pretty print json
    let l:json = substitute(l:json, '\[{', "[\n  {", 'g')
    let l:json = substitute(l:json, '},{', "},\n  {", 'g')
    let l:json = substitute(l:json, '}]', "}\n]", 'g')
    call writefile(split(l:json, "\n"), s:db2_file_path)
  catch
    echohl ErrorMsg
    echo 'db2: failed to save'
    echohl None
  endtry
endfunction

function! s:YankPassword() abort
  let l:pwd = get(s:current_entry, 'password', '')
  if empty(l:pwd)
    echo 'db2: no password'
    return
  endif

  " try system clipboard first
  if s:CopyToClipboard(l:pwd)
    echo 'db2: password copied to clipboard'
  else
    " fallback to unnamed register
    let @" = l:pwd
    echo 'db2: password yanked to register'
  endif
endfunction

function! s:YankUsername() abort
  let l:user = get(s:current_entry, 'username', '')
  if empty(l:user)
    echo 'db2: no username'
    return
  endif

  if s:CopyToClipboard(l:user)
    echo 'db2: username copied to clipboard'
  else
    let @" = l:user
    echo 'db2: username yanked to register'
  endif
endfunction

function! s:CopyToClipboard(text) abort
  " try xclip
  if executable('xclip')
    call system('xclip -selection clipboard', a:text)
    return v:shell_error == 0
  endif

  " try xsel
  if executable('xsel')
    call system('xsel --clipboard --input', a:text)
    return v:shell_error == 0
  endif

  " try wl-copy (wayland)
  if executable('wl-copy')
    call system('wl-copy', a:text)
    return v:shell_error == 0
  endif

  " try vim clipboard if available
  if has('clipboard')
    let @+ = a:text
    return 1
  endif

  return 0
endfunction

function! s:ShowPopup(title, lines) abort
  let l:width = 60
  let l:height = min([len(a:lines) + 2, 20])

  if has('nvim')
    " neovim floating window
    let l:buf = nvim_create_buf(v:false, v:true)
    call nvim_buf_set_lines(l:buf, 0, -1, v:true, a:lines)

    let l:opts = {
      \ 'relative': 'editor',
      \ 'width': l:width,
      \ 'height': l:height,
      \ 'col': (&columns - l:width) / 2,
      \ 'row': (&lines - l:height) / 2,
      \ 'style': 'minimal',
      \ 'border': 'rounded',
      \ 'title': a:title,
      \ }

    let l:win = nvim_open_win(l:buf, v:true, l:opts)

    " close on q or escape
    nnoremap <buffer> q :close<CR>
    nnoremap <buffer> <Esc> :close<CR>
    setlocal nomodifiable
  else
    " vim popup
    let l:popup_id = popup_create(a:lines, {
      \ 'title': a:title,
      \ 'border': [],
      \ 'padding': [0, 1, 0, 1],
      \ 'maxwidth': l:width,
      \ 'maxheight': l:height,
      \ 'close': 'click',
      \ 'filter': function('s:PopupFilter'),
      \ 'mapping': 0,
      \ })
  endif
endfunction

function! s:PopupFilter(winid, key) abort
  if a:key == 'q' || a:key == "\<Esc>" || a:key == 'h'
    call popup_close(a:winid)
    return 1
  endif
  if a:key == 'j'
    call win_execute(a:winid, 'normal! j')
    return 1
  endif
  if a:key == 'k'
    call win_execute(a:winid, 'normal! k')
    return 1
  endif
  if a:key == 'g'
    call win_execute(a:winid, 'normal! gg')
    return 1
  endif
  if a:key == 'G'
    call win_execute(a:winid, 'normal! G')
    return 1
  endif
  return 0
endfunction

function! s:CleanHtml(html) abort
  let l:text = a:html
  " convert br and div to newlines
  let l:text = substitute(l:text, '<br\s*/?>', "\n", 'g')
  let l:text = substitute(l:text, '<div>', '', 'g')
  let l:text = substitute(l:text, '</div>', "\n", 'g')
  " strip remaining tags
  let l:text = substitute(l:text, '<[^>]*>', '', 'g')
  " decode entities
  let l:text = substitute(l:text, '&nbsp;', ' ', 'g')
  let l:text = substitute(l:text, '&amp;', '\&', 'g')
  let l:text = substitute(l:text, '&lt;', '<', 'g')
  let l:text = substitute(l:text, '&gt;', '>', 'g')
  return l:text
endfunction

function! s:SearchDb2() abort
  let l:term = input('search: ')
  if empty(l:term)
    return
  endif

  let l:term_lower = tolower(l:term)
  let l:matches = []

  for entry in s:db2_entries
    let l:match = 0
    if stridx(tolower(get(entry, 'name', '')), l:term_lower) >= 0
      let l:match = 1
    elseif stridx(tolower(get(entry, 'url', '')), l:term_lower) >= 0
      let l:match = 1
    elseif stridx(tolower(get(entry, 'username', '')), l:term_lower) >= 0
      let l:match = 1
    elseif stridx(tolower(get(entry, 'extra', '')), l:term_lower) >= 0
      let l:match = 1
    endif

    if l:match
      call add(l:matches, entry)
    endif
  endfor

  if empty(l:matches)
    echo 'db2: no matches'
    return
  endif

  let s:filtered_entries = l:matches
  let s:search_active = 1
  call s:PopulateList(l:matches)

  " update window title
  let l:winid = bufwinid(s:list_bufnr)
  if l:winid != -1
    call win_execute(l:winid, 'file [Db2:' . len(l:matches) . '/' . len(s:db2_entries) . ']')
  endif

  echo 'db2: ' . len(l:matches) . ' matches'
endfunction

function! s:ClearSearch() abort
  if get(s:, 'search_active', 0)
    let s:search_active = 0
    call s:PopulateList()
    let l:winid = bufwinid(s:list_bufnr)
    if l:winid != -1
      call win_execute(l:winid, 'file [Db2]')
    endif
    echo 'db2: search cleared'
  endif
endfunction

function! s:ShowHelp() abort
  let l:lines = [
    \ 'db2 keybindings:',
    \ '',
    \ '  j/k     move up/down',
    \ '  gg/G    top/bottom',
    \ '  Enter/l select entry',
    \ '  h       back to list',
    \ '',
    \ '  y       yank password',
    \ '  Y       yank username',
    \ '  s       show/hide password',
    \ '',
    \ '  a       add new entry',
    \ '  A       add additional entry (in detail)',
    \ '  dd      delete entry',
    \ '  e       edit field (on field line)',
    \ '  Enter   expand/collapse section (in detail)',
    \ '',
    \ '  /       search',
    \ '  Esc     clear search',
    \ '  q       close db2',
    \ '  ?       this help',
    \ ]

  call s:ShowPopup(' Help ', l:lines)
endfunction

function! s:CloseDb2() abort
  if s:list_bufnr != -1 && bufexists(s:list_bufnr)
    execute 'bwipeout ' . s:list_bufnr
  endif
  if s:detail_bufnr != -1 && bufexists(s:detail_bufnr)
    execute 'bwipeout ' . s:detail_bufnr
  endif
  let s:list_bufnr = -1
  let s:detail_bufnr = -1
  let s:current_entry = {}
endfunction
