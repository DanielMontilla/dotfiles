local config = require("plugins.theme.kanagawa")

return {
  "rebelot/kanagawa.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("kanagawa").setup(config)
    require("kanagawa").load("dragon")
  end,
}
