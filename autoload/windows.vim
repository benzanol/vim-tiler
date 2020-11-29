" ==============================================================================
" Initialization functions
" ==============================================================================
" FUNCTION: windows#Enable() {{{1
function! windows#Enable()
	let g:wm_layout = {"num":0,"id":[0], "layout":"w", "buffer":1, "size":1, "actual_size":[1,1]}
	let g:current_pane = g:wm_layout " The current pane not including the sidebar
	let g:max_num = 1

	let g:wm_sidebar = {"open":0, "focused":0, "size":40, "side":"left", "windows":[], "bars":[]}
	let g:wm_bottombar = {"open":0, "focused":0, "size":60, "window":"", "bars":[]}

	call s:InitializeMappings()

	autocmd VimResized * call windows#Render()
	autocmd WinEnter * call windows#WindowMoveEvent()
	autocmd BufEnter * call windows#NewBufferEvent()

	call windows#Render()
endfunction
" }}}
" FUNCTION: s:InitializeMappings() {{{1
function! s:InitializeMappings()
	nnoremap <silent> <C-c> :call windows#Close()<CR>
	nnoremap <silent> <C-w>r :call windows#Render()<CR>
	nnoremap <silent> <F6> :call windows#ToggleSidebarOpen()<CR>
	nnoremap <silent> <F7> :call windows#ToggleSidebarFocus()<CR>

	nnoremap <silent> <A-k> :call windows#Move("v", 0)<CR>
	nnoremap <silent> <A-j> :call windows#Move("v", 1)<CR>
	nnoremap <silent> <A-h> :call windows#Move("h", 0)<CR>
	nnoremap <silent> <A-l> :call windows#Move("h", 1)<CR>

	nnoremap <silent> <A-K> :call windows#Split("v", 0)<CR>
	nnoremap <silent> <A-J> :call windows#Split("v", 1)<CR>
	nnoremap <silent> <A-H> :call windows#Split("h", 0)<CR>
	nnoremap <silent> <A-L> :call windows#Split("h", 1)<CR>

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
	" Prepare for rendering {{{2
	" Disable autocommands
	autocmd! WinEnter
	autocmd! BufEnter
	autocmd! BufLeave

	" Generate various variables
	let g:wm_layout.size = 1
	let g:wm_layout = g:GenerateIds(g:wm_layout, [0])

	if exists("g:wm_sidebar_color")
		exec "highlight WmSidebarColor ctermbg=" . g:wm_sidebar_color.cterm . " guibg=" . g:wm_sidebar_color.gui
		exec "highlight Normal ctermbg=" . g:wm_sidebar_color.cterm . " guibg=" . g:wm_sidebar_color.gui
	endif
	if exists("g:wm_window_color")
		exec "highlight WmWindowColor ctermbg=" . g:wm_window_color.cterm . " guibg=" . g:wm_window_color.gui
	endif
	if exists("g:wm_current_color")
		exec "highlight WmCurrentColor ctermbg=" . g:wm_current_color.cterm . " guibg=" . g:wm_current_color.gui
	endif
	" }}}
	" Generate the starting window layout, with only the sidebar and bottombar {{{2
	let sidebar_size = 0
	let bottombar_size = 0

	" Close all windows except for sidebar windows, and the current window
	wincmd J | wincmd L
	let windows_window = win_getid()

	if g:wm_sidebar.open || g:wm_bottombar.open
		let last_window = winnr("$")
		for i in range(1, last_window - 1)
			let close_window = last_window - i
			if index(g:wm_sidebar.windows, win_getid(close_window)) == -1 && win_getid(close_window) != g:wm_bottombar.window
				exec string(close_window) . "close"
			endif
		endfor
	else
		let last_window = winnr("$")
		for i in range(1, last_window - 1)
			let close_window = last_window - i
			exec string(close_window) . "close"
		endfor
	endif

	" Load the sidebar
	if g:wm_sidebar.open
		let g:did = "already open"
		" Generate the new sidebar, and figure out the windows that it adds
		if g:wm_sidebar.windows == []
			" If the sidebar has been loaded in the past
			if exists("g:wm_sidebar.current.buffers") && g:wm_sidebar.current.buffers != []
				let g:did = "loaded from buffer"
				for q in g:wm_sidebar.current.buffers
					new | exec "buffer " . q
					call add(g:wm_sidebar.windows, win_getid())
				endfor

			else
				let g:did = "create buffers"
				let before_winids = []
				for i in range(1, winnr("$"))
					call add(before_winids, win_getid(i))
				endfor
				exec g:wm_sidebar.current.command
				let after_winids = []
				for i in range(1, winnr("$"))
					call add(after_winids, win_getid(i))
				endfor
				let g:wm_sidebar.current.buffers = []
				for q in after_winids
					if index(before_winids, q) == -1
						call add(g:wm_sidebar.windows, q)
						call win_gotoid(q)
						call add(g:wm_sidebar.current.buffers, bufnr())
					endif
				endfor
			endif
		endif

		" Move the sidebar windows into a column and set settings
		for i in range(len(g:wm_sidebar.windows))
			call win_gotoid(g:wm_sidebar.windows[i])
			wincmd J

			setlocal nobuflisted
			setlocal hidden
			setlocal nonumber
			setlocal winfixwidth
			setlocal laststatus=0
			
			if exists("g:wm_sidebar_color")
				setlocal winhl=Normal:WmSidebarColor
			endif
		endfor

		" Move the origional window to the right
		call win_gotoid(windows_window)
		wincmd L

		" Figure out the size and resize the sidebar
		call win_gotoid(g:wm_sidebar.windows[0])
		if g:wm_sidebar.size > 1
			let sidebar_size = g:wm_sidebar.size
		else
			let sidebar_size = &columns * g:wm_sidebar.size
		endif
		exec "vertical resize " . string(sidebar_size)
	endif

	" Replace the origional window with a blank one
	call win_gotoid(windows_window)
	let old_window_nr = winnr()
	new | let windows_window = win_getid()
	exec old_window_nr . "close"

	" }}}
	" Load the window layout {{{2
	let g:window_list = []
	call g:LoadPane(g:wm_layout, [1, 1])

	" Set the sizes of all of the windows in the window list
	for q in g:window_list " For each level of window
		for r in q " For each individual window
			call win_gotoid(r.winid)
			exec "vertical resize " . string((&columns - sidebar_size) * r.size[0])
			" Subtract 1 because of statusline of each window
			exec "resize " . string((&lines - bottombar_size) * r.size[1] - 1)
			setlocal winfixheight
			setlocal winfixwidth

			" Set it to the default window color
			if exists("g:wm_window_color")
				setlocal winhl=Normal:WmWindowColor
			endif
		endfor
	endfor
	if g:wm_sidebar.open
		call win_gotoid(g:wm_sidebar.windows[0])
		exec "vertical resize " . string(sidebar_size)
	endif

	" Return to the origional window
	if g:wm_sidebar.focused
		call win_gotoid(g:wm_sidebar.windows[0])
	else
		call win_gotoid(g:current_pane.window)

		" Set the color of the current window if a special color is specified
		if exists("g:wm_current_color")
			setlocal winhl=Normal:WmCurrentColor
		endif
	endif
	" }}}
	" Run post rendering commands {{{2
	" Reenable autocommands
	autocmd WinEnter * call windows#WindowMoveEvent()
	autocmd BufEnter * call windows#NewBufferEvent()

	if exists("g:wm_current_color")
		autocmd BufEnter * silent! if win_getid() != g:wm_sidebar.window | setlocal winhl=Normal:WmCurrentColor | endif
		autocmd BufLeave * silent! if win_getid() != g:wm_sidebar.window | setlocal winhl=Normal:WmWindowColor | endif
	endif
	" }}}
endfunction
" }}}
" FUNCTION: windows#Split(direction, after) {{{1
function! windows#Split(direction, after)
	let current_id = g:GetPane("window", win_getid()).id
	let new_pane = {"layout":"w"}

	let g:current_pane = g:AddPane(new_pane, current_id, a:direction, a:after)
	call windows#Render()
endfunction
" }}}
" FUNCTION: windows#Close() {{{1
function! windows#Close()
	let remove_id = g:GetPane("window", win_getid()).id
	let g:current_pane = g:RemovePane(remove_id)
	call windows#Render()
endfunction
" }}}
" FUNCTION: windows#Move(direction, value) {{{1
function! windows#Move(direction, value)
	let pane = g:GetPane("window", win_getid())
	let id = pane.id
	let parent = g:GetPane("id", id[0:-2])
	let parents_parent = g:GetPane("id", id[0:-3])

	" Move the pane out of its current parent
	if parent.layout != a:direction
		call g:RemovePane(pane.id)
		call g:AddPane(pane, id[0:-2], a:direction, a:value)

		" If the pane is on the end of its parent, move it out
	elseif (id[-1] == 0 && a:value == 0) || (id[-1] == len(parent.children) - 1 && a:value == 1)
		if parent.id == [0]
			return
		endif

		call windows#Move(a:direction == "v" ? "h" : "v", 1)
		call windows#Move(a:direction, a:value)

		" If there are only 2 panes in the parent, swap their places
	elseif len(parent.children) == 2
		let parent.children = [parent.children[1], parent.children[0]]

		" Group the pane with the next pane in the parent
	else
		let location_pane = parent.children[id[-1] + (a:value ? 1 : -1)]
		call g:RemovePane(pane.id)
		call g:AddPane(pane, location_pane.id, a:direction == "v" ? "h" : "v", 1)
	endif

	call windows#Render()
	call win_gotoid(pane.window)
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
	if g:wm_sidebar.open " Disable the sidebar if it is already active
		let g:wm_sidebar.open = 0
		let g:wm_sidebar.focused = 0
		let g:wm_sidebar.windows = []
	else " Enable the sidebar if it is not already active
		let g:wm_sidebar.open = 1
		let g:wm_sidebar.focused = 1 
	endif

	call windows#Render()
endfunction
" }}}
" FUNCTION: windows#ToggleSidebarFocus() {{{1
function! windows#ToggleSidebarFocus()
	if !g:wm_sidebar.open
		call windows#ToggleSidebarOpen()

	elseif g:wm_sidebar.focused
		let g:wm_sidebar.focused = 0

	else
		let g:wm_sidebar.focused = 1
	endif

	call windows#Render()
endfunction
" }}}
" FUNCTION: windows#OpenSidebar(name) {{{1
function! windows#OpenSidebar(name)
	if a:name == g:wm_sidebar.current
		call windows#ToggleSidebarOpen()
	else
		let g:wm_sidebar.current = a:name
		let g:wm_sidebar.open = 1
		let g:wm_sidebar.focused = 1
		call windows#Render()
	endif
endfunction
" }}}

" FUNCTION: windows#ToggleBottombarOpen() {{{1
function! windows#ToggleBottombarOpen()
	if g:wm_bottombar.open " Disable the bottombar if it is already active
		let g:wm_bottombar.open = 0
		let g:wm_bottombar.focused = 0
	else " Enable the bottombar if it is not already active
		let g:wm_bottombar.open = 1
		let g:wm_bottombar.focused = 1 
	endif

	call windows#Render()
endfunction
" }}}
" FUNCTION: windows#ToggleBottombarFocus() {{{1
function! windows#ToggleBottombarFocus()
	if !g:wm_bottombar.open
		call windows#ToggleBottombarOpen()

	elseif g:wm_bottombar.focused
		let g:wm_bottombar.focused = 0

	else
		let g:wm_bottombar.focused = 1
	endif

	call windows#Render()
endfunction
" }}}
" FUNCTION: windows#OpenBottombar(name) {{{1
function! windows#OpenBottombar(name)
	if a:name == g:wm_bottombar.current
		call windows#TogglebottombarOpen()
	else
		let g:wm_bottombar.current = a:name
		let g:wm_bottombar.open = 1
		let g:wm_bottombar.focused = 1
		call windows#Render()
	endif
endfunction
" }}}

" ==============================================================================
" Background functions
" ==============================================================================
" FUNCTION: g:GetPane(datapoint, value) {{{1
function! g:GetPane(datapoint, value)
	if a:datapoint == "id"
		if a:value == [0]
			return g:wm_layout
		elseif len(a:value) <= 1
			return {}
		endif

		let pane = g:wm_layout
		for i in range(1, len(a:value) - 1)
			let id_char = a:value[i]
			if !has_key(pane, "children") || len(pane.children) <= id_char
				return {}
			endif

			let pane = pane.children[id_char]
		endfor

		return pane

	else
		let checkpanes = [g:wm_layout]

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

	let g:wm_layout = g:GenerateIds(g:wm_layout, [0])
	return a:new_pane
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

		let g:wm_layout = g:GenerateIds(g:wm_layout, [0])

		" If the dissolved split now has the same layout as its parent
		let new_parent = g:GetPane("id", a:id[0:-2])
		if len(a:id) >= 3 && new_parent.layout == g:GetPane("id", a:id[0:-3]).layout
			let super_parent = g:GetPane("id", a:id[0:-3])
			call g:ReplacePane(new_parent.children[0], new_parent.id)

			let g:wm_layout = g:GenerateIds(g:wm_layout, [0])

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

	let g:wm_layout = g:GenerateIds(g:wm_layout, [0])

	let new_window_id = new_pane.id[0:-1]
	while has_key(g:GetPane("id", new_window_id), "children")
		call add(new_window_id, len(g:GetPane("id", new_window_id).children) - 1)
	endwhile

	return g:GetPane("id", new_window_id)
endfunction
" }}}
" FUNCTION: g:ReplacePane(new_pane, location_id) {{{1
function! g:ReplacePane(new_pane, location_id)
	if a:location_id == [0]
		let g:wm_layout = a:new_pane
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
	if index(g:wm_sidebar.windows, win_getid()) != -1
		let g:wm_sidebar.focused = 1
	elseif g:GetPane("window", win_getid()) != {}
		let g:wm_sidebar.focused = 0 
		let g:current_pane = g:GetPane("window", win_getid())
	endif
endfunction
" }}}
" FUNCTION: windows#NewBufferEvent() {{{1
function! windows#NewBufferEvent()
	if g:wm_sidebar.focused
		if exists("g:wm_sidebar_color")
			setlocal winhl=Normal:WmSidebarColor
		endif

	else
		if exists("g:wm_window_color")
			setlocal winhl=Normal:WmWindowColor
		endif

		if g:current_pane.window == win_getid()
			let g:current_pane.buffer = bufnr()
		endif
	endif

endfunction
" }}}
