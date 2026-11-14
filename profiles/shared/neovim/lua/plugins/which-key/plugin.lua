return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- Show the popup almost immediately when you press a leader key,
      -- so bindings are discoverable without memorising.
      delay = 100,
      spec = {
        -- Describe the leader "file" group with common actions
        { "<leader>e", group = "File Explorer (neo-tree)", icon = "" },
        { "<leader>f", group = "Find / Files" },
      },
    },
  },
}
