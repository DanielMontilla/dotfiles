vim.g.mapleader = " "

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- #region General

-- Clear search highlights
map("n", "<Esc>", ":noh<CR>", opts)

-- Save file
map("n", "<C-s>", ":w<CR>", opts)
map("i", "<C-s>", "<Esc>:w<CR>a", opts)

-- Select all
map("n", "<C-a>", "ggVG", opts)

-- #endregion

-- #region Navigation

-- Scroll and center
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)

-- Center search results
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)

-- Navigate between windows
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Exit terminal mode
map("t", "<Esc>", "<C-\\><C-n>", opts)

-- #endregion

-- #region Editor

-- Move lines up/down
map("n", "<A-j>", ":m .+1<CR>==", opts)
map("n", "<A-k>", ":m .-2<CR>==", opts)
map("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
map("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)

-- Keep visual selection on indent
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Delete without yanking
map("n", "x", '"_x', opts)

-- #endregion

-- #region Clipboard

-- Yank to system clipboard
map("n", "<leader>y", '"+y', opts)
map("v", "<leader>y", '"+y', opts)

-- Paste from system clipboard
map("n", "<leader>p", '"+p', opts)

-- #endregion

-- #region Files

-- Open file explorer (Netrw)
map("n", "<leader>pv", ":Ex<CR>", opts)

-- Open URL/file under cursor
map("n", "gx", ":silent execute '!open ' . shellescape('<cfile>')<CR>", { noremap = true, silent = true })

-- #endregion

-- #region Config

-- Reload Neovim config
map("n", "<leader>vr", ":luafile $MYVIMRC<CR>", opts)

-- #endregion
