return {
  theme = "dragon",
  compile = true,
  undercurl = true,
  commentStyle = { italic = true },
  functionStyle = {},
  keywordStyle = { italic = true },
  statementStyle = { bold = true },
  typeStyle = {},
  transparent = false,
  dimInactive = false,
  terminalColors = true,
  colors = {
    theme = {
      all = {
        ui = {
          bg_gutter = "none",
        },
      },
    },
  },
  overrides = function(colors)
    local theme = colors.theme
    return {
      NormalFloat = { bg = theme.ui.bg_p2 },
      FloatBorder = { fg = theme.ui.fg_dim, bg = theme.ui.bg_p2 },
      Pmenu = { bg = theme.ui.bg_p1 },
      PmenuSel = { bg = theme.ui.bg_p2 },
      TelescopeNormal = { bg = theme.ui.bg_p2 },
      TelescopeBorder = { fg = theme.ui.fg_dim, bg = theme.ui.bg_p2 },
    }
  end,
}
