" dadbod_format.vim - Autoload functions for SQL output formatting
" Provides bordered tables, column alignment, truncation, and cell expansion

" Configuration
let g:dadbod_format_max_widths = get(g:, 'dadbod_format_max_widths', {
      \ 'guid': 8,
      \ 'timestamp': 19,
      \ 'json': 20,
      \ 'default': 40
      \ })

" Box-drawing characters
let s:box = {
      \ 'tl': '┌', 'tr': '┐', 'bl': '└', 'br': '┘',
      \ 'h': '─', 'v': '│',
      \ 'lm': '├', 'rm': '┤', 'tm': '┬', 'bm': '┴', 'mm': '┼'
      \ }

" ============================================================================
" FORMAT FROM ANYWHERE - finds dbout window and formats it
" ============================================================================
function! dadbod_format#format_from_anywhere() abort
  let l:current_win = winnr()
  " Find dbout window
  for l:winnr in range(1, winnr('$'))
    if getwinvar(l:winnr, '&filetype') ==# 'dbout'
      execute l:winnr . 'wincmd w'
      call dadbod_format#format()
      execute l:current_win . 'wincmd w'
      return
    endif
  endfor
  echom "No dbout window found"
endfunction

" ============================================================================
" AUTO FORMAT WITH POLLING - waits for query to complete
" ============================================================================
let s:poll_timer = -1
let s:poll_count = 0
let s:poll_max = 150  " 150 * 200ms = 30 seconds max wait
let s:last_line_count = 0

function! dadbod_format#auto_format() abort
  " Cancel any existing poll
  if s:poll_timer != -1
    call timer_stop(s:poll_timer)
  endif
  let s:poll_count = 0
  let s:last_line_count = 0
  " Start polling after 200ms
  let s:poll_timer = timer_start(200, function('s:poll_for_results'), {'repeat': -1})
endfunction

function! s:poll_for_results(timer) abort
  let s:poll_count += 1

  " Find dbout buffer
  let l:dbout_bufnr = -1
  for l:bufnr in range(1, bufnr('$'))
    if getbufvar(l:bufnr, '&filetype') ==# 'dbout'
      let l:dbout_bufnr = l:bufnr
      break
    endif
  endfor

  if l:dbout_bufnr == -1
    " No dbout buffer yet, keep waiting
    if s:poll_count >= s:poll_max
      call timer_stop(a:timer)
      let s:poll_timer = -1
    endif
    return
  endif

  " Check line count - if stable for 2 polls, format
  let l:lines = getbufline(l:dbout_bufnr, 1, '$')
  let l:line_count = len(l:lines)

  if l:line_count > 1 && l:line_count == s:last_line_count
    " Content stable, format now
    call timer_stop(a:timer)
    let s:poll_timer = -1
    call dadbod_format#format_from_anywhere()
    return
  endif

  let s:last_line_count = l:line_count

  " Timeout
  if s:poll_count >= s:poll_max
    call timer_stop(a:timer)
    let s:poll_timer = -1
    echom "Auto-format timeout - use <leader>df manually"
  endif
endfunction

" ============================================================================
" MAIN FORMAT FUNCTION
" ============================================================================
function! dadbod_format#format() abort
  " Only format dbout buffers
  if &filetype !=# 'dbout'
    return
  endif

  " Skip if already formatted (prevents garbling on re-format)
  if get(b:, 'dbout_is_formatted', 0)
    return
  endif

  " Get buffer content
  let l:lines = getline(1, '$')
  if empty(l:lines) || len(l:lines) < 2
    return
  endif

  " Store raw content for toggle
  let b:dbout_raw_content = copy(l:lines)
  let b:dbout_is_formatted = 1

  " Parse the output
  let l:parsed = s:parse_output(l:lines)
  if empty(l:parsed.headers) || empty(l:parsed.rows)
    return
  endif

  " Store cell data for expansion
  let b:dbout_cell_data = {}
  let b:dbout_headers = l:parsed.headers
  let b:dbout_parsed_rows = l:parsed.rows

  " Calculate column widths and detect types
  let l:col_info = s:analyze_columns(l:parsed.headers, l:parsed.rows)

  " Apply truncation and store original values
  let l:truncated = s:truncate_data(l:parsed.headers, l:parsed.rows, l:col_info)

  " Render bordered table
  let l:formatted = s:render_table(l:truncated.headers, l:truncated.rows, l:col_info.widths)

  " Replace buffer content
  setlocal modifiable
  silent! %delete _
  call setline(1, l:formatted)
  setlocal nomodifiable
  setlocal nomodified
  call cursor(1, 1)

  " Apply syntax highlighting
  call s:apply_highlighting()
endfunction

" ============================================================================
" SYNTAX HIGHLIGHTING
" ============================================================================
function! s:apply_highlighting() abort
  " Clear any existing dbout matches
  if exists('w:dbout_match_ids')
    for l:id in w:dbout_match_ids
      silent! call matchdelete(l:id)
    endfor
  endif
  let w:dbout_match_ids = []

  " Strings - data cell contents only (line > 3 skips header), low priority so others override
  call add(w:dbout_match_ids, matchadd('DboutString', '\%>3l│ \zs\S.*\S\ze │', 5))
  call add(w:dbout_match_ids, matchadd('DboutString', '\%>3l│ \zs\S\ze │', 5))

  " Numbers (integers and decimals, including negative) - must be solo in cell
  call add(w:dbout_match_ids, matchadd('DboutNumber', '│\s*\zs-\?\d\+\(\.\d\+\)\?\ze\s*│'))

  " GUIDs (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) - full format
  call add(w:dbout_match_ids, matchadd('DboutGuid', '\x\{8}-\x\{4}-\x\{4}-\x\{4}-\x\{12}'))
  " Truncated GUIDs - hex chars in a cell ending with ... (matches cell content before ...)
  call add(w:dbout_match_ids, matchadd('DboutGuid', '│\s*\zs\x\+\ze\.\.\.'))

  " Timestamps (YYYY-MM-DD HH:MM:SS format, with optional fractional seconds)
  call add(w:dbout_match_ids, matchadd('DboutTimestamp', '\d\{4}-\d\{2}-\d\{2}[ T]\d\{2}:\d\{2}:\d\{2}\(\.\d\+\)\?'))
  " Truncated timestamps - date/time before ...
  call add(w:dbout_match_ids, matchadd('DboutTimestamp', '\d\{4}-\d\{2}-\d\{2}[ T]\d\{2}:\d\{2}\ze\.\.\.'))

  " Truncated cells (ending with ...)
  call add(w:dbout_match_ids, matchadd('DboutTruncated', '\.\.\.\ze\s*│'))

  " NULL values
  call add(w:dbout_match_ids, matchadd('DboutNull', '│\s*\zsNULL\ze\s*│'))
endfunction

" ============================================================================
" PARSING FUNCTIONS
" ============================================================================
function! s:parse_output(lines) abort
  let l:result = {'headers': [], 'rows': []}

  " Try different delimiters
  let l:delimiters = ['|', "\t", ',']

  for l:delim in l:delimiters
    let l:parsed = s:try_parse_with_delimiter(a:lines, l:delim)
    if !empty(l:parsed.headers) && !empty(l:parsed.rows)
      return l:parsed
    endif
  endfor

  " Fallback: try fixed-width parsing (SQL Server without delimiter)
  return s:parse_fixed_width(a:lines)
endfunction

function! s:try_parse_with_delimiter(lines, delim) abort
  let l:result = {'headers': [], 'rows': []}
  let l:data_lines = []

  for l:line in a:lines
    " Skip separator lines (----, +--+, SQL Server style ----- -----, MySQL +----+----+, etc.)
    if l:line =~# '^[-+─┬┼┴├┤┌┐└┘│=]\+$' || l:line =~# '^[\s|+-]*$' || l:line =~# '^[-\s]\+$' || l:line =~# '^+[-+]\++$'
      continue
    endif
    " Skip MySQL/database warning and info lines
    if l:line =~# '^\s*\(mysql\|mariadb\|psql\):' || l:line =~# '\[Warning\]' || l:line =~# '\[Note\]' || l:line =~# '\[Error\]'
      continue
    endif
    " Skip empty lines
    if empty(trim(l:line))
      continue
    endif
    call add(l:data_lines, l:line)
  endfor

  if empty(l:data_lines)
    return l:result
  endif

  " First non-empty line is headers
  let l:result.headers = s:split_and_trim(l:data_lines[0], a:delim)

  " Remaining lines are data rows
  for l:i in range(1, len(l:data_lines) - 1)
    let l:row = s:split_and_trim(l:data_lines[l:i], a:delim)
    if !empty(l:row)
      call add(l:result.rows, l:row)
    endif
  endfor

  " Validate: headers and rows should have same column count
  if !empty(l:result.rows)
    let l:header_count = len(l:result.headers)
    let l:row_count = len(l:result.rows[0])
    if l:header_count != l:row_count && l:header_count > 1
      " Mismatch, might be wrong delimiter
      return {'headers': [], 'rows': []}
    endif
  endif

  " Reject if only 1 column but line is long (probably wrong delimiter)
  if len(l:result.headers) == 1 && len(l:data_lines[0]) > 50
    return {'headers': [], 'rows': []}
  endif

  return l:result
endfunction

function! s:split_and_trim(line, delim) abort
  let l:parts = split(a:line, a:delim)
  return map(l:parts, 'trim(v:val)')
endfunction

function! s:parse_fixed_width(lines) abort
  " Handle SQL Server fixed-width output
  let l:result = {'headers': [], 'rows': []}
  let l:data_lines = []
  let l:separator_idx = -1

  " Find the separator line (---- ---- ----)
  for l:i in range(len(a:lines))
    if a:lines[l:i] =~# '^-\+\s\+-\+' || a:lines[l:i] =~# '^-\+$'
      let l:separator_idx = l:i
      break
    endif
    " Skip empty lines at start
    if !empty(trim(a:lines[l:i]))
      call add(l:data_lines, a:lines[l:i])
    endif
  endfor

  if l:separator_idx == -1
    " No separator found, treat first line as headers
    if empty(l:data_lines)
      return l:result
    endif
    let l:result.headers = split(l:data_lines[0])
    for l:i in range(1, len(l:data_lines) - 1)
      call add(l:result.rows, split(l:data_lines[l:i]))
    endfor
    return l:result
  endif

  " Parse based on separator positions
  let l:sep_line = a:lines[l:separator_idx]
  let l:col_positions = s:get_column_positions(l:sep_line)

  " Header is line before separator
  if l:separator_idx > 0
    let l:result.headers = s:extract_fixed_columns(a:lines[l:separator_idx - 1], l:col_positions)
  endif

  " Data rows are lines after separator
  for l:i in range(l:separator_idx + 1, len(a:lines) - 1)
    let l:line = a:lines[l:i]
    if empty(trim(l:line))
      continue
    endif
    " Stop at row count line (e.g., "(5 rows affected)")
    if l:line =~# '^\s*([0-9]\+ rows\? affected)'
      break
    endif
    let l:row = s:extract_fixed_columns(l:line, l:col_positions)
    if !empty(l:row)
      call add(l:result.rows, l:row)
    endif
  endfor

  return l:result
endfunction

function! s:get_column_positions(sep_line) abort
  " Find column boundaries from separator line (---- ---- ----)
  let l:positions = []
  let l:in_col = 0
  let l:start = 0

  for l:i in range(len(a:sep_line))
    let l:char = a:sep_line[l:i]
    if l:char ==# '-'
      if !l:in_col
        let l:start = l:i
        let l:in_col = 1
      endif
    else
      if l:in_col
        call add(l:positions, [l:start, l:i - 1])
        let l:in_col = 0
      endif
    endif
  endfor

  " Handle last column
  if l:in_col
    call add(l:positions, [l:start, len(a:sep_line) - 1])
  endif

  return l:positions
endfunction

function! s:extract_fixed_columns(line, positions) abort
  let l:cols = []
  for [l:start, l:end] in a:positions
    if l:start < len(a:line)
      let l:actual_end = min([l:end, len(a:line) - 1])
      let l:val = strpart(a:line, l:start, l:actual_end - l:start + 1)
      call add(l:cols, trim(l:val))
    else
      call add(l:cols, '')
    endif
  endfor
  return l:cols
endfunction

" ============================================================================
" COLUMN ANALYSIS
" ============================================================================
function! s:analyze_columns(headers, rows) abort
  let l:info = {'types': [], 'widths': []}
  let l:col_count = len(a:headers)

  for l:i in range(l:col_count)
    " Detect type from values
    let l:type = s:detect_column_type(a:headers[l:i], a:rows, l:i)
    call add(l:info.types, l:type)

    " Calculate max width (capped by type limit)
    let l:max_width = g:dadbod_format_max_widths[l:type]
    let l:actual_max = len(a:headers[l:i])

    for l:row in a:rows
      if l:i < len(l:row)
        let l:actual_max = max([l:actual_max, len(l:row[l:i])])
      endif
    endfor

    call add(l:info.widths, min([l:actual_max, l:max_width]))
  endfor

  return l:info
endfunction

function! s:detect_column_type(header, rows, col_idx) abort
  " Check header name hints
  let l:header_lower = tolower(a:header)
  if l:header_lower =~# 'guid\|uuid\|id$'
    return 'guid'
  endif
  if l:header_lower =~# 'date\|time\|created\|updated\|timestamp'
    return 'timestamp'
  endif
  if l:header_lower =~# 'json\|data\|payload\|body'
    return 'json'
  endif

  " Sample values to detect type
  for l:row in a:rows[:min([4, len(a:rows) - 1])]
    if a:col_idx >= len(l:row)
      continue
    endif
    let l:val = l:row[a:col_idx]

    " GUID pattern: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    if l:val =~# '\v^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      return 'guid'
    endif

    " Timestamp pattern: YYYY-MM-DD HH:MM:SS
    if l:val =~# '\v^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}'
      return 'timestamp'
    endif

    " JSON pattern: starts with { or [
    if l:val =~# '^\s*[\[{]'
      return 'json'
    endif
  endfor

  return 'default'
endfunction

" ============================================================================
" TRUNCATION
" ============================================================================
function! s:truncate_data(headers, rows, col_info) abort
  let l:result = {'headers': [], 'rows': []}
  let l:row_num = 0

  " Truncate headers if needed
  for l:i in range(len(a:headers))
    let l:max_w = a:col_info.widths[l:i]
    call add(l:result.headers, s:truncate_value(a:headers[l:i], l:max_w))
  endfor

  " Truncate row values and store originals
  for l:row in a:rows
    let l:new_row = []
    for l:i in range(len(l:row))
      let l:val = l:row[l:i]
      let l:max_w = l:i < len(a:col_info.widths) ? a:col_info.widths[l:i] : g:dadbod_format_max_widths.default

      " Store original if truncated
      if len(l:val) > l:max_w
        let l:key = l:row_num . ':' . l:i
        let b:dbout_cell_data[l:key] = l:val
      endif

      call add(l:new_row, s:truncate_value(l:val, l:max_w))
    endfor
    call add(l:result.rows, l:new_row)
    let l:row_num += 1
  endfor

  return l:result
endfunction

function! s:truncate_value(val, max_width) abort
  if len(a:val) <= a:max_width
    return a:val
  endif
  " Leave room for ellipsis
  return strpart(a:val, 0, a:max_width - 3) . '...'
endfunction

" ============================================================================
" TABLE RENDERING
" ============================================================================
function! s:render_table(headers, rows, widths) abort
  let l:lines = []

  " Top border
  call add(l:lines, s:make_border_line('top', a:widths))

  " Header row
  call add(l:lines, s:make_data_line(a:headers, a:widths))

  " Header separator
  call add(l:lines, s:make_border_line('middle', a:widths))

  " Data rows
  for l:row in a:rows
    call add(l:lines, s:make_data_line(l:row, a:widths))
  endfor

  " Bottom border
  call add(l:lines, s:make_border_line('bottom', a:widths))

  return l:lines
endfunction

function! s:make_border_line(position, widths) abort
  let l:parts = []

  if a:position ==# 'top'
    let l:left = s:box.tl
    let l:mid = s:box.tm
    let l:right = s:box.tr
  elseif a:position ==# 'middle'
    let l:left = s:box.lm
    let l:mid = s:box.mm
    let l:right = s:box.rm
  else " bottom
    let l:left = s:box.bl
    let l:mid = s:box.bm
    let l:right = s:box.br
  endif

  for l:w in a:widths
    call add(l:parts, repeat(s:box.h, l:w + 2))
  endfor

  return l:left . join(l:parts, l:mid) . l:right
endfunction

function! s:make_data_line(values, widths) abort
  let l:parts = []

  for l:i in range(len(a:widths))
    let l:val = l:i < len(a:values) ? a:values[l:i] : ''
    let l:padded = s:pad_value(l:val, a:widths[l:i])
    call add(l:parts, ' ' . l:padded . ' ')
  endfor

  return s:box.v . join(l:parts, s:box.v) . s:box.v
endfunction

function! s:pad_value(val, width) abort
  let l:len = len(a:val)
  if l:len >= a:width
    return a:val
  endif
  return a:val . repeat(' ', a:width - l:len)
endfunction

" ============================================================================
" CELL EXPANSION
" ============================================================================
function! dadbod_format#expand_cell() abort
  if !exists('b:dbout_cell_data')
    echo "No formatted data available"
    return
  endif

  " Get cursor position and determine cell
  let l:line_num = line('.')
  let l:col_pos = col('.')

  " Calculate row number (subtract 2 for top border and header, 1 for header separator)
  " Line 1: top border, Line 2: header, Line 3: separator, Line 4+: data
  let l:data_row = l:line_num - 4

  if l:data_row < 0
    echo "Not on a data row"
    return
  endif

  " Find which column the cursor is in
  let l:line = getline('.')
  let l:col_idx = s:get_column_at_position(l:line, l:col_pos)

  if l:col_idx < 0
    echo "Not in a cell"
    return
  endif

  " Look up original value
  let l:key = l:data_row . ':' . l:col_idx

  if has_key(b:dbout_cell_data, l:key)
    let l:value = b:dbout_cell_data[l:key]
  elseif exists('b:dbout_parsed_rows') && l:data_row < len(b:dbout_parsed_rows)
    let l:row = b:dbout_parsed_rows[l:data_row]
    if l:col_idx < len(l:row)
      let l:value = l:row[l:col_idx]
    else
      echo "No data for this cell"
      return
    endif
  else
    echo "No data for this cell"
    return
  endif

  " Get column header
  let l:header = ''
  if exists('b:dbout_headers') && l:col_idx < len(b:dbout_headers)
    let l:header = b:dbout_headers[l:col_idx]
  endif

  " Open expansion window
  call s:open_expand_window(l:value, l:header)
endfunction

function! s:get_column_at_position(line, col_pos) abort
  " Count box.v characters before cursor position
  " Use stridx() to properly handle multi-byte UTF-8 characters
  let l:substr = strpart(a:line, 0, a:col_pos)
  let l:count = 0
  let l:idx = 0
  while 1
    let l:idx = stridx(l:substr, s:box.v, l:idx)
    if l:idx < 0
      break
    endif
    let l:count += 1
    let l:idx += len(s:box.v)
  endwhile
  " Return column index (first │ is left border, so subtract 1)
  return l:count - 1
endfunction

function! s:open_expand_window(value, header) abort
  " Create a small horizontal split at bottom
  botright 10new
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nobuflisted
  setlocal modifiable

  " Set buffer name
  let l:title = empty(a:header) ? '[Cell Value]' : '[' . a:header . ']'
  silent! execute 'file ' . fnameescape(l:title)

  " Insert content
  let l:lines = split(a:value, '\n')
  call setline(1, l:lines)

  " Detect and set filetype for syntax highlighting
  if a:value =~# '^\s*[\[{]'
    setlocal filetype=json
  endif

  setlocal nomodifiable

  " Map q to close this window
  nnoremap <buffer> q :close<CR>
  nnoremap <buffer> <Esc> :close<CR>

  " Mark this as expansion window
  let b:dbout_expand_window = 1
endfunction

function! dadbod_format#close_expand() abort
  " Find and close expansion window, or just close if in expansion window
  if exists('b:dbout_expand_window')
    close
    return
  endif

  " Look for expansion window in other windows
  for l:winnr in range(1, winnr('$'))
    if getbufvar(winbufnr(l:winnr), 'dbout_expand_window', 0)
      execute l:winnr . 'wincmd w'
      close
      return
    endif
  endfor
endfunction

" ============================================================================
" RAW/FORMATTED TOGGLE
" ============================================================================
function! dadbod_format#toggle_raw() abort
  if !exists('b:dbout_raw_content')
    echo "No raw content stored"
    return
  endif

  setlocal modifiable

  if get(b:, 'dbout_is_formatted', 0)
    " Switch to raw
    silent! %delete _
    call setline(1, b:dbout_raw_content)
    let b:dbout_is_formatted = 0
    echo "Showing raw output"
  else
    " Re-format
    silent! %delete _
    call setline(1, b:dbout_raw_content)
    setlocal nomodifiable
    call dadbod_format#format()
    echo "Showing formatted output"
    return
  endif

  setlocal nomodifiable
endfunction
