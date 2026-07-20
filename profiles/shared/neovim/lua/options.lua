-- #region UI

-- 24-bit RGB color support
vim.opt.termguicolors = true

-- Use dark background
vim.opt.background = "dark"

-- Cursor shape per mode
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"

-- Mode is shown in statusline instead
vim.opt.showmode = false

-- Global statusline
vim.opt.laststatus = 3

-- Always show sign column
vim.opt.signcolumn = "yes"

-- Highlight current line
vim.opt.cursorline = true

-- #endregion

-- #region Line numbers

-- Show line numbers
vim.opt.number = true

-- Relative line numbers
vim.opt.relativenumber = true

-- #endregion

-- #region Scrolling

-- Lines of context around cursor
vim.opt.scrolloff = 8

-- Columns of context around cursor
vim.opt.sidescrolloff = 8

-- #endregion

-- #region Indentation

-- Use spaces instead of tabs
vim.opt.expandtab = true

-- Reindent width
vim.opt.shiftwidth = 2

-- Display width of a tab
vim.opt.tabstop = 2

-- Insert-mode tab width
vim.opt.softtabstop = 2

-- Auto-indent based on syntax
vim.opt.smartindent = true

-- #endregion

-- #region Search

-- Case-insensitive search
vim.opt.ignorecase = true

-- Override ignorecase when uppercase is used
vim.opt.smartcase = true

-- Highlight search matches
vim.opt.hlsearch = true

-- Show matches while typing
vim.opt.incsearch = true

-- #endregion

-- #region Splits

-- Open horizontal splits below
vim.opt.splitbelow = true

-- Open vertical splits to the right
vim.opt.splitright = true

-- #endregion

-- #region Files & encoding

-- Internal encoding
vim.opt.encoding = "utf-8"

-- File encoding for writes
vim.opt.fileencoding = "utf-8"

-- Skip backup files
vim.opt.backup = false

-- Skip backup before write
vim.opt.writebackup = false

-- Skip swap files
vim.opt.swapfile = false

-- Persistent undo across sessions
vim.opt.undofile = true

-- #endregion

-- #region Behavior

-- Mouse in all modes
vim.opt.mouse = "a"

-- Use system clipboard
vim.opt.clipboard = "unnamedplus"

-- Popup completion menu behavior
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Fold by marker
vim.opt.foldmethod = "marker"

-- ms before swap file write / CursorHold event
vim.opt.updatetime = 250

-- ms timeout for mapped key sequences
vim.opt.timeoutlen = 300

-- Don't wrap long lines
vim.opt.wrap = false

-- Auto-reload files changed on disk
vim.opt.autoread = true

-- #endregion
