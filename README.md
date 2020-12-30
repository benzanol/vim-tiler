# Vim Tiler
## A much needed replacement for vim's default window management.

* [Installation](#installation)
	* [Vim Plug](#vim-plug)
	* [Vundle](#vundle)
	* [From Source](#from-source)
* [Features](#features)
	* [Tiling Functionality](#tiling-functionality)
	* [Sidebar Features](#sidebar-features)
	* [Floating Windows (neovim only)](#floating-windows)
* [Usage](#usage)
	* [Enabling the Plugin](#enabling-tiler)
	* [Basic Commands](#basic-commands)
	* [Sidebar Commands](#sidebar-commands)
	* [Example Configuration](#example-configuration)

## Installation
### Vim Plug
To install tiler with vim plug, add the following to your vimrc.\
`Plug 'AdamTillou/vim-tiler'`

Then, restart vim, and run the command\
`:PlugInstall`

Make sure to follow the instructions in the [usage](#usage) section to enable window management.

### Vundle
To install tiler with vundle, add the following to your vimrc.\
`Plugin 'AdamTillou/vim-tiler'`

Then, restart vim, and run the command\
`:PluginInstall`

Make sure to follow the instructions in the [usage](#usage) section to enable window management.

## Features
### Tiling Functionality
* Move windows back and forth in a natural way
### The Sidebar
Tiler provides a way to manage plugins such as nerdtree, taglist, or any other plugins that open up in a new window, with the built in sidebar.\
Once you specify a sidebar plugin (see [usage](#sidebar-commands),) you can easily launch it and have it snapped to the edge of the screen.\
If you already have a plugin open when you try to launch a new one, it will be automatically hidden until you call it again.\
You can also easily specify the screen edge and size of the sidebar to fit your needs.
### Floating Windows
Coming soon!
## Usage
**IMPORTANT:** If you do not use the provided commands for opening and closing windows these actions will not be registered by the plugin, and may get messed up when running other plugin commands. In tabs where the plugin is disabled, or if you are not using the plugin commands, the normal vim commands will continue to work just fine.
### Enabling Tiler
Enable/disable tiler for the current tab (recommended)\
`call tiler#TabEnable()` / `call tiler#TabDisable()`\
\
Enable/disable tiler for all tabs\
`call tiler#GlobalEnable()` / `call tiler#GlobalDisable()`\
Warning: This can affect plugins such as vimspector that open new tabs
### Basic Commands
Reload the window layout (this happens automatically when performing any of the commands below)\
`WindowRender`
Close the current window, or close the entire sidebar if it is focused\
`WindowClose`\
\
Open a new window in a certain direction\
`WindowOpenRight` / `WindowOpenLeft` / `WindowOpenDown` / `WindowOpenUp`\
\
Move a window in a certain direction\
`WindowMoveRight` / `WindowMoveLeft` / `WindowMoveDown` / `WindowMoveUp`
### Sidebar Commands
Specify a list of sidebars, each of which should have a name, and a command to be run\
`call tiler#sidebar#AddNew({name}, {command})`\
For example, to enable nerdtree as a sidebar\
`call tiler#sidebar#AddNew('nerdtree', 'NERDTreeToggle')`\
\
Open the sidebar of a certain name\
`SidebarOpen {name}`\
To use the example from before, to open nerdtree you would run the command\
`SidebarOpen nerdtree`\
\
Toggle the sidebar being open\
`ToggleSidebarOpen`\
\
Toggle focus being on the sidebar\
`ToggleSidebarFocus`\
\
Set the screen edge of the sidebar (left or right):
let g:tiler#sidebar.side =  {side}\
The default side is left.\
\
Set the size of the sidebar (used as a pixel value if greater than one, and a proportion if less than one)\
let g:tiler#sidebar.size = {size}\
The default size is 30 pixels.
### Example Configuration
`nnoremap <silent> <nowait> <C-w>r :WindowRender<CR>`\
`nnoremap <silent> <nowait> <C-w>c :WindowClose<CR>`

`nnoremap <silent> <nowait> <C-w>mj :WindowMoveDown<CR>`\
`nnoremap <silent> <nowait> <C-w>mk :WindowMoveUp<CR>`\
`nnoremap <silent> <nowait> <C-w>mh :WindowMoveLeft<CR>`\
`nnoremap <silent> <nowait> <C-w>ml :WindowMoveRight<CR>`

`nnoremap <silent> <nowait> <C-w>nj :WindowSplitDown<CR>`\
`nnoremap <silent> <nowait> <C-w>nk :WindowSplitUp<CR>`\
`nnoremap <silent> <nowait> <C-w>nh :WindowSplitLeft<CR>`\
`nnoremap <silent> <nowait> <C-w>nl :WindowSplitRight<CR>`

`nnoremap <silent> <nowait> <C-w>= :WindowResizeHorizontal 0.015<CR>`\
`nnoremap <silent> <nowait> <C-w>- :WindowResizeHorizontal -0.015<CR>`\
`nnoremap <silent> <nowait> <C-w>+ :WindowResizeVertical 0.025<CR>`\
`nnoremap <silent> <nowait> <C-w>_ :WindowResizeVertical -0.025<CR>`

`nnoremap <silent> <nowait> <C-w>S :SidebarToggleOpen<CR>`\
`nnoremap <silent> <nowait> <C-w>s :SidebarToggleFocus<CR>`

`let g:tiler#sidebar.side = 'left'`
`let g:tiler#sidebar.size = '0.2'`
`call tiler#sidebar#AddNew("filetree", "call filetree#Launch()")`\
`call tiler#sidebar#AddNew("mundo", "MundoToggle")`
`call tiler#sidebar#AddNew("taglist", "Tlist")`

`nnoremap <silent> <nowait> <C-w>1 :SidebarOpen nerdtree`\
`nnoremap <silent> <nowait> <C-w>2 :SidebarOpen mundo`\
`nnoremap <silent> <nowait> <C-w>3 :SidebarOpen taglist`
