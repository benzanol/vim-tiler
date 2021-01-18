" ==============================================================================
" Autocmd functions
" ==============================================================================
" FUNCTION: s:WindowMoveEvent() {{{1
function! s:WindowMoveEvent()
	" If the window is part of the sidebar, make the sidebar focussed
	if has_key(g:tiler#sidebar, 'windows') && index(g:tiler#sidebar.windows[tabpagenr()], win_getid()) != -1
		let g:tiler#sidebar.focused = 1

		" If the window is part of the window layout
	elseif tiler#api#GetPane("window", win_getid()) != {}
		let g:tiler#sidebar.focused = 0
		call tiler#api#SetCurrent(tiler#api#GetPane("window", win_getid()))
	endif
endfunction
" }}}
" FUNCTION: s:NewBufferEvent() {{{1
function! s:NewBufferEvent()
	if g:tiler#sidebar.focused
		if exists("g:tiler#sidebar_color")
			setlocal winhl=Normal:WmSidebarColor
		endif

	else
		if exists("g:wm_window_color")
			setlocal winhl=Normal:WmWindowColor
		endif

		if has_key(tiler#api#GetCurrent(), 'window') && tiler#api#GetCurrent().window == win_getid()
			let current = tiler#api#GetCurrent()
			let current.buffer = bufnr()
		endif
	endif

endfunction
" }}}

" FUNCTION: tiler#autocommands#Disable() {{{1
function! tiler#autocommands#Disable()
	augroup tiler
		autocmd!
	augroup END
endfunction
" }}}
" FUNCTION: tiler#autocommands#Enable() {{{1
function! tiler#autocommands#Enable()
	augroup tiler
		autocmd!
		" Loads colors after entering vim
		autocmd VimEnter * if tiler#api#IsEnabled() | call tiler#display#Render() | endif
		
		" Updates the current pane when switching between windows
		autocmd WinEnter * if tiler#api#IsEnabled() | call s:WindowMoveEvent() | endif
		
		" Updates the buffer of the current pane after switching buffers
		autocmd BufEnter * if tiler#api#IsEnabled() | call s:NewBufferEvent() | endif
		
		" Update the color of a new buffer when opening it
		autocmd BufReadPost * if tiler#api#IsEnabled() | call tiler#colors#HighlightWindow() | endif
		
		" Updates the layout of the panes in real time while resizing vim
		autocmd VimResized * if tiler#api#IsEnabled() | call tiler#display#Render() | endif
		
		" Updates which window is highlighted when switching between them
		if exists("g:tiler#colors#current")
			autocmd WinEnter * silent! if index(g:tiler#sidebar.windows[tabpagenr()], win_getid()) == -1 | setlocal winhl=Normal:TilerCurrentColor | endif
			autocmd WinLeave * silent! if index(g:tiler#sidebar.windows[tabpagenr()], win_getid()) == -1 | setlocal winhl=Normal:TilerWindowColor | endif
		endif
	augroup END
endfunction
" }}}
