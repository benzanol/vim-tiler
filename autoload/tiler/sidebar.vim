" ==============================================================================
" Sidebar actions
" ==============================================================================
" FUNCTION: tiler#sidebar#ToggleSidebarOpen() {{{1
function! tiler#sidebar#ToggleSidebarOpen()
	" Exit if not currently active
	if !tiler#api#IsEnabled()
		echo g:tiler#inactive_message
		return
	endif

	if g:tiler#sidebar.open " Disable the sidebar if it is already active
		let g:tiler#sidebar.open = 0
		let g:tiler#sidebar.focused = 0
		let g:tiler#sidebar.current = {}
		let g:tiler#sidebar.windows = []
	else " Enable the sidebar if it is not already active
		let g:tiler#sidebar.open = 1
		let g:tiler#sidebar.focused = 1 
	endif

	call tiler#display#Render()
endfunction
" }}}
" FUNCTION: tiler#sidebar#ToggleSidebarFocus() {{{1
function! tiler#sidebar#ToggleSidebarFocus()
	" Exit if not currently active
	if !tiler#api#IsEnabled()
		echo g:tiler#inactive_message
		return
	endif

	if !g:tiler#sidebar.open
		call tiler#sidebar#ToggleSidebarOpen()

	elseif g:tiler#sidebar.focused
		let g:tiler#sidebar.focused = 0

	else
		let g:tiler#sidebar.focused = 1
	endif

	call win_gotoid(g:tiler#sidebar.windows[0])
endfunction
" }}}
" FUNCTION: tiler#sidebar#OpenSidebar(name) {{{1
function! tiler#sidebar#OpenSidebar(name)
	" Exit if not currently active
	if !tiler#api#IsEnabled()
		echo g:tiler#inactive_message
		return
	endif

	let g:tiler#sidebar.open = 1
	let g:tiler#sidebar.focused = 1
	if !exists("g:tiler#sidebar.current.name") || a:name != g:tiler#sidebar.current.name
		for q in g:tiler#sidebar.bars
			if has_key(q, "name") && q.name == a:name
				let g:tiler#sidebar.current = q
				break
			endif
		endfor
		call tiler#display#Render()
	else
		call tiler#display#LoadPanes(tiler#api#GetLayout(), [0], g:tiler#always_resize ? [1, 1] : [], 1)
	endif
endfunction
" }}}

" FUNCTION: tiler#sidebar#AddNew(name, command) {{{1
function! tiler#sidebar#AddNew(name, command)
	call add(g:tiler#sidebar.bars, {'name':a:name, 'command':a:command})
endfunction
" }}}
