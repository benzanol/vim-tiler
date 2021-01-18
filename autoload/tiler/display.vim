" ==============================================================================
" Rendering functions
" ==============================================================================
" FUNCTION: tiler#display#Render() {{{1
function! tiler#display#Render()
	call tiler#autocommands#Disable()
	let layout = tiler#api#GetLayout()
	let layout.size = 1

	" Close all windows except for the current one
	wincmd L
	while winnr("$") > 1
		1close!
	endwhile
	let windows_window = win_getid()

	" Load the sidebar
	let s:sidebar_size = 0
	let g:tiler#sidebar.windows = []
	if g:tiler#sidebar.open
		let s:sidebar_size = tiler#display#RenderSidebar()
	endif

	" Form the split layout
	call win_gotoid(windows_window)
	call tiler#display#LoadSplits(tiler#api#GetLayout(), 1)

	" Set the sizes of all of the windows in the window list
	call tiler#display#LoadLayout(1)

	" Redisable the autocommands
	call tiler#autocommands#Disable()

	" Return to the origional window
	if g:tiler#sidebar.focused
		call win_gotoid(g:tiler#sidebar.windows[0])
	else
		call win_gotoid(tiler#api#GetCurrent().window)

		" Set the color of the current window if a special color is specified
		call tiler#colors#HighlightCurrent()
	endif

	" Remove any empty buffers that were created
	call tiler#display#ClearEmpty()

	call tiler#autocommands#Enable()
endfunction
" }}}
" FUNCTION: tiler#display#RenderSidebar() {{{1
function! tiler#display#RenderSidebar()
	" Save the current winid for later
	let nonsidebar_window = win_getid()

	" Run the command to open the sidebar
	silent! exec g:tiler#sidebar.current.command

	" Get a list of window ids after opening the sidebar
	let g:tiler#sidebar.current.buffers = []
	for i in range(1, winnr("$"))
		let window_id = win_getid(i)

		if window_id != nonsidebar_window
			call add(g:tiler#sidebar.windows, window_id)
			call add(g:tiler#sidebar.current.buffers, bufnr(win_id2win(window_id)))
		endif
	endfor

	" Create a blank window if a window wasn't created
	if !exists("g:tiler#sidebar.windows") || len(g:tiler#sidebar.windows) < 1
		vnew
		let g:tiler#sidebar.windows = [win_getid()]
	endif

	" Move the sidebar windows into a column and set settings
	for i in range(len(g:tiler#sidebar.windows))
		call win_gotoid(g:tiler#sidebar.windows[i])
		wincmd J

		setlocal nobuflisted
		setlocal hidden
		setlocal nonumber
		setlocal winfixwidth
		setlocal statusline=\ 

		if g:tiler#colors#enabled
			setlocal fillchars=vert:\ 
		endif

		call tiler#colors#HighlightSidebar()
	endfor

	" Move the origional window to the right
	call win_gotoid(nonsidebar_window)
	if g:tiler#sidebar.side == 'right'
		wincmd H
	else
		wincmd L
	endif

	" Figure out the size and resize the sidebar
	call win_gotoid(g:tiler#sidebar.windows[0])
	if g:tiler#sidebar.size > 1
		let s:sidebar_size = g:tiler#sidebar.size
	else
		let s:sidebar_size = &columns * g:tiler#sidebar.size
	endif
	exec "vertical resize " . string(s:sidebar_size)

	return s:sidebar_size
endfunction
" }}}

" FUNCTION: tiler#display#LoadSplits(pane, first) {{{1
function! tiler#display#LoadSplits(pane, first)
	if a:first
		call tiler#autocommands#Disable()
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
			call tiler#display#LoadSplits(a:pane.children[i], 0)
		endfor

		if has_key(a:pane, "window")
			call remove(a:pane, "window")
		endif
	endif

	if a:first
		call tiler#autocommands#Enable()
	endif
endfunction
" }}}
" FUNCTION: tiler#display#LoadPanes(pane, id, size, first) {{{1
function! tiler#display#LoadPanes(pane, id, size, first)
	let a:pane.id = a:id

	" Disable the autocommands so that they aren't triggered everytime a new
	" split is created
	if a:first
		call tiler#autocommands#Disable()
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
			call tiler#display#LoadPanes(a:pane.children[i], new_id, new_size, 0)
		endfor

	else
		call win_gotoid(a:pane.window)

		" Set it to the default window color
		call tiler#colors#HighlightWindow()

		if a:size != []
			exec "vertical resize " . string((&columns - s:sidebar_size) * a:size[0])
			" Subtract 1 because of statusline of each window
			exec "resize " . string(&lines * a:size[1] - 1)
		endif
	endif


	if a:first
		if a:size != [] && g:tiler#sidebar.open
			call win_gotoid(g:tiler#sidebar.windows[0])
			if g:tiler#sidebar.size > 1
				let s:sidebar_size = g:tiler#sidebar.size
			else
				let s:sidebar_size = &columns * g:tiler#sidebar.size
			endif
			exec "vertical resize " . string(s:sidebar_size)
		endif

		if a:size != []
			if g:tiler#sidebar.focused
				" Go to the current nonsidebar window first, so that it will be stored
				" as the alternate window
				call win_gotoid(tiler#api#GetCurrent().window)
				" Return to the sidebar
				call win_gotoid(g:tiler#sidebar.windows[0])
			else
				" Return to the origional sidebar and set the window color
				call win_gotoid(tiler#api#GetCurrent().window)
				call tiler#colors#HighlightCurrent()
			endif
		endif

		" Reenable the autocommands
		call tiler#autocommands#Enable()
	endif
endfunction
" }}}
" FUNCTION: tiler#display#LoadLayout(resize) {{{1
function! tiler#display#LoadLayout(resize)
	if a:resize == 1
		let size_arg = [1, 1]
	elseif a:resize == 0
		let size_arg = []
	elseif g:tiler#always_resize
		let size_arg = [1, 1]
	else
		let size_arg = []
	endif

	let current_layout = tiler#api#GetLayout()

	call tiler#display#LoadPanes(current_layout, [0], size_arg, 1)
endfunction
" }}}

" FUNCTION: tiler#display#ClearEmpty() {{{1
function! tiler#display#ClearEmpty()
	" Clear unused empty buffers
	let open_buffer_list = []
	let current_tab = tabpagenr()
	exec "tabdo for i in range(1, winnr('$')) | call add(open_buffer_list, winbufnr(i)) | endfor"
	" Return to the current tab
	while tabpagenr() != current_tab
		tabnext
	endwhile

	for i in range(1, bufnr("$"))
		if bufname(i) == "" && index(open_buffer_list, i) == -1
			silent! exec string(i) . "bdelete!"
		endif
	endfor
endfunction
" }}}
