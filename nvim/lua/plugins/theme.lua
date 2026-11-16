return {
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      terminal_colors = true,
      undercurl = true,
      underline = true,
      bold = true,
      italic = {
        strings = true,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
      },
      strikethrough = true,
      inverse = true,
      contrast = "soft",
      transparent_mode = true,
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = false, -- cargar inmediatamente
    priority = 1000, -- prioridad alta
    opts = {
      style = "night", -- storm, night, moon, day
      transparent = true,
      terminal_colors = true,
    },
  },

  {
    "rebelot/kanagawa.nvim",
    opts = {
      theme = "wave", -- wave, dragon, lotus
      transparent = true,
      terminalColors = true,
    },
  },

  {
    "gbprod/nord.nvim",
    opts = {
      transparent = true,
      terminal_colors = true,
      diff = { mode = "bg" },
      borders = true,
      errors = { mode = "bg" },
      styles = {
        comments = { italic = true },
        keywords = {},
        functions = {},
        variables = {},
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      -- carga el último colorscheme guardado (ver el autocmd "persist_colorscheme"
      -- en config/autocmds.lua); si no hay ninguno guardado, usa tokyonight
      colorscheme = function()
        -- reaplica la transparencia justo antes de que lazy.nvim cargue
        -- cualquier plugin de tema, tanto ahora como en cambios posteriores
        -- vía <leader>uC: lazy.nvim carga el plugin en su propio autocmd
        -- ColorSchemePre (registrado antes que este, al iniciar), así que
        -- para cuando corremos aquí el módulo ya está disponible
        vim.api.nvim_create_autocmd("ColorSchemePre", {
          group = vim.api.nvim_create_augroup("sync_transparency", { clear = true }),
          callback = function()
            require("config.transparency").apply(vim.g.transparent_enabled ~= false)
          end,
        })

        local theme_file = vim.fn.stdpath("data") .. "/lazyvim-theme"
        local name
        local f = io.open(theme_file, "r")
        if f then
          name = vim.trim(f:read("*a") or "")
          f:close()
        end
        vim.cmd.colorscheme(name ~= "" and name or "tokyonight")
      end,
    },
  },
}
