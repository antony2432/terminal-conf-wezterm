-- Dashboard de inicio con estilo propio: header con arte ASCII a color
-- (aleatorio entre 8 imágenes), frase, menú en cuadrícula y footer con
-- stats — construido sobre el dashboard de Snacks (el mismo que ya usa
-- el resto de la config), sin depender de alpha-nvim/telescope como en
-- https://github.com/Hordunlarmy/nvim.
--
-- Las imágenes son las mismas que trae https://github.com/nhattVim/alpha-ascii.nvim
-- (MIT), guardadas como datos puros en lua/ascii_headers/ (fuera de
-- lua/plugins/ a propósito, para que lazy.nvim no las trate como specs
-- de plugin). Cada archivo define su propia paleta de highlights y una
-- rejilla de caracteres Braille; converttimos ese formato (pensado para
-- alpha-nvim) a la lista plana de "Text" que espera item.text en Snacks.

local ASCII_NAMES = {
  "abstract_portrait",
  "black_cat",
  "blue_bubblegum",
  "calm_eyes",
  "cat_girl",
  "color_eyes",
  "girl_bandaged_eyes",
  "red_jpa",
}

local QUOTES = {
  "Escribe menos. Comunica más.",
  "El código limpio se lee como una historia clara.",
  "La velocidad se gana con claridad, no con prisa.",
  "Cada tecla es una decisión de diseño.",
  "Las herramientas se olvidan; el oficio permanece.",
}

math.randomseed(os.time())
local quote = QUOTES[math.random(#QUOTES)]

local function load_ascii_header(name)
  local path = vim.fn.stdpath("config") .. "/lua/ascii_headers/" .. name .. ".lua"
  local chunk = loadfile(path)
  if not chunk then
    return nil
  end
  local ok, mod = pcall(chunk)
  return (ok and mod and mod.header) or nil
end

-- item.text en Snacks es una lista PLANA de {texto, hl=...}: los saltos
-- de línea se marcan agregando "\n" al final del último segmento de cada
-- fila, no anidando listas de líneas.
local function to_snacks_text(ascii_header)
  local lines = ascii_header.val or {}
  local hl_by_line = (ascii_header.opts and ascii_header.opts.hl) or {}
  local texts = {}
  for i, raw_line in ipairs(lines) do
    -- las líneas traen un espacio inicial ajeno a la rejilla de colores
    -- (los offsets de "hl" son relativos al texto sin ese espacio)
    local line = raw_line:sub(2)
    local segments = hl_by_line[i]
    if segments and #segments > 0 then
      for si, seg in ipairs(segments) do
        local group, from, to = seg[1], seg[2], seg[3]
        local chunk = line:sub(from + 1, to)
        if si == #segments and i < #lines then
          chunk = chunk .. "\n"
        end
        texts[#texts + 1] = { chunk, hl = group }
      end
    else
      texts[#texts + 1] = { i < #lines and (line .. "\n") or line, hl = "header" }
    end
  end
  return texts
end

-- Algunas imágenes tienen muchas más filas que otras; si el header no
-- entra en la ventana junto con el resto de secciones, el buffer termina
-- con scroll en vez de quedar fijo. Recortamos filas simétricamente
-- (centrado) para que siempre quepa, igual que hacía "constrain_header_size"
-- en el repo de referencia.
local function clip_header(ascii_header, max_lines)
  local val = ascii_header.val or {}
  if #val <= max_lines then
    return ascii_header
  end
  local hl_by_line = (ascii_header.opts and ascii_header.opts.hl) or {}
  local start_idx = math.floor((#val - max_lines) / 2) + 1
  local new_val, new_hl = {}, {}
  for i = start_idx, start_idx + max_lines - 1 do
    table.insert(new_val, val[i])
    table.insert(new_hl, hl_by_line[i])
  end
  return { val = new_val, opts = { hl = new_hl } }
end

-- líneas aproximadas que consumen frase + menú + footer + sus paddings,
-- para saber cuánto espacio vertical le queda de verdad al header
local NON_HEADER_ROWS = 16

-- Cuando la imagen elegida es más corta que la ventana, Snacks centra
-- todo pero deja espacio real por debajo: Neovim lo rellena con "~" y ese
-- tramo se puede "scrollear" (aunque no haya nada que ver). Ocultamos esas
-- marcas para que se vea como espacio fijo, no como buffer con más contenido.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "snacks_dashboard",
  group = vim.api.nvim_create_augroup("dashboard_hide_eob", { clear = true }),
  callback = function()
    vim.opt_local.fillchars:append({ eob = " " })
  end,
})

local chosen_header = load_ascii_header(ASCII_NAMES[math.random(#ASCII_NAMES)])

local function pad(text, width)
  local len = vim.fn.strdisplaywidth(text)
  return len >= width and text or text .. string.rep(" ", width - len)
end

local function grid_row(left, right)
  return (" %s │ %s"):format(pad(left, 22), pad(right, 22))
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        sections = {
          chosen_header and function()
            local max_lines = math.max(6, vim.o.lines - NON_HEADER_ROWS)
            return {
              align = "center",
              padding = 2,
              text = to_snacks_text(clip_header(chosen_header, max_lines)),
            }
          end or { section = "header" },
          { text = { { quote, hl = "comment" } }, align = "center", padding = 2 },
          {
            align = "center",
            padding = 1,
            -- necesita una acción propia (aunque sea la más obvia, "find
            -- files") para que el auto-seguimiento de cursor de Snacks
            -- tenga un ítem real donde anclarse; sin esto, al no haber
            -- ningún ítem visible con acción, el cursor queda libre para
            -- moverse por los renglones de relleno (se siente como si
            -- "sobrara espacio" y se pudiera hacer scroll).
            action = ":lua Snacks.dashboard.pick('files')",
            text = {
              {
                table.concat({
                  " ┌────────────────────────┬────────────────────────┐",
                  grid_row("[f] Find Files", "[r] Recent Files"),
                  grid_row("[g] Find Text", "[c] Config"),
                  grid_row("[s] Restore Session", "[n] New File"),
                  grid_row("[l] Lazy", "[q] Quit"),
                  " └────────────────────────┴────────────────────────┘",
                }, "\n"),
                hl = "comment",
              },
            },
          },
          { key = "f", action = ":lua Snacks.dashboard.pick('files')", hidden = true },
          { key = "g", action = ":lua Snacks.dashboard.pick('live_grep')", hidden = true },
          { key = "r", action = ":lua Snacks.dashboard.pick('oldfiles')", hidden = true },
          {
            key = "c",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
            hidden = true,
          },
          { key = "n", action = ":ene | startinsert", hidden = true },
          { key = "s", section = "session", hidden = true },
          { key = "l", action = ":Lazy", hidden = true },
          { key = "q", action = ":qa", hidden = true },
          function()
            local stats = require("lazy.stats").stats()
            local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
            return {
              align = "center",
              padding = 1,
              text = {
                { os.date("%d-%m-%Y  %H:%M"), hl = "footer" },
                { "  •  ", hl = "footer" },
                { stats.loaded .. "/" .. stats.count .. " plugins", hl = "special" },
                { "  •  ", hl = "footer" },
                { ms .. "ms", hl = "special" },
              },
            }
          end,
        },
      },
    },
  },
}
