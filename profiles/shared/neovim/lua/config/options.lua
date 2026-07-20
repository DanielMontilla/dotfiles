local options = {}

options.number = true
options.relativenumber = true

options.mouse = "a"

options.encoding = "utf-8"
options.fileencoding = "utf-8"

options.scrolloff = 8
options.sidescrolloff = 8

options.expandtab = true
options.shiftwidth = 2
options.tabstop = 2
options.softtabstop = 2

options.smartindent = true

options.wrap = false

options.termguicolors = true

options.signcolumn = "yes"

options.updatetime = 250

options.timeoutlen = 300

options.splitbelow = true
options.splitright = true

options.ignorecase = true
options.smartcase = true

options.hlsearch = true
options.incsearch = true

options.cursorline = true

options.background = "dark"

options.backup = false
options.writebackup = false
options.swapfile = false
options.undofile = true

options.clipboard = "unnamedplus"

options.completeopt = { "menu", "menuone", "noselect" }

options.foldmethod = "marker"

options.showmode = false

options.laststatus = 3

options.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"

for k, v in pairs(options) do
  vim.opt[k] = v
end
