" ==============================================================================
" Sidebar actions
" ==============================================================================
" FUNCTION: tiler#sidebar#ToggleSidebarOpen() {{{1
function! tiler#sidebar#ToggleSidebarOpen()
	if g:wm#sidebar.open " Disable the sidebar if it is already active
		let g:wm#sidebar.open = 0
		let g:wm#sidebar.focused = 0
		let g:wm#sidebar.current = {}
		let g:wm#sidebar.windows = []
	else " Enable the sidebar if it is not already active
		let g:wm#sidebar.open = 1
		let g:wm#sidebar.focused = 1 
	endif

	call tiler#display#Render()
endfunction
" }}}
" FUNCTION: tiler#sidebar#ToggleSidebarFocus() {{{1
function! tiler#sidebar#ToggleSidebarFocus()
	if !g:wm#sidebar.open
		call tiler#sidebar#ToggleSidebarOpen()

	elseif g:wm#sidebar.focused
		let g:wm#sidebar.focused = 0

	else
		let g:wm#sidebar.focused = 1
	endif

	call win_gotoid(g:wm#sidebar.windows[0])
endfunction
" }}}
" FUNCTION: tiler#sidebar#OpenSidebar(name) {{{1
function! tiler#sidebar#OpenSidebar(name)
	let g:wm#sidebar.open = 1
	let g:wm#sidebar.focused = 1
	if !exists("g:wm#sidebar.current.name") || a:name != g:wm#sidebar.current.name
		for q in g:wm#sidebar.bars
			if has_key(q, "name") && q.name == a:name
				let g:wm#sidebar.current = q
				break
			endif
		endfor
		call tiler#display#Render()
	else
		call tiler#display#LoadPanes(tiler#api#GetLayout(), [0], g:wm#always_resize ? [1, 1] : [], 1)
	endif
endfunction
" }}}
