" vimspector configuration

" Keybindings (avoid F10/F11/F12 terminal conflicts)
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
