-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Guarda el colorscheme elegido (con <leader>uC, :colorscheme, etc.) para
-- restaurarlo automáticamente en la próxima sesión (ver lua/plugins/theme.lua)
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("persist_colorscheme", { clear = true }),
  callback = function(ev)
    if not ev.match or ev.match == "" then
      return
    end
    local f = io.open(vim.fn.stdpath("data") .. "/lazyvim-theme", "w")
    if f then
      f:write(ev.match)
      f:close()
    end
  end,
})
