local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local highlight_group = augroup("highlight_yank", { clear = true })
autocmd("TextYankPost", {
  group = highlight_group,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

local line_return = augroup("line_return", { clear = true })
autocmd("BufReadPost", {
  group = line_return,
  pattern = "*",
  callback = function()
    if vim.fn.line("'\"") > 0 and vim.fn.line("'\"") <= vim.fn.line("$") then
      vim.cmd('normal! g`"')
    end
  end,
})

local trim_whitespace = augroup("trim_whitespace", { clear = true })
autocmd("BufWritePre", {
  group = trim_whitespace,
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

local filetype_detect = augroup("filetype_detect", { clear = true })
autocmd({ "BufNewFile", "BufRead" }, {
  group = filetype_detect,
  pattern = "*.tf",
  callback = function()
    vim.opt.filetype = "terraform"
  end,
})
