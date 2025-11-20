" Ensure Python3 support for Vimspector
if has('python3')
  let s:vimspector_python = expand('~/.vim/plugged/vimspector/python3')
  if isdirectory(s:vimspector_python)
    execute 'python3 import sys; sys.path.append(r"' . s:vimspector_python . '")'
  endif
endif

" Use Visual Studio-style keybindings (F5 to run, F9 to toggle breakpoint, etc.)
let g:vimspector_enable_mappings = 'VISUAL_STUDIO'
