local opt = vim.opt

-- │ Editor Behavior │
-----------------------

-- Set the leader key to space. The leader key is a prefix for custom shortcuts.
-- This should be set before any key mappings.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Enable mouse support in all modes
opt.mouse = 'a'

-- Use the system clipboard for all yank, delete, and put operations
opt.clipboard = 'unnamedplus'

-- Duration for keymap combinations input
opt.timeoutlen = 350

-- │ Appearance & UI │
-----------------------

-- Enable 24-bit RGB color in the terminal
opt.termguicolors = true

-- Show line numbers
opt.number = true

-- Show relative line numbers for easier vertical navigation
opt.relativenumber = true

-- How many columns of screen real estate to preserve to the left and right of the cursor
opt.sidescrolloff = 8

-- How many lines of screen real estate to preserve above and below the cursor
opt.scrolloff = 12

-- Highlight the current line
opt.cursorline = true

-- Always show the sign column, preventing screen jitter when signs appear/disappear
opt.signcolumn = 'yes'

-- Do not wrap long lines of text
opt.wrap = false

-- Command line height
opt.cmdheight = 1

-- │ Tabs & Indentation │
--------------------------

-- Set the number of spaces a <Tab> counts for
opt.tabstop = 2
opt.softtabstop = 2

-- Set the number of spaces to use for auto-indentation
opt.shiftwidth = 2

-- Use spaces instead of tabs
opt.expandtab = true
 
-- Enable smart auto-indenting for new lines
opt.smartindent = true

-- │ File & Backup Settings │
------------------------------

-- Disable the creation of swap files
opt.swapfile = false

-- Disable the creation of backup files
opt.backup = false

-- Keep undo history even after closing a file
opt.undofile = true
