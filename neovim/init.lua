-- Basic settings  
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Key mappings
vim.g.mapleader = " "
local keymap = vim.keymap.set

keymap("n", "<leader>pf", ":Ex<CR>")
