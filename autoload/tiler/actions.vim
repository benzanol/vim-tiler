" ==============================================================================
" User level actions
" ==============================================================================
" FUNCTION: tiler#actions#Split(direction, after) {{{1
function! tiler#actions#Split(direction, after)
	let pane = tiler#api#GetPane("window", win_getid())
	if pane == {}
		call tiler#display#Render()
		return
	endif

	" Create the split for the pane
	if a:direction == "v"
		let old_split_dir = &splitbelow
		exec "set " . (a:after ? "" : "no") . "splitbelow"
		new
		exec "set " . (old_split_dir ? "" : "no") . "splitbelow"
	else
		let old_split_dir = &splitright
		exec "set " . (a:after ? "" : "no") . "splitright"
		vnew
		exec "set " . (old_split_dir ? "" : "no") . "splitright"
	endif

	let current_id = pane.id
	call tiler#api#SetCurrent(tiler#layout#AddPane({"layout":"w", "window":win_getid()}, current_id, a:direction, a:after))

	" Set the sizes of the panes and return to the origional window
	call tiler#display#LoadPanes(tiler#api#GetLayout(), [0], g:wm#always_resize ? [1, 1] : [], 1)
	call win_gotoid(tiler#api#GetCurrent().window)
endfunction
" }}}
" FUNCTION: tiler#actions#Close() {{{1
function! tiler#actions#Close()
	if index(g:wm#sidebar.windows, win_getid()) != -1
		call tiler#sidebar#ToggleSidebarOpen()
		return
	endif

	let window = winnr()
	let was_empty = bufname() == ""
	let pane = tiler#api#GetPane("window", win_getid())
	
	if g:wm#sidebar.focused
		call win_gotoid(g:wm#sidebar.windows[0])
	else
		call win_gotoid(tiler#api#GetCurrent().window)
	endif
	
	exec 'silent!' window 'close!'
	
	if was_empty
		call tiler#display#ClearEmpty()
	endif

	if pane == {} || len(pane.id) <= 1
		return
	endif

	call tiler#api#SetCurrent(tiler#layout#RemovePane(pane.id))

	" Set the sizes of the panes and return to the origional window
	call tiler#display#LoadPanes(tiler#api#GetLayout(), [0], g:wm#always_resize ? [1, 1] : [], 1)
	call win_gotoid(tiler#api#GetCurrent().window)
endfunction
" }}}
" FUNCTION: tiler#actions#Move(direction, value) {{{1
function! tiler#actions#Move(direction, value)
	let pane = tiler#api#GetPane("window", win_getid())
	if pane == {} || !has_key(pane, "id") || len(pane.id) <= 1
		return
	endif

	let id = pane.id
	let parent = tiler#api#GetPane("id", id[0:-2])
	let parents_parent = tiler#api#GetPane("id", id[0:-3])

	" Move the pane out of its current parent
	if parent.layout != a:direction
		call tiler#layout#RemovePane(pane.id)
		call tiler#layout#AddPane(pane, id[0:-2], a:direction, a:value)

		" If the pane is on the end of its parent, move it out
	elseif (id[-1] == 0 && a:value == 0) || (id[-1] == len(parent.children) - 1 && a:value == 1)
		if parent.id == [0]
			return
		endif

		call tiler#actions#Move(a:direction == "v" ? "h" : "v", 1)
		call tiler#actions#Move(a:direction, a:value)

		" If there are only 2 panes in the parent, swap their places
	elseif len(parent.children) == 2
		let parent.children = [parent.children[1], parent.children[0]]

		" Group the pane with the next pane in the parent
	else
		let location_pane = parent.children[id[-1] + (a:value ? 1 : -1)]
		call tiler#layout#RemovePane(pane.id)
		call tiler#layout#AddPane(pane, location_pane.id, a:direction == "v" ? "h" : "v", 1)
	endif

	call tiler#display#Render()
	call win_gotoid(pane.window)
endfunction
" }}}
" FUNCTION: tiler#actions#Resize(direction, amount) {{{1
function! tiler#actions#Resize(direction, amount)
	if index(g:wm#sidebar.windows, win_getid()) > -1
		if g:wm#sidebar.size > 1
			let g:wm#sidebar.size += 1.0 * &columns * a:amount
			exec "vertical resize " . string(g:wm#sidebar.size)
		else
			let g:wm#sidebar.size += a:amount
			exec "vertical resize " . string(&columns * g:wm#sidebar.size)
		endif
		return
	endif

	if !g:wm#always_resize
		if a:direction == "h"
			exec "vertical resize " . string(winwidth(0) + &columns * a:amount)
		else
			exec "resize " . string(winheight(0) + &lines * a:amount)
		endif
		return
	endif

	let pane = tiler#api#GetPane("window", win_getid())
	if pane == {}
		return
	endif
	let id = pane.id

	if len(id) >= 2 && tiler#api#GetPane("id", id[0:-2]).layout == a:direction
		let parent = tiler#api#GetPane("id", id[0:-2])
		let pane = tiler#api#GetPane("id", id)
	elseif len(id) >= 3
		let pane = tiler#api#GetPane("id", id[0:-2])
		let parent = tiler#api#GetPane("id", id[0:-3])
	else
		return
	endif

	let pane.size += a:amount
	let reduce_factor = 1.0 * a:amount / (len(parent.children) - 1.0)
	for q in parent.children
		if q.id != pane.id
			let q.size -= reduce_factor
		endif
	endfor

	call tiler#display#LoadPanes(tiler#api#GetLayout(), [0], [1, 1], 1)
endfunction
" }}}
