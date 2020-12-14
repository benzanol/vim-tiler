" ==============================================================================
" Initialization functions
" ==============================================================================
" FUNCTION: windows:WindowManagerEnable() {{{1
function! windows#WindowManagerEnable()
	let new_layout = s:GetNewLayout()
	let g:wm_tab_layouts = [new_layout]
	let g:current_pane = [new_layout]
	let g:tab = 0

	let g:wm_sidebar = {"open":0, "focused":0, "size":30, "side":"left", "windows":[], "bars":[]}
	let g:wm_sidebar.current = {"name":"blank", "command":"vnew | wincmd H"}

	call s:InitializeCommands()

	call s:EnableAutocommands()
	autocmd VimResized * call s:Render()

	call s:Render()
endfunction
" }}}
" FUNCTION: s:InitializeCommands() {{{1
function! s:InitializeCommands()
	command! WindowClose call s:Close()
	command! WindowRender call s:Render()

	command! WindowMoveUp call s:Move("v", 0)
	command! WindowMoveDown call s:Move("v", 1)
	command! WindowMoveLeft call s:Move("h", 0)
	command! WindowMoveRight call s:Move("h", 1)

	command! WindowSplitUp call s:Split("v", 0)
	command! WindowSplitDown call s:Split("v", 1)
	command! WindowSplitLeft call s:Split("h", 0)
	command! WindowSplitRight call s:Split("h", 1)

	" Recommended resize values for horizontal and vertical are 0.015 and 0.025 respectively
	command! -nargs=1 WindowResizeHorizontal call s:Resize("h", <args>)
	command! -nargs=1 WindowResizeVertical call s:Resize("v", <args>)

	command! SidebarToggleOpen call s:ToggleSidebarOpen()
	command! SidebarToggleFocus call s:ToggleSidebarFocus()
	command! -nargs=1 SidebarOpen call s:OpenSidebar("<args>")
endfunction
" }}}
" FUNCTION: s:GetNewLayout() {{{1
function! s:GetNewLayout()
	let new_layout = {}

	let new_layout.id = [0]
	let new_layout.layout = "w"
	let new_layout.buffer = 1
	let new_layout.size = 1
	let new_layout.window = win_getid()

	return new_layout
endfunction
" }}}

" ==============================================================================
" User level functions
" ==============================================================================
" FUNCTION: s:Split(direction, after) {{{1
function! s:Split(direction, after)
	let pane = s:GetPane("window", win_getid())
	if pane == {}
		call s:Render()
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
	let g:current_pane[g:tab] = s:AddPane({"layout":"w", "window":win_getid()}, current_id, a:direction, a:after)

	" Set the sizes of the panes and return to the origional window
	call s:LoadPanes(g:wm_tab_layouts[g:tab], [0], [1, 1], 1)
	call win_gotoid(g:current_pane[g:tab].window)
endfunction
" }}}
" FUNCTION: s:Close() {{{1
function! s:Close()
	if index(g:wm_sidebar.windows, win_getid()) != -1
		call s:ToggleSidebarOpen()
		return
	endif

	let was_empty = bufname() == ""
	let pane = s:GetPane("window", win_getid())
	close!

	if was_empty
		call s:ClearEmpty()
	endif

	if pane == {} || len(pane.id) <= 1
		return
	endif

	let g:current_pane[g:tab] = s:RemovePane(pane.id)

	" Set the sizes of the panes and return to the origional window
	call s:LoadPanes(g:wm_tab_layouts[g:tab], [0], [1, 1], 1)
	call win_gotoid(g:current_pane[g:tab].window)
endfunction
" }}}
" FUNCTION: s:Move(direction, value) {{{1
function! s:Move(direction, value)
	let pane = s:GetPane("window", win_getid())
	if pane == {} || !has_key(pane, "id") || len(pane.id) <= 1
		return
	endif

	let id = pane.id
	let parent = s:GetPane("id", id[0:-2])
	let parents_parent = s:GetPane("id", id[0:-3])

	" Move the pane out of its current parent
	if parent.layout != a:direction
		call s:RemovePane(pane.id)
		call s:AddPane(pane, id[0:-2], a:direction, a:value)

		" If the pane is on the end of its parent, move it out
	elseif (id[-1] == 0 && a:value == 0) || (id[-1] == len(parent.children) - 1 && a:value == 1)
		if parent.id == [0]
			return
		endif

		call s:Move(a:direction == "v" ? "h" : "v", 1)
		call s:Move(a:direction, a:value)

		" If there are only 2 panes in the parent, swap their places
	elseif len(parent.children) == 2
		let parent.children = [parent.children[1], parent.children[0]]

		" Group the pane with the next pane in the parent
	else
		let location_pane = parent.children[id[-1] + (a:value ? 1 : -1)]
		call s:RemovePane(pane.id)
		call s:AddPane(pane, location_pane.id, a:direction == "v" ? "h" : "v", 1)
	endif

	call s:Render()
	call win_gotoid(pane.window)
endfunction
" }}}
" FUNCTION: s:Resize(direction, amount) {{{1
function! s:Resize(direction, amount)
	if index(g:wm_sidebar.windows, win_getid()) != -1
		if g:wm_sidebar.size > 1
			let g:wm_sidebar.size += 1.0 * &columns * a:amount
			exec "vertical resize " . g:wm_sidebar.size
		else
			let g:wm_sidebar.size += a:amount
			exec "vertical resize " . (&columns * g:wm_sidebar.size)
		endif
		return
	endif

	let pane = s:GetPane("window", win_getid())
	if pane == {}
		return
	endif
	let id = pane.id

	if len(id) >= 2 && s:GetPane("id", id[0:-2]).layout == a:direction
		let parent = s:GetPane("id", id[0:-2])
		let pane = s:GetPane("id", id)
	elseif len(id) >= 3
		let pane = s:GetPane("id", id[0:-2])
		let parent = s:GetPane("id", id[0:-3])
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

	call s:LoadPanes(g:wm_tab_layouts[g:tab], [0], [1, 1], 1)
endfunction
" }}}

" FUNCTION: s:ToggleSidebarOpen() {{{1
function! s:ToggleSidebarOpen()
	if g:wm_sidebar.open " Disable the sidebar if it is already active
		let g:wm_sidebar.open = 0
		let g:wm_sidebar.focused = 0
		let g:wm_sidebar.current = {}
		let g:wm_sidebar.windows = []
	else " Enable the sidebar if it is not already active
		let g:wm_sidebar.open = 1
		let g:wm_sidebar.focused = 1 
	endif

	call s:Render()
endfunction
" }}}
" FUNCTION: s:ToggleSidebarFocus() {{{1
function! s:ToggleSidebarFocus()
	if !g:wm_sidebar.open
		call s:ToggleSidebarOpen()

	elseif g:wm_sidebar.focused
		let g:wm_sidebar.focused = 0

	else
		let g:wm_sidebar.focused = 1
	endif

	call win_gotoid(g:wm_sidebar.windows[0])
endfunction
" }}}
" FUNCTION: s:OpenSidebar(name) {{{1
function! s:OpenSidebar(name)
	let g:wm_sidebar.open = 1
	let g:wm_sidebar.focused = 1
	if !exists("g:wm_sidebar.current.name") || a:name != g:wm_sidebar.current.name
		for q in g:wm_sidebar.bars
			let g:var = q
			if has_key(q, "name") && q.name == a:name
				let g:wm_sidebar.current = q
				break
			endif
		endfor
		call s:Render()
	else
		call s:LoadPanes(g:wm_tab_layouts[g:tab], [0], [1, 1], 1)
	endif
endfunction
" }}}

" ==============================================================================
" Rendering functions
" ==============================================================================
" FUNCTION: s:Render() {{{1
function! s:Render()
	call s:DisableAutocommands()
	let g:wm_tab_layouts[g:tab].size = 1

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

	" Close all windows except for the current one
	wincmd L
	while winnr("$") > 1
		1close!
	endwhile
	let windows_window = win_getid()

	" Load the sidebar
	let s:sidebar_size = 0
	let g:wm_sidebar.windows = []
	if g:wm_sidebar.open
		let s:sidebar_size = s:RenderSidebar()
	endif

	" Form the split layout
	call win_gotoid(windows_window)
	call s:LoadSplits(g:wm_tab_layouts[g:tab], 1)

	" Set the sizes of all of the windows in the window list
	call s:LoadPanes(g:wm_tab_layouts[g:tab], [0], [1, 1], 1)

	" Redisable the autocommands
	call s:DisableAutocommands()

	" Resize the sidebar if necessary
	if g:wm_sidebar.open
		call win_gotoid(g:wm_sidebar.windows[0])
		exec "vertical resize " . string(s:sidebar_size)
		set winfixwidth
	endif

	" Return to the origional window
	if g:wm_sidebar.focused
		call win_gotoid(g:wm_sidebar.windows[0])
	else
		call win_gotoid(g:current_pane[g:tab].window)

		" Set the color of the current window if a special color is specified
		if exists("g:wm_current_color")
			setlocal winhl=Normal:WmCurrentColor
		endif
	endif

	" Remove any empty buffers that were created
	call s:ClearEmpty()

	if exists("g:wm_current_color")
		autocmd BufEnter * silent! if win_getid() != g:wm_sidebar.window | setlocal winhl=Normal:WmCurrentColor | endif
		autocmd BufLeave * silent! if win_getid() != g:wm_sidebar.window | setlocal winhl=Normal:WmWindowColor | endif
	endif

	call s:EnableAutocommands()
endfunction
" }}}
" FUNCTION: s:RenderSidebar() {{{1
function! s:RenderSidebar()
	" Save the current winid for later
	let nonsidebar_window = win_getid()

	" Run the command to open the sidebar
	silent! exec g:wm_sidebar.current.command

	" Get a list of window ids after opening the sidebar
	let g:wm_sidebar.current.buffers = []
	for i in range(1, winnr("$"))
		let window_id = win_getid(i)

		if window_id != nonsidebar_window
			call add(g:wm_sidebar.windows, window_id)
			call add(g:wm_sidebar.current.buffers, bufnr(win_id2win(window_id)))
		endif
	endfor

	" Create a blank window if a window wasn't created
	if !exists("g:wm_sidebar.windows") || len(g:wm_sidebar.windows) < 1
		vnew
		let g:wm_sidebar.windows = [win_getid()]
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
	call win_gotoid(nonsidebar_window)
	wincmd L

	" Figure out the size and resize the sidebar
	call win_gotoid(g:wm_sidebar.windows[0])
	if g:wm_sidebar.size > 1
		let s:sidebar_size = g:wm_sidebar.size
	else
		let s:sidebar_size = &columns * g:wm_sidebar.size
	endif
	exec "vertical resize " . string(s:sidebar_size)

	return s:sidebar_size
endfunction
" }}}
" FUNCTION: s:LoadSplits(pane, first) {{{1
function! s:LoadSplits(pane, first)
	if a:first
		call s:DisableAutocommands()
	endif

	" Open a window
	if a:pane["layout"] == "w"
		" Open the correct buffer in the window if the buffer exists
		if exists("a:pane.buffer") && index(range(1, bufnr("$")), a:pane.buffer) != -1
			exec "buffer " . a:pane.buffer
		endif

		" Give the pane a window number if it doesn't have one already
		let a:pane.window = win_getid()

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
			call win_gotoid(a:pane.children[i].window)
			call s:LoadSplits(a:pane.children[i], 0)
		endfor

		if has_key(a:pane, "window")
			call remove(a:pane, "window")
		endif
	endif

	if a:first
		call s:EnableAutocommands()
	endif
endfunction
" }}}
" FUNCTION: s:LoadPanes(pane, id, size, first) {{{1
function! s:LoadPanes(pane, id, size, first)
	let a:pane.id = a:id

	if a:first
		call s:DisableAutocommands()
	endif

	" Open a window
	if a:pane["layout"] != "w"
		" Set up the children
		for i in range(len(a:pane.children))
			" Figure out the new size
			if a:size == []
				let new_size = []
			else
				let size_index = a:pane.layout == "h" ? 0 : 1
				let new_size = a:size[0:1]
				let new_size[size_index] = 1.0 * a:size[size_index] * a:pane.children[i].size
			endif

			let new_id = a:id[0:-1]
			call add(new_id, i)

			" Go to the window and load it
			call s:LoadPanes(a:pane.children[i], new_id, new_size, 0)
		endfor

	elseif a:size != []	
		call win_gotoid(a:pane.window)

		exec "vertical resize " . string((&columns - s:sidebar_size) * a:size[0])
		" Subtract 1 because of statusline of each window
		exec "resize " . string(&lines * a:size[1] - 1)

		" Set it to the default window color
		if exists("g:wm_window_color")
			setlocal winhl=Normal:WmWindowColor
		endif
	endif

	if a:first
		if a:size != []
			if g:wm_sidebar.focused
				call win_gotoid(g:wm_sidebar.windows[0])
			else
				call win_gotoid(g:current_pane[g:tab].window)
			endif
		endif

		call s:EnableAutocommands()
	endif
endfunction
" }}}
" FUNCTION: s:ClearEmpty() {{{1
function! s:ClearEmpty()
	" Clear unused empty buffers
	let open_buffer_list = []
	exec "tabdo for i in range(1, winnr('$')) | call add(open_buffer_list, winbufnr(i)) | endfor"
	exec "norm! " . string(g:tab + 1) . "gt"

	for i in range(1, bufnr("$"))
		if bufname(i) == "" && index(open_buffer_list, i) == -1
			silent! exec string(i) . "bdelete!"
		endif
	endfor
endfunction
" }}}

" ==============================================================================
" Background functions
" ==============================================================================
" FUNCTION: s:GetPane(datapoint, value) {{{1
function! s:GetPane(datapoint, value)
	if a:datapoint == "id"
		if a:value == [0]
			return g:wm_tab_layouts[g:tab]
		elseif len(a:value) <= 1
			return {}
		endif

		let pane = g:wm_tab_layouts[g:tab]
		for i in range(1, len(a:value) - 1)
			let id_char = a:value[i]
			if !has_key(pane, "children") || len(pane.children) <= id_char
				return {}
			endif

			let pane = pane.children[id_char]
		endfor

		return pane

	else
		let checkpanes = [g:wm_tab_layouts[g:tab]]

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
" FUNCTION: s:AddPane(new_pane, location_id, direction, after) {{{1
function! s:AddPane(new_pane, location_id, direction, after)
	let location_pane = s:GetPane("id", a:location_id)

	if location_pane == {}
		echo "Error: Location " . string(a:location_id) . " not found"
		return -1
	endif

	let location_parent = s:GetPane("id", a:location_id[0:-2])

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

		call s:ReplacePane(new_parent, a:location_id)

		" Set the window sizes to be 50/50
		let new_parent.children[0].size = 0.5
		let new_parent.children[1].size = 0.5
	endif

	call s:LoadPanes(g:wm_tab_layouts[g:tab], [0], [], 1)
	return a:new_pane
endfunction
" }}}
" FUNCTION: s:RemovePane(id) {{{1
function! s:RemovePane(id)
	let parent = s:GetPane("id", a:id[0:-2])
	let remove_index = a:id[-1]

	call remove(parent.children, remove_index)

	" If the parent contains a single other window, and should be dissolved
	if len(parent.children) == 1
		let replacement = parent.children[0]
		let replacement.id = parent.id
		let replacement.size = parent.size
		call s:ReplacePane(replacement, parent.id)
		let new_pane = replacement

		call s:LoadPanes(g:wm_tab_layouts[g:tab], [0], [], 1)

		" If the dissolved split now has the same layout as its parent
		let new_parent = s:GetPane("id", a:id[0:-2])
		if len(a:id) >= 3 && new_parent.layout == s:GetPane("id", a:id[0:-3]).layout
			let super_parent = s:GetPane("id", a:id[0:-3])
			" Put the first pane that should be integrated into the super parent in
			" the place of the entire list
			call s:ReplacePane(new_parent.children[0], new_parent.id)

			" Generate new ids
			call s:LoadPanes(g:wm_tab_layouts[g:tab], [0], [], 1)

			" One by one add the rest of the panes that need to be integrated into
			" the super parent after the one that was added before
			for i in range(1, len(new_parent.children) - 1)
				call s:AddPane(new_parent.children[i], new_parent.children[0].id, super_parent.layout, 1)
			endfor

			" Set all the sizes to be equal
			let new_size_ratio = 1.0 / len(super_parent.children)
			for q in super_parent.children
				let q.size = new_size_ratio
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

	call s:LoadPanes(g:wm_tab_layouts[g:tab], [0], [], 1)

	let new_window_id = new_pane.id[0:-1]
	while has_key(s:GetPane("id", new_window_id), "children")
		call add(new_window_id, len(s:GetPane("id", new_window_id).children) - 1)
	endwhile

	return s:GetPane("id", new_window_id)
endfunction
" }}}
" FUNCTION: s:ReplacePane(new_pane, location_id) {{{1
function! s:ReplacePane(new_pane, location_id)
	if a:location_id == [0]
		let g:wm_tab_layouts[g:tab] = a:new_pane
		return
	endif

	let location_pane = s:GetPane("id", a:location_id)
	let location_parent = s:GetPane("id", a:location_id[0:-2])
	let location_index = index(location_parent.children, location_pane)

	call remove(location_parent.children, location_index)
	call insert(location_parent.children, a:new_pane, location_index)
endfunction
" }}}

" ==============================================================================
" Autocmd functions
" ==============================================================================
" FUNCTION: s:WindowMoveEvent() {{{1
function! s:WindowMoveEvent()
	silent! if index(g:wm_sidebar.windows, win_getid()) != -1
	let g:wm_sidebar.focused = 1
	silent! elseif s:GetPane("window", win_getid()) != {}
	let g:wm_sidebar.focused = 0 
	let g:current_pane[g:tab] = s:GetPane("window", win_getid())
endif
endfunction
" }}}
" FUNCTION: s:NewBufferEvent() {{{1
function! s:NewBufferEvent()
	if g:wm_sidebar.focused
		if exists("g:wm_sidebar_color")
			setlocal winhl=Normal:WmSidebarColor
		endif

	else
		if exists("g:wm_window_color")
			setlocal winhl=Normal:WmWindowColor
		endif

		silent! if g:current_pane[g:tab].window == win_getid()
		let g:current_pane[g:tab].buffer = bufnr()
	endif
endif

endfunction
" }}}
" FUNCTION: s:NewTabEvent() {{{1
function! s:NewTabEvent()
	let g:tab = tabpagenr() - 1 

	while len(g:wm_tab_layouts) < tabpagenr() 
		let new_layout = s:GetNewLayout()
		call add(g:wm_tab_layouts, new_layout) 
		call add(g:current_pane, new_layout) 
	endwhile 

	call s:Render()
endfunction
" }}}

" FUNCTION: s:DisableAutocommands() {{{1
function! s:DisableAutocommands()
	autocmd! WinEnter
	autocmd! BufEnter
	autocmd! TabEnter
endfunction
" }}}
" FUNCTION: s:EnableAutocommands() {{{1
function! s:EnableAutocommands()
	autocmd WinEnter * call s:WindowMoveEvent()
	autocmd BufEnter * call s:NewBufferEvent()
	autocmd TabEnter * call s:NewTabEvent()
endfunction
" }}}
