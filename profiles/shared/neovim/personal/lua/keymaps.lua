vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local map = vim.keymap.set

-- │ Navigation │
---------------------

-- This is your original mapping for the file explorer
map("n", "<leader>pv", "<cmd>Ex<CR>", { desc = "Open File Explorer" })


-- │ Window Splits │
---------------------

map('n', '<leader>sv', '<cmd>vsplit<CR>', { desc = "Split Vertically", noremap = true, silent = true })
map('n', '<leader>sh', '<cmd>split<CR>', { desc = "Split Horizontally", noremap = true, silent = true })

-- │ Shortcuts │
-----------------

-- A common shortcut to select all text in the current buffer.
map('n', '<C-a>', 'ggVG', { desc = "Select All" })

-- │ Configuration │
-------------------

map('n', '<C-s>', '<cmd>source %<CR>', { desc = "Source Current File" })
