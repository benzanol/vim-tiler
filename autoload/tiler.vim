" ==============================================================================
" Initialization functions
" ==============================================================================
" FUNCTION: tiler#TabEnable() {{{1
function! tiler#TabEnable()
	if tiler#api#IsEnabled()
		return 0
	endif

	call tiler#api#AddLayout()
	call tiler#api#SetCurrent(tiler#api#GetLayout())

	call tiler#autocommands#Enable()
	call tiler#display#Render()

	return 1
endfunction
" }}}
" FUNCTION: tiler#TabDisable() {{{1
function! tiler#TabDisable()
	if !tiler#api#IsEnabled()
		return 0
	endif

	call tiler#api#RemoveLayout()

	return 1
endfunction
" }}}
" FUNCTION: tiler#TabToggle() {{{1
function! tiler#TabToggle()
	if tiler#api#IsEnabled()
		call tiler#TabDisable()
		return 0
	else
		call tiler#TabEnable()
		return 1
	endif
endfunction
" }}}

" FUNCTION: tiler#GlobalEnable() {{{1
function! tiler#GlobalEnable()
	let g:tiler#global = 1

	call tiler#TabEnable()

	augroup tiler_enable
		autocmd TabNewEntered * call tiler#TabEnable()
	augroup END

	return 1
endfunction
" }}}
" FUNCTION: tiler#GlobalDisable() {{{1
function! tiler#GlobalDisable()
	let g:tiler#global = 0

	augroup tiler_enable
		autocmd!
	augroup END

	let g:tiler#layouts = {}
	let g:tiler#currents = {}

	return 1
endfunction
" }}}
" FUNCTION: tiler#GlobalToggle() {{{1
function! tiler#GlobalToggle()
	if g:tiler#global
		call tiler#GlobalDisable()
		return 0
	else
		call tiler#GlobalEnable()
		return 1
	endif
endfunction
" }}}
