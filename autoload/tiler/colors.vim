" FUNCTION: tiler#colors#SetWindowColor(color)
function! tiler#colors#SetWindowColor(color)
	exec "highlight TilerWindowColor ctermbg=" . a:color.cterm . " guibg=" . a:color.gui
	let g:tiler#colors#window = a:color
endfunction
" FUNCTION: tiler#colors#SetCurrentColor(color)
function! tiler#colors#SetCurrentColor(color)
	exec "highlight TilerCurrentColor ctermbg=" . a:color.cterm . " guibg=" . a:color.gui
	let g:tiler#colors#current = a:color
endfunction
" FUNCTION: tiler#colors#SetSidebarColor(color)
function! tiler#colors#SetSidebarColor(color)
	exec "highlight TilerSidebarColor ctermbg=" . a:color.cterm . " guibg=" . a:color.gui
	let g:tiler#colors#sidebar = a:color
endfunction
