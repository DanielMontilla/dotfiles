return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.config").setup({
      ensure_installed = { "lua", "vim", "vimdoc", "query" },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    })
  end,
}
