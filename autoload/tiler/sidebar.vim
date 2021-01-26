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
		let g:tiler#sidebar.windows[tabpagenr()] = []
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

	call win_gotoid(g:tiler#sidebar.windows[tabpagenr()][0])
endfunction
" }}}
" FUNCTION: tiler#sidebar#OpenSidebar(name) {{{1
function! tiler#sidebar#OpenSidebar(name)
	" Exit if not currently active
	if !tiler#api#IsEnabled()
		echo g:tiler#inactive_message
		return
	endif

	let already_open = g:tiler#sidebar.open
	let g:tiler#sidebar.open = 1
	let g:tiler#sidebar.focused = 1

	if already_open && a:name == g:tiler#sidebar.name
		call win_gotoid(g:tiler#sidebar.windows[tabpagenr()][0])
	else
		if has_key(g:tiler#sidebars, a:name)
			let g:tiler#sidebar.name = a:name
			let g:tiler#sidebar.command = g:tiler#sidebars[a:name]
		endif
		call tiler#display#Render()
	endif

endfunction
" }}}

"FUNCTION: tiler#sidebar#GetWidth() {{{1
function! tiler#sidebar#GetWidth()
	if g:tiler#sidebar.size > 1
		return g:tiler#sidebar.size
	else
		return &columns * g:tiler#sidebar.size
	endif
endfunction
" }}}
