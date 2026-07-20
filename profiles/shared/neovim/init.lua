vim.opt.runtimepath:prepend(vim.fn.stdpath("config"))

require("config.options")
require("config.keymaps")
require("config.autocmds")

require("look.colorscheme")
