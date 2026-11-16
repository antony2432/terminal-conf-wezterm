-- Aplica el estado de transparencia a cualquier tema ya cargado por lazy.nvim.
-- Compartido entre el toggle (<leader>ut, en keymaps.lua) y el autocmd que
-- sincroniza la transparencia justo antes de aplicar un colorscheme nuevo
-- (registrado en plugins/theme.lua), para que no haga falta re-activarla
-- manualmente cada vez que cambias de tema.
local M = {}

M.themes = {
  { plugin = "tokyonight.nvim", module = "tokyonight", key = "transparent" },
  { plugin = "gruvbox.nvim", module = "gruvbox", key = "transparent_mode" },
  { plugin = "catppuccin", module = "catppuccin", key = "transparent_background" },
  { plugin = "kanagawa.nvim", module = "kanagawa", key = "transparent" },
  { plugin = "nord.nvim", module = "nord", key = "transparent" },
}

function M.apply(state)
  local plugins = require("lazy.core.config").plugins
  local Plugin = require("lazy.core.plugin")

  for _, theme in ipairs(M.themes) do
    local spec = plugins[theme.plugin]
    local ok_mod, mod = pcall(require, theme.module)
    if spec and ok_mod and mod.setup then
      local opts = Plugin.values(spec, "opts", false)
      opts[theme.key] = state
      mod.setup(opts)
    end
  end
end

return M
