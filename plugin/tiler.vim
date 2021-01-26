" ==============================================================================
" Initialization functions
" ==============================================================================

" Remember that tiler is loaded
let g:tiler#loaded = 1

" Disable tiler on all tabs by default
let g:tiler#global = 0

" Enable or disable autocommands when entering/leaving tabs
autocmd TabEnter *
			\ if tiler#api#IsEnabled() |
			\ 	call tiler#display#Render() |
			\ 	call tiler#autocommands#Enable() |
			\ else |
			\ 	call tiler#autocommands#Disable() |
			\ endif

" Initialize variables
let g:tiler#loaded = 1
let g:tiler#always_resize = 1

let g:tiler#layouts = {}
let g:tiler#currents = {}

let g:tiler#sidebar = {"open":0, "focused":0, "size":30, "side":"left", "windows":{}, "bars":[]}
let g:tiler#sidebar.current = {"name":"blank", "command":"vnew | wincmd H"}

let g:tiler#inactive_message = "Tiler is not active on this tab. Run 'call tiler#TabEnable()' to activate it."

let g:tiler#colors#enabled = 0
let g:tiler#colors#background_groups = ["Normal", "MsgArea", "SignColumn", "StatusLine", "StatusLineNC", "VertSplit"]

" Initialize commands
command! WindowClose call tiler#actions#Close()
command! WindowRender call tiler#display#Render()

command! WindowMoveUp call tiler#actions#Move("v", 0)
command! WindowMoveDown call tiler#actions#Move("v", 1)
command! WindowMoveLeft call tiler#actions#Move("h", 0)
command! WindowMoveRight call tiler#actions#Move("h", 1)

command! WindowSplitUp call tiler#actions#Split("v", 0)
command! WindowSplitDown call tiler#actions#Split("v", 1)
command! WindowSplitLeft call tiler#actions#Split("h", 0)
command! WindowSplitRight call tiler#actions#Split("h", 1)

" Recommended resize values for horizontal and vertical are 0.015 and 0.025 respectively
command! -nargs=1 WindowResizeHorizontal call tiler#actions#Resize("h", <args>)
command! -nargs=1 WindowResizeVertical call tiler#actions#Resize("v", <args>)

command! SidebarToggleOpen call tiler#sidebar#ToggleSidebarOpen()
command! SidebarToggleFocus call tiler#sidebar#ToggleSidebarFocus()
command! -nargs=1 SidebarOpen call tiler#sidebar#OpenSidebar("<args>")

" Create highlight groups
if exists("g:tiler#colors#sidebar")
	let color = g:tiler#colors#sidebar
	execute printf("highlight TilerSidebarColor ctermbg=%s guibg=%s", color.cterm, color.gui)
endif

if exists("g:tiler#colors#window")
	let color = g:tiler#colors#window
	execute printf("highlight TilerWindowColor ctermbg=%s guibg=%s", color.cterm, color.gui)
endif

if exists("g:tiler#colors#current")
	let color = g:tiler#colors#current
	execute printf("highlight TilerCurrentColor ctermbg=%s guibg=%s", color.cterm, color.gui)
endif
