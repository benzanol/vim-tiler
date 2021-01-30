" ==============================================================================
" User level actions
" ==============================================================================
" FUNCTION: tiler#actions#Split(direction, after) {{{1
function! tiler#actions#Split(direction, after)
	" Exit if not currently active
	if !tiler#api#IsEnabled()
		echo "Tiler is not active on this tab. Run 'call tiler#TabEnable()' to activate it."
		return
	endif

	let pane = tiler#api#GetPane("window", win_getid())
	if pane == {}
		call tiler#display#Render()
		return
	endif

	" Create the split for the pane
	if a:direction == "v"
		let old_split_dir = &splitbelow
		execute "set " . (a:after ? "" : "no") . "splitbelow"
		new
		execute "set " . (old_split_dir ? "" : "no") . "splitbelow"
	else
		let old_split_dir = &splitright
		execute "set " . (a:after ? "" : "no") . "splitright"
		vnew
		execute "set " . (old_split_dir ? "" : "no") . "splitright"
	endif

	let g:one = bufnr()
	let current_id = pane.id
	let new_window = tiler#layout#AddPane({"layout":"w", "window":win_getid()}, current_id, a:direction, a:after)
	let g:two = bufnr()
	let new_window.buffer = bufnr()
	call tiler#api#SetCurrent(new_window)

	" Set the sizes of the panes and return to the origional window
	call tiler#display#LoadLayout(-1)
	call win_gotoid(tiler#api#GetCurrent().window)
endfunction
" }}}
" FUNCTION: tiler#actions#Close() {{{1
function! tiler#actions#Close()
	" Run the close command if tiler is not currently active
	if !tiler#api#IsEnabled()
		close!

		" Close the sidebar if it is focused
	elseif index(g:tiler#sidebar.windows[tabpagenr()], win_getid()) != -1
		call tiler#sidebar#ToggleSidebarOpen()

		" Close the current window if it is part of the layout, but not the root
	elseif tiler#api#GetPane("window", win_getid()) != {}
		let pane = tiler#api#GetPane("window", win_getid())
		if len(pane.id) > 1
			" Close the window, but only delete the buffer if it is empty 
			if bufname(0) == ''
				silent! quit!
			else
				silent! close!
			endif

			call tiler#api#SetCurrent(tiler#layout#RemovePane(pane.id))
			call tiler#display#LoadLayout(-1)
		endif

		" Run the close command if tiler is enabled but the current window is not
		" part of the layout
	else
		silent! close!

	endif
endfunction
" }}}
" FUNCTION: tiler#actions#Move(direction, value) {{{1
function! tiler#actions#Move(direction, value)
	" Exit if not currently active
	if !tiler#api#IsEnabled()
		echo "Tiler is not active on this tab. Run 'call tiler#TabEnable()' to activate it."
		return
	endif

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
	" Exit if not currently active
	if !tiler#api#IsEnabled()
		if direction == "h"
			execute "vertical resize " . string(winwidth(0) + &columns * a:amount)
		else
			execute "resize " . string(winheight(0) + &lines * a:amount)
		endif
		return
	endif

	" If the current window is part of the sidebar
	if index(g:tiler#sidebar.windows[tabpagenr()], win_getid()) != -1
		" Reset the size to 0 if it is bugged
		if g:tiler#sidebar.size < 0
			let g:tiler#sidebar.size = 0
		endif

		" If the size is in terms of pixels
		if g:tiler#sidebar.size > 1
			let g:tiler#sidebar.size += 1.0 * &columns * a:amount
			execute "vertical resize " . string(g:tiler#sidebar.size)
			" If the size is in terms of a percent
		else
			let g:tiler#sidebar.size += a:amount
			execute "vertical resize " . string(&columns * g:tiler#sidebar.size)
		endif
		return
	endif

	" Return if the current window is not part of the list
	let pane = tiler#api#GetPane("window", win_getid())
	if pane == {}
		return
	endif
	let id = pane.id

	" If it is not a top level window
	if len(id) >= 2 && tiler#api#GetPane("id", id[0:-2]).layout == a:direction
		let parent = tiler#api#GetPane("id", id[0:-2])
		let pane = tiler#api#GetPane("id", id)
		" If the parent is not a top level window
	elseif len(id) >= 3
		let pane = tiler#api#GetPane("id", id[0:-2])
		let parent = tiler#api#GetPane("id", id[0:-3])
	else
		return
	endif

	" Set the size to 1 or 0 if it is outside the correct range
	let pane.size += a:amount
	if pane.size > 1
		let pane.size = 1
	elseif pane.size < 0
		let pane.size = 0
	endif

	" Reduce the rest of the windows in the layout accordingly
	let reduce_factor = 1.0 * a:amount / (len(parent.children) - 1.0)
	for q in parent.children
		if q.id != pane.id
			let q.size -= reduce_factor
		endif
	endfor

	" Manualy resize the window if always resize is disabled
	if !g:tiler#always_resize
		if a:direction == "h"
			execute "vertical resize " . string(winwidth(0) + &columns * a:amount)
		else
			execute "resize " . string(winheight(0) + &lines * a:amount)
		endif
		return

	else
		call tiler#display#LoadLayout(1)
	endif
endfunction
" }}}
