" dadbod_format.vim - Autoload functions for SQL output formatting
" Provides bordered tables, column alignment, truncation, and cell expansion

" Configuration
let g:dadbod_format_max_widths = get(g:, 'dadbod_format_max_widths', {
      \ 'guid': 15,
      \ 'timestamp': 22,
      \ 'number': 15,
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
let s:stable_count = 0  " Number of consecutive polls with same content

function! dadbod_format#auto_format() abort
  " Cancel any existing poll
  if s:poll_timer != -1
    call timer_stop(s:poll_timer)
  endif
  let s:poll_count = 0
  let s:last_line_count = 0
  let s:stable_count = 0
  " Reset formatted flag so new content can be formatted
  let b:dbout_is_formatted = 0
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

  " Check line count - if stable for 3 consecutive polls, format
  let l:lines = getbufline(l:dbout_bufnr, 1, '$')
  let l:line_count = len(l:lines)

  if l:line_count > 1 && l:line_count == s:last_line_count
    let s:stable_count += 1
    " Wait for 3 consecutive stable polls (600ms of no changes)
    if s:stable_count >= 3
      call timer_stop(a:timer)
      let s:poll_timer = -1
      call dadbod_format#format_from_anywhere()
      return
    endif
  else
    let s:stable_count = 0
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
  if empty(l:lines)
    return
  endif

  " Skip if content is already formatted (contains our box-drawing chars)
  " This prevents re-formatting when switching between queries
  let l:first_line = l:lines[0]
  if l:first_line =~# '^[┌┐└┘├┤┬┴┼─│]'
    return
  endif

  " Skip formatting if output looks like an error message
  " Check first line for common error patterns (not mysql:/mariadb: as those are just warnings)
  if l:first_line =~? '\v^(Msg|ERROR|Error|error:|failed|ORA-|PLS-|SP2-|SQL Error)'
    return
  endif
  " Check if content contains SQL Server error pattern (Msg followed by number)
  let l:content = join(l:lines, "\n")
  if l:content =~# '\vMsg\s+\d+.*Level\s+\d+'
    return
  endif
  " Check for MySQL/MariaDB error pattern (ERROR nnnn)
  if l:content =~# '\vERROR\s+\d+\s+\(\d+\)'
    return
  endif
  " Check for other common error indicators
  if l:content =~? '\v(Incorrect syntax|syntax error|permission denied|access denied|connection refused|login failed)'
    return
  endif

  " Store raw content for toggle
  let b:dbout_raw_content = copy(l:lines)
  let b:dbout_is_formatted = 1

  " Store cell data for expansion (across all result sets)
  let b:dbout_cell_data = {}
  let b:dbout_all_headers = []
  let b:dbout_all_rows = []
  let b:dbout_col_info_list = []  " Store column types/widths per result set for highlighting
  let b:dbout_table_data_lines = []  " Track data line ranges for each result set [(start, end), ...]

  " Split into multiple result sets and format each
  let l:result_sets = s:split_result_sets(l:lines)
  let l:all_formatted = []
  let l:global_row_offset = 0
  let b:dbout_header_lines = []  " Track header line numbers for highlighting

  for l:result_set in l:result_sets
    let l:result_lines = l:result_set.lines
    let l:status_msg = get(l:result_set, 'status', '')

    " Handle status-only results (UPDATE/DELETE/INSERT with no table output)
    if empty(l:result_lines) && !empty(l:status_msg)
      if !empty(l:all_formatted)
        call add(l:all_formatted, '')
      endif
      call add(l:all_formatted, l:status_msg)
      continue
    endif

    " Parse the output
    let l:parsed = s:parse_output(l:result_lines)
    if empty(l:parsed.headers) || empty(l:parsed.rows)
      " If we have a status message but parsing failed, show the status
      if !empty(l:status_msg)
        if !empty(l:all_formatted)
          call add(l:all_formatted, '')
        endif
        call add(l:all_formatted, l:status_msg)
      endif
      continue
    endif

    " Check for ROW_COUNT() result (our injected query for MySQL UPDATE/DELETE/INSERT)
    " Display as simple "(N rows affected)" instead of a table
    if len(l:parsed.headers) == 1 && l:parsed.headers[0] ==# 'rows_affected' && len(l:parsed.rows) == 1
      let l:count = l:parsed.rows[0][0]
      if !empty(l:all_formatted)
        call add(l:all_formatted, '')
      endif
      let l:word = l:count == '1' ? 'row' : 'rows'
      call add(l:all_formatted, '(' . l:count . ' ' . l:word . ' affected)')
      continue
    endif

    " Validate parsing result - skip if it looks malformed
    " (e.g., contains MySQL border chars means parsing failed)
    let l:is_malformed = 0
    for l:h in l:parsed.headers
      if l:h =~# '+[-+]\+' || l:h =~# '^\s*|\s*$'
        let l:is_malformed = 1
        break
      endif
    endfor
    if !l:is_malformed && !empty(l:parsed.rows)
      for l:cell in l:parsed.rows[0]
        if l:cell =~# '+[-+]\+' || l:cell =~# '^\s*-\+\s*$'
          let l:is_malformed = 1
          break
        endif
      endfor
    endif
    if l:is_malformed
      continue
    endif

    " Store for cell expansion
    call add(b:dbout_all_headers, l:parsed.headers)
    call add(b:dbout_all_rows, l:parsed.rows)

    " Calculate column widths and detect types
    let l:col_info = s:analyze_columns(l:parsed.headers, l:parsed.rows)

    " Store column info for this result set (used for highlighting)
    call add(b:dbout_col_info_list, l:col_info)

    " Apply truncation and store original values (with global row offset)
    let l:truncated = s:truncate_data_with_offset(l:parsed.headers, l:parsed.rows, l:col_info, l:global_row_offset)

    " Render bordered table
    let l:formatted = s:render_table(l:truncated.headers, l:truncated.rows, l:col_info.widths)

    " Track header line number (line 2 of each table, accounting for blank lines between tables)
    " +1 for blank line between tables (if not first), +1 for 1-based line numbers
    let l:table_start_line = len(l:all_formatted) + 1
    if !empty(l:all_formatted)
      let l:table_start_line += 1  " Account for blank line separator
    endif
    let l:header_line = l:table_start_line + 1
    call add(b:dbout_header_lines, l:header_line)

    " Track data line range for this table (data starts at line 4 of table: border, header, separator, data)
    " Line numbers are 1-based
    let l:data_start = l:table_start_line + 3  " After border + header + separator
    let l:data_end = l:table_start_line + 3 + len(l:parsed.rows) - 1
    call add(b:dbout_table_data_lines, [l:data_start, l:data_end])

    " Add blank line between tables
    if !empty(l:all_formatted)
      call add(l:all_formatted, '')
    endif
    call extend(l:all_formatted, l:formatted)

    " Add row count line - use status message if available, otherwise count rows
    if !empty(l:status_msg)
      call add(l:all_formatted, l:status_msg)
    else
      let l:row_count = len(l:parsed.rows)
      let l:row_word = l:row_count == 1 ? 'row' : 'rows'
      call add(l:all_formatted, '(' . l:row_count . ' ' . l:row_word . ')')
    endif

    let l:global_row_offset += len(l:parsed.rows)
  endfor

  if empty(l:all_formatted)
    return
  endif

  " For backwards compatibility, store first result set's headers/rows
  if !empty(b:dbout_all_headers)
    let b:dbout_headers = b:dbout_all_headers[0]
    let b:dbout_parsed_rows = b:dbout_all_rows[0]
  endif

  " Replace buffer content
  setlocal modifiable
  silent! %delete _
  call setline(1, l:all_formatted)
  setlocal nomodifiable
  setlocal nomodified
  call cursor(1, 1)

  " Apply syntax highlighting
  call s:apply_highlighting()
endfunction

" ============================================================================
" SPLIT RESULT SETS - separates multiple query results
" Returns list of {'lines': [...], 'status': 'row count or status message'}
" ============================================================================
function! s:split_result_sets(lines) abort
  let l:result_sets = []
  let l:current_set = []
  let l:current_status = ''
  let l:in_data = 0

  for l:i in range(len(a:lines))
    let l:line = a:lines[l:i]

    " Detect result set boundaries and capture status messages:
    " - Row count lines: "(N rows affected)", "N rows in set", "Query OK"
    if l:line =~# '\v^\s*\(?\d+\s+(rows?|row\(s\))\s*(affected|in set|returned)' ||
          \ l:line =~# '\v^\d+ rows? in set'
      " End of a result set - save current if not empty
      if !empty(l:current_set)
        call add(l:result_sets, {'lines': l:current_set, 'status': l:line})
        let l:current_set = []
        let l:current_status = ''
        let l:in_data = 0
      endif
      continue
    endif

    " Handle Query OK (UPDATE/DELETE/INSERT) - capture as status-only result
    if l:line =~# '\v^Query OK'
      " Save any pending result set first
      if !empty(l:current_set)
        call add(l:result_sets, {'lines': l:current_set, 'status': l:current_status})
        let l:current_set = []
      endif
      " Extract row count from "Query OK, N rows affected"
      let l:match = matchlist(l:line, '\v(\d+)\s+rows?\s+affected')
      if !empty(l:match)
        let l:current_status = '(' . l:match[1] . ' ' . (l:match[1] == '1' ? 'row' : 'rows') . ' affected)'
      else
        let l:current_status = l:line
      endif
      " Add status-only result set
      call add(l:result_sets, {'lines': [], 'status': l:current_status})
      let l:current_status = ''
      let l:in_data = 0
      continue
    endif

    " Handle MySQL "Rows matched" line (appears after UPDATE)
    " Format: "Rows matched: 5  Changed: 3  Warnings: 0"
    if l:line =~# '\v^Rows matched:'
      let l:match = matchlist(l:line, '\vChanged:\s*(\d+)')
      if !empty(l:match)
        let l:changed = l:match[1]
        let l:current_status = '(' . l:changed . ' ' . (l:changed == '1' ? 'row' : 'rows') . ' affected)'
        call add(l:result_sets, {'lines': [], 'status': l:current_status})
        let l:current_status = ''
      endif
      continue
    endif

    " Detect MySQL table boundaries: two consecutive +----+ border lines
    " First border = end of previous table, second border = start of new table
    let l:is_mysql_border = l:line =~# '\v^\+[-+]+\+\s*$'

    if l:is_mysql_border && len(l:current_set) >= 4
      " Check if previous line in current_set was also a border (consecutive borders)
      let l:prev_line = l:current_set[-1]
      if l:prev_line =~# '\v^\+[-+]+\+\s*$'
        " Remove the previous border (it was the bottom of the last table)
        call remove(l:current_set, -1)
        " Save current result set
        if !empty(l:current_set)
          call add(l:result_sets, {'lines': l:current_set, 'status': l:current_status})
          let l:current_status = ''
        endif
        " Start new set with this border as the top
        let l:current_set = [l:line]
        let l:in_data = 1
        continue
      endif
    endif

    " Skip mysql warning lines between result sets
    if l:line =~# '\v^mysql:|^\s*$' && !l:in_data
      continue
    endif

    " Start collecting data
    if !empty(trim(l:line))
      let l:in_data = 1
    endif

    call add(l:current_set, l:line)
  endfor

  " Don't forget the last result set
  if !empty(l:current_set)
    call add(l:result_sets, {'lines': l:current_set, 'status': l:current_status})
  endif

  " Fallback: if no result sets but input only contained mysql warnings (no errors),
  " the query likely succeeded - show generic message
  if empty(l:result_sets) && !empty(a:lines)
    let l:only_warnings = 1
    for l:line in a:lines
      let l:trimmed = trim(l:line)
      if !empty(l:trimmed) && l:trimmed !~# '\v^mysql:.*\[Warning\]'
        let l:only_warnings = 0
        break
      endif
    endfor
    if l:only_warnings
      call add(l:result_sets, {'lines': [], 'status': 'Query OK'})
    endif
  endif

  return l:result_sets
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

  " Box-drawing borders - very high priority to ensure they stay white
  call add(w:dbout_match_ids, matchadd('DboutBorder', '[│┌┐└┘├┤┬┴┼─]', 30))

  " Header rows - detect dynamically: any │...│ line that follows a ┌...┐ line
  " Priority 35 to override borders (30) on header lines
  let l:lines = getline(1, '$')
  for l:i in range(1, len(l:lines) - 1)
    if l:lines[l:i - 1] =~# '^┌' && l:lines[l:i] =~# '^│'
      call add(w:dbout_match_ids, matchadd('DboutHeader', '\%' . (l:i + 1) . 'l.', 35))
    endif
  endfor

  " Apply column-based highlighting (handles all data types)
  call s:apply_column_type_highlighting()

  " NULL values - override column type highlighting
  call add(w:dbout_match_ids, matchadd('DboutNull', '│\s*\zsNULL\ze\s*│', 18))

  " Truncated indicator (...) - override column type highlighting
  call add(w:dbout_match_ids, matchadd('DboutTruncated', '\.\.\.\ze\s*│', 18))

  " Row count line - matches various formats:
  " (N rows), (N row), (N rows affected), N row in set (0.00 sec), Query OK, etc.
  call add(w:dbout_match_ids, matchadd('DboutRowCount', '^\d\+ rows\? in set', 10))
  call add(w:dbout_match_ids, matchadd('DboutRowCount', '^(\d\+ rows\?\( affected\)\?)$', 10))
  call add(w:dbout_match_ids, matchadd('DboutRowCount', '^Query OK', 10))
endfunction

" ============================================================================
" COLUMN TYPE HIGHLIGHTING - highlights ALL columns based on detected types
" ============================================================================
function! s:apply_column_type_highlighting() abort
  if !exists('b:dbout_col_info_list') || !exists('b:dbout_table_data_lines')
    return
  endif

  for l:table_idx in range(len(b:dbout_col_info_list))
    let l:col_info = b:dbout_col_info_list[l:table_idx]

    if l:table_idx >= len(b:dbout_table_data_lines)
      continue
    endif
    let [l:data_start, l:data_end] = b:dbout_table_data_lines[l:table_idx]

    " Build pattern prefix for each column and apply highlighting
    for l:col_idx in range(len(l:col_info.types))
      let l:type = l:col_info.types[l:col_idx]

      " Map type to highlight group
      let l:highlight_group = 'DboutString'  " Default for 'default' and unknown types
      if l:type ==# 'guid'
        let l:highlight_group = 'DboutGuid'
      elseif l:type ==# 'timestamp'
        let l:highlight_group = 'DboutTimestamp'
      elseif l:type ==# 'number'
        let l:highlight_group = 'DboutNumber'
      endif

      " Build pattern to match the n-th cell content
      " Skip n cells, then match content in target cell
      let l:cell_prefix = ''
      for l:i in range(l:col_idx)
        let l:cell_prefix .= '│[^│]*'
      endfor

      " Match cell content: after │ and space, capture value including internal spaces
      " Use [^│ \t] instead of \S to explicitly exclude │ from matching
      let l:cell_pattern = l:cell_prefix . '│\s*\zs[^│ \t]\+\%(\s\+[^│ \t]\+\)*\ze'

      " Apply to all data lines in this table
      for l:line_nr in range(l:data_start, l:data_end)
        let l:pattern = '\%' . l:line_nr . 'l' . l:cell_pattern
        call add(w:dbout_match_ids, matchadd(l:highlight_group, l:pattern, 10))
      endfor
    endfor
  endfor
endfunction

" ============================================================================
" PARSING FUNCTIONS
" ============================================================================
function! s:parse_output(lines) abort
  let l:result = {'headers': [], 'rows': []}

  " First, try explicit MySQL format detection (has +----+ borders and | delimiters)
  let l:has_mysql_border = 0
  let l:has_pipe_data = 0
  for l:line in a:lines
    if l:line =~# '^+[-+]\++\s*$'
      let l:has_mysql_border = 1
    endif
    if l:line =~# '^|.\+|$'
      let l:has_pipe_data = 1
    endif
    if l:has_mysql_border && l:has_pipe_data
      break
    endif
  endfor

  " If MySQL format detected, parse with pipe delimiter
  if l:has_mysql_border && l:has_pipe_data
    let l:parsed = s:try_parse_with_delimiter(a:lines, '|')
    if !empty(l:parsed.headers) && !empty(l:parsed.rows)
      return l:parsed
    endif
  endif

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
    " Note: patterns allow optional trailing whitespace
    if l:line =~# '^[-+─┬┼┴├┤┌┐└┘│=]\+\s*$' || l:line =~# '^[\s|+-]*$' || l:line =~# '^[-\s]\+$' || l:line =~# '^+[-+]\++\s*$'
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

    " Width is capped at max_width for data, but must be at least header width
    let l:header_width = len(a:headers[l:i])
    let l:data_width = min([l:actual_max, l:max_width])
    call add(l:info.widths, max([l:header_width, l:data_width]))
  endfor

  return l:info
endfunction

function! s:detect_column_type(header, rows, col_idx) abort
  " Detect type purely from data values, not header names
  " Check ALL values for type detection
  let l:guid_count = 0
  let l:timestamp_count = 0
  let l:json_count = 0
  let l:number_count = 0
  let l:total_non_null = 0

  for l:row in a:rows
    if a:col_idx >= len(l:row)
      continue
    endif
    let l:val = l:row[a:col_idx]

    " Skip NULL values
    if l:val ==# 'NULL' || empty(trim(l:val))
      continue
    endif
    let l:total_non_null += 1

    " GUID pattern: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    if l:val =~# '\v^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      let l:guid_count += 1
    endif

    " Timestamp pattern: YYYY-MM-DD HH:MM:SS
    if l:val =~# '\v^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}'
      let l:timestamp_count += 1
    endif

    " Number pattern: integer or decimal, optionally negative
    if l:val =~# '\v^-?\d+(\.\d+)?$'
      let l:number_count += 1
    endif

    " JSON pattern: starts with { or [
    if l:val =~# '^\s*[\[{]'
      let l:json_count += 1
    endif
  endfor

  " If any value matches GUID pattern, treat entire column as GUID
  if l:guid_count > 0
    return 'guid'
  endif

  " For other types, require majority match
  if l:total_non_null > 0
    if l:timestamp_count * 2 >= l:total_non_null
      return 'timestamp'
    endif
    if l:number_count * 2 >= l:total_non_null
      return 'number'
    endif
    if l:json_count * 2 >= l:total_non_null
      return 'json'
    endif
  endif

  return 'default'
endfunction

" ============================================================================
" TRUNCATION
" ============================================================================
function! s:truncate_data(headers, rows, col_info) abort
  return s:truncate_data_with_offset(a:headers, a:rows, a:col_info, 0)
endfunction

function! s:truncate_data_with_offset(headers, rows, col_info, row_offset) abort
  let l:result = {'headers': [], 'rows': []}
  let l:row_num = a:row_offset

  " Headers are never truncated - use as-is
  let l:result.headers = copy(a:headers)

  " Truncate row values and store originals
  for l:row in a:rows
    let l:new_row = []
    for l:i in range(len(l:row))
      let l:val = l:row[l:i]
      let l:max_w = l:i < len(a:col_info.widths) ? a:col_info.widths[l:i] : g:dadbod_format_max_widths.default
      let l:type = l:i < len(a:col_info.types) ? a:col_info.types[l:i] : 'default'

      " Store original if truncated
      if len(l:val) > l:max_w
        let l:key = l:row_num . ':' . l:i
        let b:dbout_cell_data[l:key] = l:val
      endif

      call add(l:new_row, s:truncate_value(l:val, l:max_w, l:type))
    endfor
    call add(l:result.rows, l:new_row)
    let l:row_num += 1
  endfor

  return l:result
endfunction

function! s:truncate_value(val, max_width, type) abort
  if len(a:val) <= a:max_width
    return a:val
  endif

  " GUIDs: truncate middle, keep first 6 and last 6 chars (e.g., e81234...af1234)
  if a:type ==# 'guid' && a:max_width >= 15
    let l:keep_chars = 6
    let l:prefix = strpart(a:val, 0, l:keep_chars)
    let l:suffix = strpart(a:val, len(a:val) - l:keep_chars)
    return l:prefix . '...' . l:suffix
  endif

  " Default: truncate end with ellipsis
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
  " Create a 1-line horizontal split at bottom
  botright 1new
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
