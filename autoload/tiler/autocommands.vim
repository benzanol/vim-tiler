" ==============================================================================
" Autocmd functions
" ==============================================================================
" FUNCTION: s:WindowMoveEvent() {{{1
function! s:WindowMoveEvent()
	" If the window is part of the sidebar, make the sidebar focussed
	if has_key(g:tiler#sidebar, 'windows') && index(g:tiler#sidebar.windows, win_getid()) != -1
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

" FUNCTION: tiler#autocommands#DisableAutocommands() {{{1
function! tiler#autocommands#DisableAutocommands()
	augroup tiler
		autocmd!
	augroup END
endfunction
" }}}
" FUNCTION: tiler#autocommands#EnableAutocommands() {{{1
function! tiler#autocommands#EnableAutocommands()
	augroup tiler
		autocmd WinEnter * if tiler#api#IsEnabled() | call s:WindowMoveEvent() | endif
		autocmd BufEnter * if tiler#api#IsEnabled() | call s:NewBufferEvent() | endif
		autocmd VimResized * if tiler#api#IsEnabled() | call tiler#display#Render() | endif
	augroup END
endfunction
" }}}
