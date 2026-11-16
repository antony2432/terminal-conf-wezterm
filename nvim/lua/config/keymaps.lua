-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Toggle de transparencia: aplica al colorscheme activo, sea cual sea
-- (la lógica compartida vive en lua/config/transparency.lua, también usada
-- por el autocmd que sincroniza la transparencia al cambiar de tema)
local transparency = require("config.transparency")

Snacks.toggle({
  name = "Transparencia",
  get = function()
    return vim.g.transparent_enabled ~= false
  end,
  set = function(state)
    vim.g.transparent_enabled = state
    transparency.apply(state)

    if vim.g.colors_name then
      vim.cmd.colorscheme(vim.g.colors_name)
    end
  end,
}):map("<leader>ut")
