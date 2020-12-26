" ==============================================================================
" Initialization functions
" ==============================================================================
" FUNCTION: tiler#TabEnable() {{{1
function! tiler#TabEnable()
	if !exists('g:tiler#loaded')
		let g:tiler#loaded = 1
		let g:tiler#layouts = {}
		let g:tiler#currents = {}
	endif

	if tiler#api#IsEnabled()
		return 0
	endif

	call tiler#api#AddLayout()
	call tiler#api#SetCurrent(tiler#api#GetLayout())

	let g:wm#sidebar = {"open":0, "focused":0, "size":30, "side":"left", "windows":[], "bars":[]}
	let g:wm#sidebar.current = {"name":"blank", "command":"vnew | wincmd H"}
	let g:wm#always_resize = 1

	call s:InitializeCommands()

	call tiler#autocommands#EnableAutocommands()

	call tiler#display#Render()

	return 1
endfunction
" }}}
" FUNCTION: s:InitializeCommands() {{{1
function! s:InitializeCommands()
	command! WindowClose call tiler#actions#Close()
	command! WindowRender call tiler#display#Render()

	command! WindowMoveUp call tiler#actions#Move("v", 0)
	command! WindowMoveDown call tiler#actions#Move("v", 1)
	command! WindowMoveLeft call tiler#actions#Move("h", 0)
	command! WindowMoveRight call tiler#actions#Move("h", 1)

	command! WindowSplitUp call tiler#actions#Split("v", 0)
	command! WindowSplitDown call tiler#actions#Split("v", 1)
	command! WindowSplitLeft call tiler#actions#Split("h", 0)
	command! WindowSplitRight call tiler#actions#Split("h", 1)

	" Recommended resize values for horizontal and vertical are 0.015 and 0.025 respectively
	command! -nargs=1 WindowResizeHorizontal call tiler#actions#Resize("h", <args>)
	command! -nargs=1 WindowResizeVertical call tiler#actions#Resize("v", <args>)

	command! SidebarToggleOpen call tiler#sidebar#ToggleSidebarOpen()
	command! SidebarToggleFocus call tiler#sidebar#ToggleSidebarFocus()
	command! -nargs=1 SidebarOpen call tiler#sidebar#OpenSidebar("<args>")
endfunction
" }}}
