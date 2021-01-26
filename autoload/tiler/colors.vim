" Functions for highlighting different types of windows
function! tiler#colors#HighlightWindow()
	if exists("g:tiler#colors#window") && g:tiler#colors#enabled
		setlocal winhl=Normal:TilerWindowColor,SignColumn:TilerWindowColor
	endif
endfunction

function! tiler#colors#HighlightCurrent()
	if exists("g:tiler#colors#current") && g:tiler#colors#enabled
		setlocal winhl=Normal:TilerCurrentColor,SignColumn:TilerCurrentColor
	endif
endfunction

function! tiler#colors#HighlightSidebar()
	if exists("g:tiler#colors#sidebar") && g:tiler#colors#enabled
		setlocal winhl=Normal:TilerSidebarColor,SignColumn:TilerSidebarColor
	endif
endfunction

" Enable or disable the 2 color environment
function! tiler#colors#Enable()
	let g:tiler#colors#enabled = 1

	if !exists("g:tiler#colors#window")
		echoerr "No color specified for windows"
	endif
	if !exists("g:tiler#colors#sidebar")
		echoerr "No color specified for the sidebar"
	endif

	for q in g:tiler#colors#background_groups
		exec "highlight " . q . " ctermbg=" . g:tiler#colors#sidebar.cterm . " guibg=" . g:tiler#colors#sidebar.gui
	endfor

	call tiler#display#LoadLayout(0)
endfunction

function! tiler#colors#Disable()
	let g:tiler#colors#enabled = 0

	if !exists("g:tiler#colors#window")
		echoerr "No color specified for windows"
	endif

	for q in g:tiler#colors#background_groups
		exec "highlight " . q . " ctermbg=" . g:tiler#colors#window.cterm . " guibg=" . g:tiler#colors#window.gui
	endfor

	call tiler#display#LoadLayout(0)
endfunction

function! tiler#colors#Toggle()
	if g:tiler#colors#enabled
		call tiler#colors#Disable()
	else
		call tiler#colors#Enable()
	endif
endfunction
