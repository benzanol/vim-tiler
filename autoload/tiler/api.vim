" ==============================================================================
" API Functions
" ==============================================================================
"FUNCTION: tiler#api#IsEnabled() {{{1
function! tiler#api#IsEnabled()
	if has_key(g:tiler#layouts, tabpagenr())
		return 1
	else
		return 0
	endif
endfunction
" }}}

"FUNCTION: tiler#api#GetNewLayout() {{{1
function! tiler#api#GetNewLayout()
	let new_layout = {}

	let new_layout.id = [0]
	let new_layout.layout = "w"
	let new_layout.buffer = 1
	let new_layout.size = 1
	let new_layout.window = win_getid()

	return new_layout
endfunction
" }}}
"FUNCTION: tiler#api#AddLayout() {{{1
function! tiler#api#AddLayout()
	if tiler#api#IsEnabled()
		return 0
	else
		let g:tiler#layouts[tabpagenr()] = tiler#api#GetNewLayout()
	endif
endfunction
" }}}

"FUNCTION: tiler#api#GetLayout() {{{1
function! tiler#api#GetLayout()
	if !tiler#api#IsEnabled()
		return {}
	else
		return g:tiler#layouts[tabpagenr()]
	endif
endfunction
" }}}
"FUNCTION: tiler#api#SetLayout(new_layout) {{{1
function! tiler#api#SetLayout(new_layout)
	if !tiler#api#IsEnabled()
		return 0
	else
		let g:tiler#layouts[tabpagenr()] = a:new_layout
		return 1
	endif
endfunction
" }}}

"FUNCTION: tiler#api#GetCurrent() {{{1
function! tiler#api#GetCurrent()
	if !tiler#api#IsEnabled()
		return {}
	else
		return g:tiler#currents[tabpagenr()]
	endif
endfunction
" }}}
"FUNCTION: tiler#api#SetCurrent(new_current) {{{1
function! tiler#api#SetCurrent(new_current)
	if !tiler#api#IsEnabled()
		return 0
	else
		let g:tiler#currents[tabpagenr()] = a:new_current
		return 1
	endif
endfunction
" }}}

" FUNCTION: tiler#api#GetPane(datapoint, value) {{{1
function! tiler#api#GetPane(datapoint, value)
	let layout = tiler#api#GetLayout()
	
	if a:datapoint == "id"
		if a:value == [0]
			return layout
		elseif len(a:value) <= 1
			return {}
		endif

		let pane = layout
		for i in range(1, len(a:value) - 1)
			let id_char = a:value[i]
			if !has_key(pane, "children") || len(pane.children) <= id_char
				return {}
			endif

			let pane = pane.children[id_char]
		endfor

		return pane

	else
		let checkpanes = [layout]

		while len(checkpanes) > 0
			if has_key(checkpanes[0], a:datapoint) && checkpanes[0][a:datapoint] == a:value
				return checkpanes[0]
			endif

			if has_key(checkpanes[0], "children")
				let checkpanes += checkpanes[0].children
			endif

			call remove(checkpanes, 0)
		endwhile

		return {}
	endif
endfunction
" }}}
