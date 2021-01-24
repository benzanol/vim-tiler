" ==============================================================================
" Background functions for changing the window layout
" ==============================================================================
" FUNCTION: tiler#layout#AddPane(new_pane, location_id, direction, after) {{{1
function! tiler#layout#AddPane(new_pane, location_id, direction, after)
	let location_pane = tiler#api#GetPane("id", a:location_id)

	if location_pane == {}
		echo "Error: Location " . string(a:location_id) . " not found"
		return -1
	endif

	let location_parent = tiler#api#GetPane("id", a:location_id[0:-2])
	
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
		let ratio = (len(children) / (len(children) + 1.0))
		for i in range(len(children))
			let children[i].size = 1.0 * ratio * children[i].size
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

		call tiler#layout#ReplacePane(new_parent, a:location_id)

		" Set the window sizes to be 50/50
		let new_parent.children[0].size = 0.5
		let new_parent.children[1].size = 0.5
	endif

	call tiler#display#LoadLayout(0)
	
	return a:new_pane
endfunction
" }}}
" FUNCTION: tiler#layout#RemovePane(id) {{{1
function! tiler#layout#RemovePane(id)
	let parent = tiler#api#GetPane("id", a:id[0:-2])
	let remove_index = a:id[-1]

	call remove(parent.children, remove_index)

	" If the parent contains a single other window, and should be dissolved
	if len(parent.children) == 1
		let replacement = parent.children[0]
		let replacement.id = parent.id
		let replacement.size = parent.size
		call tiler#layout#ReplacePane(replacement, parent.id)
		let new_pane = replacement

		" Load ids
	call tiler#display#LoadLayout(0)

		" If the dissolved split now has the same layout as its parent
		let new_parent = tiler#api#GetPane("id", a:id[0:-2])
		if len(a:id) >= 3 && new_parent.layout == tiler#api#GetPane("id", a:id[0:-3]).layout
			let super_parent = tiler#api#GetPane("id", a:id[0:-3])
			" Put the first pane that should be integrated into the super parent in
			" the place of the entire list
			call tiler#layout#ReplacePane(new_parent.children[0], new_parent.id)

			" Generate new ids
	call tiler#display#LoadLayout(0)

			" One by one add the rest of the panes that need to be integrated into
			" the super parent after the one that was added before
			for i in range(1, len(new_parent.children) - 1)
				call tiler#layout#AddPane(new_parent.children[i], new_parent.children[0].id, super_parent.layout, 1)
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

	" Load ids
	call tiler#display#LoadLayout(0)

	let new_window_id = new_pane.id[0:-1]
	while has_key(tiler#api#GetPane("id", new_window_id), "children")
		call add(new_window_id, len(tiler#api#GetPane("id", new_window_id).children) - 1)
	endwhile

	return tiler#api#GetPane("id", new_window_id)
endfunction
" }}}
" FUNCTION: tiler#layout#ReplacePane(new_pane, location_id) {{{1
function! tiler#layout#ReplacePane(new_pane, location_id)
	if a:location_id == [0]
		call tiler#api#SetLayout(a:new_pane)
		return
	endif

	let location_pane = tiler#api#GetPane("id", a:location_id)
	let location_parent = tiler#api#GetPane("id", a:location_id[0:-2])
	let location_index = index(location_parent.children, location_pane)

	call remove(location_parent.children, location_index)
	call insert(location_parent.children, a:new_pane, location_index)
endfunction
" }}}
