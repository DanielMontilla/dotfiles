return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      -- Standard LazyVim binding: <leader>e toggles the file explorer.
      -- (<leader>e diagnostics moved to <leader>xd in lsp/plugin.lua.)
      { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "File explorer" },
      { "<leader>fe", "<cmd>Neotree reveal<CR>", desc = "Reveal file in tree" },
    },
    init = function()
      -- Documented LazyVim pattern: make `nvim .` open the tree.
      -- Force neo-tree to load on the first BufEnter IF the startup
      -- argument is a directory. Requiring neo-tree here runs setup()
      -- early enough for its built-in netrw hijack to replace netrw.
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("Neotree_start_directory", { clear = true }),
        desc = "Start Neo-tree with directory",
        once = true,
        callback = function()
          if package.loaded["neo-tree"] then
            return
          else
            local stats = vim.uv.fs_stat(vim.fn.argv(0))
            if stats and stats.type == "directory" then
              require("neo-tree")
            end
          end
        end,
      })
    end,
    config = function(_, opts)
      -- Kill netrw so `nvim .` doesn't open the default file explorer.
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      require("neo-tree").setup(opts)
    end,
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = {
          visible = false, -- show hidden/dotfiles (so .env files appear)
          show_hidden_count = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      git = {
        enable = true,
      },
      window = {
        position = "left",
        width = 32,
        mappings = {
          -- <space> kept as a no-op so it doesn't conflict with leader
          ["<space>"] = "none",
          -- enter opens in a NEW tab by default
          ["<cr>"] = "open_tabnew",
          -- o opens in the current buffer (in-place)
          ["o"] = "open",
        },
      },
      default_component_configs = {
        git_status = {
          symbols = {
            added = "",
            modified = "",
            deleted = "D",
            renamed = "R",
            untracked = "?",
            ignored = "I",
            unstaged = "",
            staged = "",
            conflict = "",
          },
        },
      },
    },
  },
}
