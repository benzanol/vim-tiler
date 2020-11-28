" ==============================================================================
" Initialization functions
" ==============================================================================
" FUNCTION: windows#Enable() {{{1
function! windows#Enable()
	let g:layout = {"num":0,"id":[0], "layout":"w", "buffer":1, "size":1, "actual_size":[1,1]}
	let g:current_pane = g:layout " The current pane not including the sidebar
	let g:max_num = 1

	let g:sidebar = {"open":0, "focused":0, "size":0.2, "side":"left", "buffers":[], "window":"", "command":"vsplit"}

	call s:InitializeMappings()

	autocmd VimResized * call windows#Render()
	autocmd WinEnter * call windows#WindowMoveEvent()
	autocmd BufEnter * call windows#NewBufferEvent()

	call windows#Render()
endfunction
" }}}
" FUNCTION: s:InitializeMappings() {{{1
function! s:InitializeMappings()
	nnoremap <C-c> :call windows#Close(["current"])<CR>
	nnoremap <C-w>r :call windows#Render()<CR>
	nnoremap <F6> :call windows#ToggleSidebarOpen()<CR>
	nnoremap <F7> :call windows#ToggleSidebarFocus()<CR>

	nnoremap <A-k> :call windows#Move("v", 0)<CR>
	nnoremap <A-j> :call windows#Move("v", 1)<CR>
	nnoremap <A-h> :call windows#Move("h", 0)<CR>
	nnoremap <A-l> :call windows#Move("h", 1)<CR>

	nnoremap <A-K> :call windows#Split("v", 0)<CR>
	nnoremap <A-J> :call windows#Split("v", 1)<CR>
	nnoremap <A-H> :call windows#Split("h", 0)<CR>
	nnoremap <A-L> :call windows#Split("h", 1)<CR>

	noremap <nowait> <silent> = :call windows#Resize("h", 0.015)<CR>
	noremap <nowait> <silent> - :call windows#Resize("h", -0.015)<CR>
	noremap <nowait> <silent> + :call windows#Resize("v", 0.025)<CR>
	noremap <nowait> <silent> _ :call windows#Resize("v", -0.025)<CR>
endfunction
" }}}

" ==============================================================================
" User level functions
" ==============================================================================
" FUNCTION: windows#Render() {{{1
function! windows#Render()
	" Disable autocommands
	autocmd! WinEnter
	autocmd! BufEnter

	" Generate the recursive variables
	let g:layout.size = 1
	let g:layout = g:GenerateIds(g:layout, [0])
	let winwidth = 1.0

	" Remove other splits
	wincmd o

	" Create a sidebar
	if g:sidebar.open
		" Delete the previous sidebar buffer, if there is one
		if exists("g:sidebar.buffer")
			exec string(g:sidebar.buffer) . "bdelete!"
		endif

		" Create a window on the left with the correct width
		exec g:sidebar.command
		exec "wincmd " . (g:sidebar.side == "right" ? "L" : "H")
		exec "vertical resize " . string(1.0 * g:sidebar.size * &columns)

		" Set the related variables
		let g:sidebar.window = win_getid()
		let g:sidebar.buffer = bufnr()
		let winwidth = 1.0 - g:sidebar.size

		" Return to the main pane
		wincmd p
	endif

	" Create a list of all windows to be resized at the end
	let g:window_list = []

	" Load the layout of the splits
	call g:LoadPane(g:layout, [1, 1])

	" Resize the sidebar if it is open
	if g:sidebar.open
		call win_gotoid(g:sidebar.window)
		exec "vertical resize " . string(1.0 * g:sidebar.size * &columns)
	endif

	" Set the sizes of all of the windows in the window list
	for q in g:window_list " For each level of window
		for r in q " For each individual window
			call win_gotoid(r.winid)
			exec "vertical resize " . string(1.0 * r.size[0] * &columns * winwidth)
			" Subtract 1 because of statusline of each window
			exec "resize " . string(1.0 * r.size[1] * &lines - 1.0)
			setlocal winfixheight
			setlocal winfixwidth
		endfor
	endfor

	" Resize the sidebar again
	if g:sidebar.open
		call win_gotoid(g:sidebar.window)
		exec "vertical resize " . string(1.0 * g:sidebar.size * &columns)
	endif

	"echo "rendering to " . string(g:current_pane)
	"echo "called by " . string(expand("<sfile>"))
	"call win_gotoid(g:current_pane.window)

	" Return to the origional window
	if g:sidebar.focused
		call win_gotoid(g:sidebar.window)
	else
		call win_gotoid(g:current_pane.window)
	endif

	" Reenable autocommands
	autocmd WinEnter * call windows#WindowMoveEvent()
	autocmd BufEnter * call windows#NewBufferEvent()
endfunction
" }}}
" FUNCTION: windows#Split(direction, after) {{{1
function! windows#Split(direction, after)
	let current_id = g:GetPane("window", win_getid()).id
	let new_pane = {"layout":"w"}

	let num = g:AddPane(new_pane, current_id, a:direction, a:after)
	call windows#Render()

	" Move cursor to the new pane
	call win_gotoid(g:GetPane("num", num).window)
endfunction
" }}}
" FUNCTION: windows#Close() {{{1
function! windows#Close()
	let remove_id = g:GetPane("window", win_getid()).id
	call g:RemovePane(remove_id)
endfunction
" }}}
" FUNCTION: windows#Move(direction, value) {{{1
function! windows#Move(direction, value)
	let g:pane = g:GetPane("window", win_getid())
	let g:id = g:pane.id
	let g:parent = g:GetPane("id", g:id[0:-2])
	let g:parents_parent = g:GetPane("id", g:id[0:-3])

	let g:opt = 0

	" Move the pane out of its current parent
	if g:parent.layout != a:direction
		call windows#Close(["current"])
		call g:AddPane(g:pane, g:id[0:-2], a:direction, a:value)

		" If the pane is on the end of its parent, move it out
	elseif (g:id[-1] == 0 && a:value == 0) || (g:id[-1] == len(g:parent.children) - 1 && a:value == 1)
		if g:parent.id == [0]
			return
		endif

		let g:opt = 6
		call windows#Move(a:direction == "v" ? "h" : "v", 1)
		call windows#Move(a:direction, a:value)

		" If there are only 2 panes in the parent, swap their places
	elseif len(g:parent.children) == 2
		let g:parent.children = [g:parent.children[1], g:parent.children[0]]

		" Group the pane with the next pane in the parent
	else
		let location_pane = g:parent.children[g:id[-1] + (a:value ? 1 : -1)]
		call windows#Close(["current"])
		call g:AddPane(g:pane, location_pane.id, a:direction == "v" ? "h" : "v", 1)
	endif

	call windows#Render()
	call win_gotoid(g:pane.window)
endfunction
" }}}
" FUNCTION: windows#Resize(direction, amount) {{{1
function! windows#Resize(direction, amount)
	let id = g:GetPane("window", win_getid()).id

	if len(id) >= 2 && g:GetPane("id", id[0:-2]).layout == a:direction
		let parent = g:GetPane("id", id[0:-2])
		let pane = g:GetPane("id", id)
	elseif len(id) >= 3
		let pane = g:GetPane("id", id[0:-2])
		let parent = g:GetPane("id", id[0:-3])
	else
		return
	endif

	let g:pan = pane
	let g:par = parent

	let pane.size += a:amount
	let reduce_factor = 1.0 * a:amount / (len(parent.children) - 1.0)
	for q in parent.children
		if q.id != pane.id
			let q.size -= reduce_factor
		endif
	endfor

	call windows#Render()
endfunction
" }}}
" FUNCTION: windows#ToggleSidebarOpen() {{{1
function! windows#ToggleSidebarOpen()
	if g:sidebar.open " Disable the sidebar if it is already active
		let g:sidebar.open = 0
		let g:sidebar.focused = 0
	else " Enable the sidebar if it is not already active
		let g:sidebar.open = 1
		let g:sidebar.focused = 1 
	endif

	call windows#Render()
endfunction
" }}}
" FUNCTION: windows#ToggleSidebarFocus() {{{1
function! windows#ToggleSidebarFocus()
	if !g:sidebar.open
		call windows#ToggleSidebarOpen()

	elseif g:sidebar.focused
		let g:sidebar.focused = 0

	else
		let g:sidebar.focused = 1
	endif

	echo g:sidebar.focused
	call windows#Render()
endfunction
" }}}

" ==============================================================================
" Background functions
" ==============================================================================
" FUNCTION: g:GetPane(datapoint, value) {{{1
function! g:GetPane(datapoint, value)
	if a:datapoint == "id"
		if a:value == [0]
			return g:layout
		elseif len(a:value) <= 1
			return {}
		endif

		let pane = g:layout
		for i in range(1, len(a:value) - 1)
			let id_char = a:value[i]
			if !has_key(pane, "children") || len(pane.children) <= id_char
				return {}
			endif

			let pane = pane.children[id_char]
		endfor

		return pane

	else
		let checkpanes = [g:layout]

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
" FUNCTION: g:LoadPane(pane, size) {{{1
function! g:LoadPane(pane, size)
	let a:pane.actual_size = a:size

	" Open a window
	if a:pane["layout"] == "w"
		" Open the correct buffer in the window if the buffer exists
		if exists("a:pane.buffer") && index(range(1, bufnr("$")), a:pane.buffer) != -1
			exec "buffer " . a:pane.buffer
		endif

		" Give the pane a window number if it doesn't have one already
		let a:pane.window = win_getid()

		" Add the current window to the list of windows to be resized later
		while len(g:window_list) < len(a:pane.id)
			call add(g:window_list, [])
		endwhile
		call add(g:window_list[len(a:pane.id) - 1], {"winid":(a:pane.window), "size":(a:size)})

	else
		" Set up the splits
		let split_cmd = (a:pane.layout == "h") ? "vertical new" : "new"
		let a:pane.children[0].window = win_getid()
		for i in range(1, len(a:pane.children) - 1)
			exec split_cmd
			let a:pane.children[i].window = win_getid()
		endfor

		" Return to each split and set it up
		for i in range(len(a:pane.children))
			" Figure out the new size
			let size_index = a:pane.layout == "h" ? 0 : 1
			let new_size = a:size[0:1]
			let new_size[size_index] = 1.0 * a:size[size_index] * a:pane.children[i].size

			" Go to the window and load it
			call win_gotoid(a:pane.children[i].window)
			call g:LoadPane(a:pane.children[i], new_size)
		endfor

		if has_key(a:pane, "window")
			call remove(a:pane, "window")
		endif
	endif
endfunction
" }}}
" FUNCTION: g:GenerateIds(pane, id) {{{1
function g:GenerateIds(pane, id)
	let a:pane.id = a:id

	if !has_key(a:pane, "children")
		return a:pane
	endif

	let children = a:pane.children
	for i in range(len(children))
		let new_id = a:id + [i]

		let children[i] = g:GenerateIds(children[i], new_id)
	endfor
	return a:pane
endfunction
" }}}
" FUNCTION: g:AddPane(new_pane, location_id, direction, after) {{{1
function! g:AddPane(new_pane, location_id, direction, after)
	let location_pane = g:GetPane("id", a:location_id)

	if location_pane == {}
		echo "Error: Location " . string(a:location_id) . " not found"
		return -1
	endif

	let location_parent = g:GetPane("id", a:location_id[0:-2])

	" The new pane should be added to the list in the location id
	if location_pane.layout == a:direction
		let children = location_pane.children

		" Set the sizes of the windows
		for i in range(len(children))
			let children[i].size = 1.0 * (len(children) / (len(children) + 1.0)) * children[i].size
		endfor
		let a:new_pane.size = 1.0 / (len(children) + 1)

		" Add the windows to the list
		if a:after
			call add(children, a:new_pane)
		else
			call insert(children, a:new_pane, 0)
		endif

		" The new pane should be added to the parent of the location referenced
	elseif location_parent != {} && location_parent.layout == a:direction
		let children = location_parent.children
		let location_index = a:location_id[-1]

		" Set the sizes of the windows
		let g:ratio = (len(children) / (len(children) + 1.0))
		for i in range(len(children))
			let children[i].size = 1.0 * g:ratio * children[i].size
		endfor
		let a:new_pane.size = 1.0 / (len(children) + 1)

		" Add the windows to the list
		if a:after
			call insert(children, a:new_pane, location_index + 1)
		else
			call insert(children, a:new_pane, location_index)
		endif

		" The new pane and the location referenced should be together in a new list
	else
		let new_parent = {"layout":a:direction, "id":a:location_id}
		let new_parent.size = location_pane.size
		let new_parent.children = a:after ? [location_pane, a:new_pane] : [a:new_pane, location_pane]

		call g:ReplacePane(new_parent, a:location_id)

		" Set the window sizes to be 50/50
		let new_parent.children[0].size = 0.5
		let new_parent.children[1].size = 0.5
	endif

	if !has_key(a:new_pane, "num")
		let a:new_pane.num = g:max_num + 1
		let g:max_num += 1
	endif

	let g:layout = g:GenerateIds(g:layout, [0])
	return a:new_pane.num
endfunction
" }}}
" FUNCTION: g:RemovePane(id) {{{1
function! g:RemovePane(id)
	let parent = g:GetPane("id", a:id[0:-2])
	let remove_index = a:id[-1]

	call remove(parent.children, remove_index)

	" If the parent contains a single other window, and should be dissolved
	if len(parent.children) == 1
		let replacement = parent.children[0]
		let replacement.id = parent.id
		let replacement.size = parent.size
		call g:ReplacePane(replacement, parent.id)
		let new_pane = replacement

		let g:layout = g:GenerateIds(g:layout, [0])

		" If the dissolved split now has the same layout as its parent
		let new_parent = g:GetPane("id", a:id[0:-2])
		if len(a:id) >= 3 && new_parent.layout == g:GetPane("id", a:id[0:-3]).layout
			let super_parent = g:GetPane("id", a:id[0:-3])
			call g:ReplacePane(new_parent.children[0], new_parent.id)

			let g:layout = g:GenerateIds(g:layout, [0])

			for i in range(1, len(new_parent.children) - 1)
				call g:AddPane(new_parent.children[i], new_parent.children[0].id, super_parent.layout, 1)
			endfor
		endif

	else " If the remaining windows' sizes need to be updated to fill the empty space
		let ratio = 1.0 * (len(parent.children) + 1.0) / len(parent.children)
		for q in parent.children
			let q.size = 1.0 * q.size * ratio
		endfor
		if len(parent.children) <= remove_index
			let new_pane = parent.children[-1]
		else
			let new_pane = parent.children[remove_index]
		endif
	endif

	call windows#Render()

	let new_window_id = new_pane.id[0:-1]
	while has_key(g:GetPane("id", new_window_id), "children")
		call add(new_window_id, len(g:GetPane("id", new_window_id).children) - 1)
	endwhile

	call win_gotoid(g:GetPane("id", new_window_id).window)
endfunction
" }}}
" FUNCTION: g:ReplacePane(new_pane, location_id) {{{1
function! g:ReplacePane(new_pane, location_id)
	if a:location_id == [0]
		let g:layout = a:new_pane
		return
	endif

	let location_pane = g:GetPane("id", a:location_id)
	let location_parent = g:GetPane("id", a:location_id[0:-2])
	let location_index = index(location_parent.children, location_pane)

	call remove(location_parent.children, location_index)
	call insert(location_parent.children, a:new_pane, location_index)

	if !has_key(a:new_pane, "num")
		let a:new_pane.num = g:max_num + 1
		let g:max_num += 1
	endif
endfunction
" }}}

" ==============================================================================
" Autocmd functions
" ==============================================================================
" FUNCTION: windows#WindowMoveEvent() {{{1
function! windows#WindowMoveEvent()
	if win_getid() == g:sidebar.window
		let g:sidebar.focused = 1
	elseif g:GetPane("window", win_getid()) != {}
		let g:sidebar.focused = 0 
		let g:current_pane = g:GetPane("window", win_getid())
	endif
endfunction
" }}}
" FUNCTION: windows#NewBufferEvent() {{{1
function! windows#NewBufferEvent()
	if !g:sidebar.focused && g:current_pane.window == win_getid()
		let g:current_pane.buffer = bufnr()
	endif

endfunction
" }}}
