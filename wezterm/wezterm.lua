local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ─── Estado persistente (tema y transparencia) ────────────
-- Se guardan fuera del repo, en %LOCALAPPDATA%, para no ensuciar
-- wezterm-config-w. Mismo patrón que persist_colorscheme en tu config de nvim.
local state_dir = os.getenv("LOCALAPPDATA") or wezterm.home_dir
local theme_file = state_dir .. "/wezterm-theme"
local opacity_file = state_dir .. "/wezterm-opacity"

local DEFAULT_SCHEME = "Catppuccin Mocha"
local SESION_TMUX = "conf-term" -- sesión de tmux a la que lleva Ctrl+Shift+M (antes "main")
local TRANSPARENTE = 0.85
local OPACO = 1.0

local function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local v = (f:read("*a") or ""):gsub("^%s*(.-)%s*$", "%1")
	f:close()
	return v ~= "" and v or nil
end

local function write_file(path, value)
	local f = io.open(path, "w")
	if f then
		f:write(tostring(value))
		f:close()
	end
end

local function saved_theme()
	return read_file(theme_file) or DEFAULT_SCHEME
end

local function saved_opacity()
	return tonumber(read_file(opacity_file) or "") or TRANSPARENTE
end

-- Colores de la barra de tabs derivados del esquema activo, para que la tab
-- seleccionada no quede con el negro por defecto y siga al tema al cambiarlo.
local function colores_tabs(scheme_name)
	local scheme = wezterm.color.get_builtin_schemes()[scheme_name]
	if not scheme then
		return {}
	end
	local bg = wezterm.color.parse(scheme.background)
	return {
		tab_bar = {
			active_tab = { bg_color = bg:lighten(0.15), fg_color = scheme.foreground },
			inactive_tab = { bg_color = bg:lighten(0.04), fg_color = scheme.brights[1] },
			inactive_tab_hover = { bg_color = bg:lighten(0.1), fg_color = scheme.foreground },
		},
	}
end

local function hex(color)
	local r, g, b = color:srgba_u8()
	return string.format("#%02x%02x%02x", r, g, b)
end

-- Colores de la paleta de comandos (Ctrl+Shift+P) derivados del esquema activo:
-- fondo un poco más claro que el terminal para que se despegue, y el cian del
-- tema como acento. WezTerm pinta la fila seleccionada con los colores
-- invertidos, así que la barra de selección sale cian con texto oscuro.
local function colores_paleta(scheme_name)
	local scheme = wezterm.color.get_builtin_schemes()[scheme_name]
	if not scheme then
		return {}
	end
	return {
		command_palette_bg_color = hex(wezterm.color.parse(scheme.background):lighten(0.05)),
		command_palette_fg_color = scheme.ansi[7], -- cian
	}
end

-- Aplica SIEMPRE tema y opacidad juntos: set_config_overrides reemplaza el
-- conjunto entero de overrides, así que mandar solo uno borraría el otro.
local function aplicar_estado()
	local overrides = {
		color_scheme = saved_theme(),
		window_background_opacity = saved_opacity(),
		colors = colores_tabs(saved_theme()),
	}
	for clave, valor in pairs(colores_paleta(saved_theme())) do
		overrides[clave] = valor
	end
	for _, mux_win in ipairs(wezterm.mux.all_windows()) do
		local gui = mux_win:gui_window()
		if gui then
			gui:set_config_overrides(overrides)
		end
	end
end

-- ─── Apariencia ───────────────────────────────────────────
config.color_scheme = saved_theme()
config.colors = colores_tabs(saved_theme())
for clave, valor in pairs(colores_paleta(saved_theme())) do
	config[clave] = valor
end
config.command_palette_font_size = 12.0 -- por defecto es 14, desentona con la terminal
config.command_palette_rows = 10
config.font = wezterm.font("JetBrainsMono NF", { weight = "Regular" })
config.font_size = 11.0
config.line_height = 1.15 -- más aire entre líneas
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" } -- ligaduras activas

-- ─── Ventana ──────────────────────────────────────────────
config.window_background_opacity = saved_opacity()
config.win32_system_backdrop = "Acrylic" -- blur del fondo (Windows 11)
config.window_decorations = "TITLE | RESIZE" -- barra nativa de Windows (con el blur de Acrylic)

-- Título de la ventana en blanco (el icono lo pone el marco de Windows y no se puede quitar).
wezterm.on("format-window-title", function()
	return " "
end)
config.initial_cols = 158 -- tamaño inicial de la ventana (columnas x filas);
config.initial_rows = 34 -- solo fija el tamaño al abrir, se puede redimensionar libremente
config.window_padding = {
	left = 16,
	right = 16,
	top = 12,
	bottom = 0, -- el sobrante de píxeles de la última fila ya deja hueco abajo
}

-- ─── Tabs ─────────────────────────────────────────────────
config.enable_tab_bar = false -- barra de pestañas oculta (las tabs se manejan con atajos)

-- ─── Cursor ───────────────────────────────────────────────
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 800 -- ms por ciclo
config.cursor_blink_ease_in = "EaseInOut" -- parpadeo suave en vez de on/off brusco
config.cursor_blink_ease_out = "EaseInOut"

-- ─── Rendimiento ──────────────────────────────────────────
config.max_fps = 120
config.animation_fps = 60

-- ─── Teclado extendido ────────────────────────────────────
-- Permite que Ctrl+Shift+<tecla> llegue distinguible hasta tmux
-- (los splits/paneles ahora los maneja tmux, no WezTerm; ver .tmux.conf en WSL)
config.enable_kitty_keyboard = true

-- Alt izquierdo actua como Meta (envia ESC+tecla) en vez de componer caracteres,
-- para que Alt+T / Alt+W lleguen a tmux. Es el valor por defecto; se deja
-- explicito porque de el dependen los binds de ~/.tmux.conf en WSL.
config.send_composed_key_when_left_alt_is_pressed = false

-- ─── Shell por defecto (Windows) ──────────────────────────
config.default_prog = { "pwsh.exe", "-NoLogo" } -- PowerShell 7
-- config.default_prog = { 'cmd.exe' }                       -- CMD
-- config.default_prog = { 'wsl.exe', '~' }                  -- WSL

-- ─── Atajos de teclado ────────────────────────────────────
config.keys = {
	-- Ctrl+Shift+P: paleta de comandos propia de tmux (popup centrado, ver
	-- ~/.local/bin/tmux-palette en WSL) cuando la pestaña corre WSL; en cualquier
	-- otra (PowerShell) abre la paleta de WezTerm. Se detecta WSL por el nombre
	-- del proceso o el título de la pestaña.
	{
		key = "p",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			local proceso = (pane:get_foreground_process_name() or ""):lower()
			local titulo = (pane:get_title() or ""):lower()
			if proceso:find("wsl", 1, true) or titulo:find("wsl", 1, true) then
				window:perform_action(wezterm.action.SendKey({ key = "p", mods = "ALT" }), pane)
			else
				window:perform_action(wezterm.action.ActivateCommandPalette, pane)
			end
		end),
	},
	-- Ctrl+Shift+Alt+P: la paleta de WezTerm de siempre (tema, transparencia, etc.)
	{ key = "p", mods = "CTRL|SHIFT|ALT", action = wezterm.action.ActivateCommandPalette },
	-- Nueva tab
	{ key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	-- Cerrar tab
	{ key = "w", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
	-- Splits, navegación entre paneles, cerrar panel y zoom ahora los maneja
	-- tmux (ver .tmux.conf en WSL) — estas teclas ya no están capturadas por
	-- WezTerm para que lleguen hasta la sesión de tmux sin interferencia.
	-- Nueva tab con WSL + tmux (crea la sesion SESION_TMUX o se reconecta si ya existe)
	{
		key = "m",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SpawnCommandInNewTab({
			args = { "wsl.exe", "-d", "Ubuntu", "--", "tmux", "new-session", "-A", "-s", SESION_TMUX },
		}),
	},
	-- Ctrl+Shift+E — selector de tema, equivalente a <leader>uC en nvim.
	-- Lista difusa de los esquemas integrados; se aplica al vuelo y se recuerda.
	{
		key = "e",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			local choices = {}
			for name in pairs(wezterm.color.get_builtin_schemes()) do
				table.insert(choices, { label = name })
			end
			table.sort(choices, function(a, b)
				return a.label < b.label
			end)
			window:perform_action(
				wezterm.action.InputSelector({
					title = "Tema de WezTerm",
					description = "Escribe para filtrar · Enter aplica · Esc cancela",
					fuzzy = true,
					choices = choices,
					action = wezterm.action_callback(function(_, _, _, label)
						if not label then
							return
						end
						write_file(theme_file, label)
						aplicar_estado()
					end),
				}),
				pane
			)
		end),
	},
	-- Ctrl+Shift+O — alterna transparencia (0.95) / opaco (1.0).
	{
		key = "o",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window)
			local siguiente = saved_opacity() < 1.0 and OPACO or TRANSPARENTE
			write_file(opacity_file, siguiente)
			aplicar_estado()
			window:toast_notification(
				"WezTerm",
				siguiente < 1.0 and "Transparencia activada" or "Transparencia desactivada",
				nil,
				2000
			)
		end),
	},
}

-- ─── Paleta de comandos (Ctrl+Shift+P): sesiones de tmux ──────────
-- Abren una pestaña nueva de WezTerm conectada a la sesión. Se usa --exec (sin
-- shell) para que el nombre de la sesión no se interprete como comando.
local function tmux_en_pestana_nueva(window, pane, nombre)
	window:perform_action(
		wezterm.action.SpawnCommandInNewTab({
			args = { "wsl.exe", "-d", "Ubuntu", "--exec", "tmux", "new-session", "-A", "-s", nombre },
		}),
		pane
	)
end

wezterm.on("augment-command-palette", function()
	return {
		{
			brief = "tmux: nueva sesión",
			action = wezterm.action.PromptInputLine({
				description = "Nombre de la nueva sesión de tmux",
				action = wezterm.action_callback(function(window, pane, line)
					-- tmux no admite "." ni ":" en el nombre; se limpian también los espacios de los bordes
					local nombre = (line or ""):gsub("[%.:]", "_"):gsub("^%s+", ""):gsub("%s+$", "")
					if nombre ~= "" then
						tmux_en_pestana_nueva(window, pane, nombre)
					end
				end),
			}),
		},
		{
			brief = "tmux: ir a sesión",
			-- La lista se pide al abrir el selector, no al abrir la paleta.
			action = wezterm.action_callback(function(window, pane)
				local ok, stdout = wezterm.run_child_process({
					"wsl.exe", "-d", "Ubuntu", "--exec", "tmux", "list-sessions", "-F", "#S",
				})
				local choices = {}
				if ok then
					for nombre in stdout:gmatch("[^\r\n]+") do
						table.insert(choices, { label = nombre })
					end
				end
				if #choices == 0 then
					window:toast_notification("WezTerm", "No hay sesiones de tmux", nil, 2000)
					return
				end
				window:perform_action(
					wezterm.action.InputSelector({
						title = "Ir a sesión de tmux",
						choices = choices,
						fuzzy = true,
						action = wezterm.action_callback(function(w, p, _, label)
							if label then
								tmux_en_pestana_nueva(w, p, label)
							end
						end),
					}),
					pane
				)
			end),
		},
	}
end)

return config
