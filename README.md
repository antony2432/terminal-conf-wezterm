# terminal-conf-wezterm

Documentación completa de la configuración de terminal de Antony: qué se instaló, qué se cambió, dónde vive cada archivo y cómo reproducirlo desde cero en una máquina nueva.

Resultado final: una ventana de **WezTerm** translúcida con blur Acrylic de Windows 11, paleta **Nord**, que abre **tmux** dentro de **WSL2 (Ubuntu)** con **zsh + Powerlevel10k**, un banner de **fastfetch** centrado, una paleta de comandos propia, un **countdown** propio y **Claude Code** personalizado (status line, estilo de salida, mod `/countdown` y memoria global).

> Estado documentado: 2026-11-16. Las secciones "Archivo completo" son copias exactas de los archivos en uso en esa fecha.

---

## Uso rápido

### Instalar en una máquina nueva (dentro de WSL)

```bash
git clone git@github.com:antony2432/terminal-conf-wezterm.git ~/terminal-conf-wezterm
cd ~/terminal-conf-wezterm
./install.sh --dry-run     # revisar qué se va a cambiar, sin tocar nada
./install.sh --deps        # instalar paquetes + colocar todos los archivos
```

Requisitos previos en Windows: WezTerm y JetBrainsMono Nerd Font instalados (ver [3.1](#31-windows)). Después de instalar, abrir WezTerm y pulsar `Ctrl+Shift+M`.

### Guardar en el repo los cambios hechos en esta máquina

```bash
cd ~/terminal-conf-wezterm
./actualizar.sh            # copia la config en uso al repo
git diff                   # revisar los cambios
git add -A && git commit -m "Describe el cambio" && git push
```

### Notas

- `actualizar.sh` actualiza los archivos de configuración del repo, pero **no** las copias incrustadas en este README (secciones "Archivo completo"). Si el cambio es relevante, actualizar también la sección correspondiente.
- `install.sh` guarda una copia de cada archivo que sobrescribe en `~/.terminal-conf-backup/<fecha>/`.
- La carpeta `nvim/` es una copia de la configuración de Neovim, cuyo repositorio original es `antony2432/nvm-config`. Los cambios de nvim deben subirse también a ese repositorio.
- El repositorio no contiene secretos (credenciales de Claude Code, cookies de ytm-player, key de atuin), pero sí archivos personales: el estilo de salida de Claude Code (`claude/output-styles/nino.md`), `claude/CLAUDE.md` y rutas con el nombre de usuario. Tenerlo en cuenta al decidir si el repositorio es público o privado.
- El mod `/countdown` de Claude Code no se instala automáticamente (ver [13.4](#134-mod-countdown-dentro-de-claude-code)).

---

## Índice

1. [Arquitectura general](#1-arquitectura-general)
2. [Versiones y herramientas](#2-versiones-y-herramientas)
3. [Instalación desde cero](#3-instalación-desde-cero)
4. [Paleta de colores Nord](#4-paleta-de-colores-nord)
5. [WezTerm (Windows)](#5-wezterm-windows)
6. [tmux](#6-tmux)
7. [Paleta de comandos de tmux (`tmux-palette`)](#7-paleta-de-comandos-de-tmux-tmux-palette)
8. [zsh (`~/.zshrc`)](#8-zsh-zshrc)
9. [Prompt: Powerlevel10k compacto](#9-prompt-powerlevel10k-compacto)
10. [fastfetch y el banner centrado (`cf`)](#10-fastfetch-y-el-banner-centrado-cf)
11. [atuin, zoxide, autosuggestions, eza](#11-atuin-zoxide-autosuggestions-eza)
12. [countdown propio](#12-countdown-propio)
13. [Claude Code personalizado](#13-claude-code-personalizado)
14. [Neovim (LazyVim) a juego](#14-neovim-lazyvim-a-juego)
15. [Música en terminal (ytm-player)](#15-música-en-terminal-ytm-player)
16. [Atajos de teclado: referencia rápida](#16-atajos-de-teclado-referencia-rápida)
17. [Problemas conocidos y trampas técnicas](#17-problemas-conocidos-y-trampas-técnicas)
18. [Pendientes](#18-pendientes)
19. [Mapa de archivos](#19-mapa-de-archivos)

---

## 1. Arquitectura general

```
Windows 11
└── WezTerm 20240203  (C:\Users\Antony\.config\wezterm\wezterm.lua)
    │   Acrylic + opacidad 0.85, tema Nord, JetBrainsMono Nerd Font
    │   Ctrl+Shift+M ─► wsl.exe -d Ubuntu -- tmux new-session -A -s conf-term
    │
    └── WSL2 · Ubuntu 26.04
        └── tmux 3.6  (~/.tmux.conf)
            │   barra Nord de 2 filas, splits con Alt, F12 flotante, Alt+P paleta
            │
            └── zsh 5.9  (~/.zshrc)
                ├── Powerlevel10k (~/.p10k.zsh, bloque "compacto")
                ├── banner fastfetch centrado (cf)
                ├── atuin · zoxide · zsh-autosuggestions · eza
                ├── countdown  (~/.local/bin/countdown)
                ├── nvim (LazyVim, tema Nord transparente)
                └── claude (Claude Code: status line, estilo Nino, mod /countdown)
```

Principios que guían todo el diseño:

- **Una sola paleta (Nord)** en WezTerm, tmux, prompt, fastfetch, atuin, fzf, status line de Claude Code y Neovim.
- **Transparencia en todas las capas**: WezTerm aporta el blur; tmux, nvim y el prompt usan fondo `default` para no taparlo.
- **Atajos sin prefijo**: casi todo se maneja con `Alt+<tecla>` en tmux y `Ctrl+Shift+<tecla>` en WezTerm.
- **Arranque rápido**: nvm en modo lazy, instant prompt de p10k (arranque de zsh ~0.26 s).

---

## 2. Versiones y herramientas

| Herramienta | Versión | Origen | Para qué |
|---|---|---|---|
| Windows 11 | — | — | Host. Necesario para `win32_system_backdrop = "Acrylic"` |
| WezTerm | 20240203-110809-5046fc22 | instalador oficial (Windows) | Emulador de terminal |
| JetBrainsMono Nerd Font | — | nerdfonts.com, instalada en Windows | Fuente con iconos (eza, p10k, fastfetch) |
| WSL2 · Ubuntu | 26.04 LTS (kernel 6.18 WSL2) | `wsl --install -d Ubuntu` | Entorno Linux |
| zsh | 5.9 | apt | Shell |
| tmux | 3.6 | apt | Multiplexor |
| Powerlevel10k | git (`romkatv/powerlevel10k`) | clon en `~/.local/share/powerlevel10k` | Prompt |
| zsh-autosuggestions | 0.7.1 | apt | Sugerencias en gris |
| fastfetch | 2.57.1 | apt | Banner de sistema |
| eza | 0.23.4 | apt | `ls` con iconos |
| zoxide | 0.9.8 | apt | `cd` con memoria (`z`) |
| atuin | 18.8.0 | apt / instalador oficial | Historial con búsqueda difusa |
| fzf | 0.67.0 | apt | Menú de la paleta de tmux |
| git | 2.53.0 | apt | — |
| Python | 3.14.4 | apt | `countdown`, status line de Claude Code |
| Node | v24.16.0 | nvm (`~/.nvm`) | Herramientas JS / LSPs |
| Neovim | 0.11.6 | — | Editor (LazyVim) |
| win32yank.exe | — | viene con Neovim de Windows (`C:\Program Files\Neovim\bin`) | Portapapeles Windows ↔ WSL |
| Claude Code | 2.1.325 | instalador nativo (`~/.local/share/claude`) | Asistente |
| yt-dlp | 2026.10.26 | binario en `~/.local/bin` | Descargas de audio |
| ytm-player | 2.2.0 | pipx | YouTube Music en terminal |
| mpv | 0.41.0 | apt | Reproductor usado por ytm-player |

---

## 3. Instalación desde cero

### 3.1 Windows

1. Instalar **WezTerm** (instalador oficial, versión estable 20240203).
2. Instalar **JetBrainsMono Nerd Font** (todas las variantes `.ttf`, "Instalar para todos los usuarios" o solo usuario).
3. Copiar `wezterm.lua` (sección 5) a `C:\Users\<usuario>\.config\wezterm\wezterm.lua`.
4. (Opcional) Crear el estado inicial en `%LOCALAPPDATA%`:
   - `wezterm-theme` con el contenido `nord`
   - `wezterm-opacity` con el contenido `0.85`

   Si no existen, WezTerm usa `Catppuccin Mocha` y `0.85`; se pueden elegir luego con `Ctrl+Shift+E` y `Ctrl+Shift+O`.

### 3.2 WSL / Ubuntu

```bash
# Paquetes base
sudo apt update
sudo apt install -y zsh tmux git fzf eza zoxide fastfetch zsh-autosuggestions \
                    python3 mpv pipx
# atuin (si no está en apt de la distro)
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

# zsh como shell por defecto
chsh -s "$(command -v zsh)"

# Powerlevel10k (sin gestor de plugins)
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.local/share/powerlevel10k

# nvm + node LTS
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
# (abrir nueva shell) nvm install --lts && nvm alias default node

# Claude Code (instalador nativo, deja el binario en ~/.local/bin/claude)
curl -fsSL https://claude.ai/install.sh | bash
```

### 3.3 Colocar los archivos con `install.sh` (recomendado)

```bash
git clone <url-de-este-repo> ~/terminal-conf-wezterm
cd ~/terminal-conf-wezterm
./install.sh --dry-run     # ver qué haría, sin tocar nada
./install.sh --deps        # máquina nueva: paquetes apt, p10k, atuin, nvm + archivos
./install.sh               # solo copiar los archivos
./install.sh --link        # enlazar (symlink) al repo: editar ~/.tmux.conf edita el repo
```

- Antes de sobrescribir algo guarda una copia en `~/.terminal-conf-backup/<fecha>/`.
- Lo que ya es idéntico no se toca (`= ... (sin cambios)`), así que se puede ejecutar varias veces.
- `wezterm.lua` se copia siempre a `%USERPROFILE%\.config\wezterm\` (Windows no sigue symlinks de WSL). `wezterm-theme` y `wezterm-opacity` solo se crean si no existen.
- Si `~/.config/nvim` ya es un repositorio git, no se toca.
- El mod `/countdown` de Claude Code no se instala automáticamente (ver 13.4).

Para llevar al repo los cambios hechos en la máquina: `./actualizar.sh` (operación inversa), luego `git diff` y commit.

### Estructura del repositorio

```
terminal-conf-wezterm/
├── README.md
├── install.sh                  # repo → sistema
├── actualizar.sh               # sistema → repo
├── wezterm/                    # wezterm.lua, wezterm-theme, wezterm-opacity
├── tmux/tmux.conf
├── bin/                        # tmux-palette, countdown
├── zsh/                        # zshrc, p10k.zsh, completions/_countdown
├── fastfetch/config.jsonc
├── atuin/                      # config.toml, themes/nordtron.toml
├── countdown/config
├── audio/asoundrc              # ALSA → PulseAudio de WSLg
├── claude/                     # settings, statusline.py, CLAUDE.md, output-styles/nino.md, mods/countdown
└── nvim/                       # copia de ~/.config/nvim (repo original: antony2432/nvm-config)
```

No se incluyen a propósito: `~/.claude/.credentials.json`, `~/.claude/memory/` (notas personales), `~/.config/ytm-player/` (cookies y sesión de Google), la key de sync de atuin (`~/.local/share/atuin/`).

### 3.4 Colocación manual (equivalencias)

| Archivo de este README | Destino |
|---|---|
| sección 6 | `~/.tmux.conf` |
| sección 7 | `~/.local/bin/tmux-palette` (`chmod +x`) |
| sección 8 | `~/.zshrc` |
| sección 9 | añadir al final de `~/.p10k.zsh` (generado antes con `p10k configure`, plantilla **lean**) |
| sección 10 | `~/.config/fastfetch/config.jsonc` |
| sección 11 | `~/.config/atuin/themes/nordtron.toml` + `[theme] name = "nordtron"` en `~/.config/atuin/config.toml` |
| sección 12 | `~/.local/bin/countdown` (`chmod +x`), `~/.local/share/zsh/site-functions/_countdown`, `~/.config/countdown/config` |
| sección 13 | `~/.claude/statusline.py`, `~/.claude/settings.json`, `~/.claude/settings.local.json`, `~/.claude/output-styles/nino.md`, `~/.claude/CLAUDE.md` |

Después: cerrar y abrir WezTerm, pulsar `Ctrl+Shift+M`.

---

## 4. Paleta de colores Nord

| Nombre | Hex | RGB | Dónde se usa |
|---|---|---|---|
| nord0 | `#2e3440` | 46,52,64 | Fondo sólido del popup de la paleta de tmux y de fzf |
| nord1 | `#3b4252` | 59,66,82 | Línea separadora de tmux, borde de panel inactivo, selección de fzf |
| nord2 | `#434c5e` | 67,76,94 | Selección en copy-mode de tmux |
| nord3 | `#4c566a` | 76,86,106 | Texto apagado, borde de panel activo, sugerencias de zsh, barras vacías |
| nord4 | `#d8dee9` | 216,222,233 | Texto principal |
| nord6 | `#eceff4` | 236,239,244 | Texto resaltado |
| nord7 | `#8fbcbb` | 143,188,187 | Git modificado (prompt) |
| nord8 | `#88c0d0` | 136,192,208 | Acento cian: ruta, ventana activa, claves de fastfetch, bordes de popup |
| nord9 | `#81a1c1` | 129,161,193 | Hora en tmux |
| nord10 | `#5e81ac` | 94,129,172 | Corchetes, separadores, símbolo `❯` |
| nord11 | `#bf616a` | 191,97,106 | Errores, confirmaciones destructivas |
| nord13 | `#ebcb8b` | 235,203,139 | Actividad / advertencias |
| nord14 | `#a3be8c` | 163,190,140 | OK / barras < 50 % |
| nord15 | `#b48ead` | 180,142,173 | Nombre de sesión, rama git, usuario |

---

## 5. WezTerm (Windows)

**Ruta:** `C:\Users\Antony\.config\wezterm\wezterm.lua` (desde WSL: `/mnt/c/Users/Antony/.config/wezterm/wezterm.lua`).
**Estado persistente:** `%LOCALAPPDATA%\wezterm-theme` (actual: `nord`) y `%LOCALAPPDATA%\wezterm-opacity` (actual: `0.85`). El archivo de opacidad tiene prioridad sobre el valor por defecto del código.

### Decisiones y por qué

| Ajuste | Valor | Motivo |
|---|---|---|
| `window_decorations` | `"TITLE \| RESIZE"` | Barra de título nativa de Windows: es la única que recibe el blur Acrylic. Se probó la barra con botones integrados (`INTEGRATED_BUTTONS`) y quedaba plana/opaca; se descartó. |
| `format-window-title` | `" "` | Título vacío. El icono del marco nativo no se puede quitar. |
| `win32_system_backdrop` | `"Acrylic"` | Blur del escritorio detrás de la ventana. |
| `window_background_opacity` | `0.85` | Balance entre legibilidad y transparencia. `Ctrl+Shift+O` alterna con `1.0`. |
| `enable_tab_bar` | `false` | Las pestañas se manejan con atajos; la barra rompía el look limpio. |
| `font` | JetBrainsMono NF 11, `line_height = 1.15` | Nerd Font con ligaduras (`calt`, `clig`, `liga`). |
| `window_padding` | 16 / 16 / 12 / 0 | Abajo 0 porque el sobrante de píxeles de la última fila ya deja hueco. |
| `initial_cols/rows` | 158 × 34 | Tamaño inicial; la ventana se puede redimensionar. |
| Cursor | `BlinkingBar`, 800 ms, `EaseInOut` | Parpadeo suave en vez de on/off. |
| `enable_kitty_keyboard` | `true` | Para que `Ctrl+Shift+<tecla>` llegue distinguible a tmux. |
| `send_composed_key_when_left_alt_is_pressed` | `false` | Alt izquierdo actúa como Meta: necesario para los binds `Alt+*` de tmux. |
| `default_prog` | `pwsh.exe -NoLogo` | La pestaña por defecto es PowerShell 7; WSL+tmux se abre con `Ctrl+Shift+M`. |
| `SESION_TMUX` | `"conf-term"` | Sesión a la que se conecta `Ctrl+Shift+M`. Si se renombra la sesión, cambiar esta variable. |
| Colores de la paleta de WezTerm y de pestañas | derivados del esquema activo | `colores_tabs()` / `colores_paleta()`; se reaplican al cambiar de tema. |

### Atajos de WezTerm

| Atajo | Acción |
|---|---|
| `Ctrl+Shift+M` | Nueva pestaña con WSL + tmux, sesión `conf-term` (la crea o se reconecta) |
| `Ctrl+Shift+P` | En pestaña WSL: envía `Alt+P` a tmux (paleta propia). En PowerShell: paleta de WezTerm |
| `Ctrl+Shift+Alt+P` | Paleta de WezTerm siempre (incluye "tmux: nueva sesión" e "ir a sesión") |
| `Ctrl+Shift+E` | Selector difuso de tema; se aplica al vuelo y se guarda |
| `Ctrl+Shift+O` | Alterna transparencia (0.85) / opaco (1.0) y se guarda |
| `Ctrl+Shift+T` | Nueva pestaña (dominio actual) |
| `Ctrl+Shift+W` | Cerrar pestaña sin confirmar |

### Validar la config sin abrir la GUI (desde WSL)

```bash
"/mnt/c/Program Files/WezTerm/wezterm.exe" \
  --config-file "$(wslpath -w /mnt/c/Users/Antony/.config/wezterm/wezterm.lua)" show-keys
```

Un campo inexistente en la config **no** da error en `show-keys`; comprobar nombres de opciones en la documentación de la versión instalada.

<details>
<summary><b>Archivo completo: <code>wezterm.lua</code></b></summary>

```lua
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
```

</details>

---

## 6. tmux

**Ruta:** `~/.tmux.conf` (tmux 3.6). Sin TPM ni plugins: todo escrito a mano.

### Qué hace

- **Color:** `tmux-256color` + override `Tc` para true color.
- **Teclado extendido:** `extended-keys on` + `terminal-features 'xterm*:extkeys'` (pareja de `enable_kitty_keyboard` de WezTerm).
- **Índices desde 1**, `renumber-windows on`, ratón activo, `escape-time 10`, historial de 10 000 líneas.
- **Barra de estado de 2 filas**, fondo transparente (`bg=default`):
  - Fila 0: línea tenue `─` en `#3b4252` del ancho del cliente (`#{R:─,#{client_width}}`).
  - Fila 1: la barra de siempre. Se copia el formato original de tmux a `status-format[1]` solo si la fila 0 todavía es la original (contiene `status-left-style`), así recargar la config no la rompe.
  - Izquierda `[sesión]` (malva), ventanas (activa entre corchetes en cian, resto en gris), derecha `host | HH:MM dd-mes`.
- **Bordes de panel sutiles:** inactivo `#3b4252`, activo `#4c566a`.
- **Terminal flotante (F12):** popup centrado 80 %×75 % con la sesión `flotante` (sin barra). F12 dentro la oculta; la sesión sigue viva.
- **Tab scratch (Shift+F12):** ventana normal llamada `scratch` (a diferencia del popup, admite ratón).
- **Paleta de comandos (Alt+P):** ver sección 7.
- `default-shell /usr/bin/zsh` explícito (el servidor hereda `$SHELL` del momento en que arrancó).

### Atajos de tmux (sin prefijo)

| Atajo | Acción |
|---|---|
| `Alt+T` | Nueva ventana en el directorio actual |
| `Alt+W` | Cerrar ventana |
| `Alt+←` / `Alt+→` | Ventana anterior / siguiente |
| `Alt+\` | Dividir panel a la derecha |
| `Alt+-` | Dividir panel hacia abajo |
| `Alt+H/J/K/L` | Moverse entre paneles (estilo vim) |
| `Alt+Z` | Maximizar / restaurar panel |
| `Alt+Q` | Cerrar panel |
| `Alt+P` | Paleta de comandos |
| `F12` | Terminal flotante |
| `Shift+F12` | Ventana `scratch` (ida y vuelta) |

Jerarquía para no confundirse: **sesión > ventana > panel**. En la barra, `[conf-term]` es la sesión; `1 zsh` es la ventana (índice + programa).

<details>
<summary><b>Archivo completo: <code>~/.tmux.conf</code></b></summary>

```tmux
# ─── Terminal y color ─────────────────────────────────────
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm*:Tc"

# ─── Teclado extendido ────────────────────────────────────
# Necesario para que Ctrl+Shift+<tecla> de WezTerm (enable_kitty_keyboard)
# llegue hasta tmux de forma distinguible. Ver ~/.config/wezterm/wezterm.lua
set -s extended-keys on
set -as terminal-features 'xterm*:extkeys'

# ─── Ventanas (= "tabs") ──────────────────────────────────
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on   # al cerrar una, renumera el resto sin huecos

# Alt+T  -> nueva tab (en el directorio actual)
bind -n M-t new-window -c "#{pane_current_path}"

# Alt+W  -> cerrar tab (sin confirmacion, igual que Ctrl+Shift+W en WezTerm)
bind -n M-w kill-window

# Alt+<-/-> para moverse entre tabs
bind -n M-Left  previous-window
bind -n M-Right next-window

# ─── Varios ───────────────────────────────────────────────
set -g mouse on
set -g escape-time 10        # sin retardo al usar Alt/Esc
set -g history-limit 10000

# ─── Barra de estado (paleta Nord, a juego con oh-my-posh nordtron) ──
# nord0 #2e3440 fondo · nord3 #4c566a apagado · nord8 #88c0d0 cian
# nord10 #5e81ac azul (corchetes) · nord15 #b48ead malva
set -g status on
set -g status-position bottom
set -g status-justify left
set -g status-interval 5
set -g status-style "bg=default,fg=#d8dee9"   # bg=default: transparente, deja ver el blur de WezTerm (antes bg=#2e3440)

# Fila separadora encima de la barra: la barra pasa a 2 filas; la de abajo es
# la barra de siempre (se copia el formato por defecto de tmux) y la de arriba
# es una linea tenue del ancho de la terminal (mismo gris que los bordes de
# panel). Para quitarlo: status on.
# Solo se copia si la fila 0 sigue siendo la original (la original menciona
# status-left-style), asi recargar la config no sobrescribe la barra.
set -g status 2
run-shell 'f=$(tmux show -gv "status-format[0]"); case "$f" in *status-left-style*) tmux set -g "status-format[1]" "$f";; esac'
set -g "status-format[0]" "#[fg=#3b4252]#{R:─,#{client_width}}"

# Izquierda: [sesion]
set -g status-left-length 40
set -g status-left "#[fg=#5e81ac][#[fg=#b48ead,bold]#S#[fg=#5e81ac,nobold]] "

# Tabs: la activa entre corchetes y en cian; las demas, gris apagado
set -g window-status-separator "  "
set -g window-status-format "#[fg=#4c566a]#I #W"
set -g window-status-current-format "#[fg=#5e81ac][#[fg=#88c0d0,bold]#I #W#[fg=#5e81ac,nobold]]"
set -g window-status-activity-style "fg=#ebcb8b"
set -g window-status-bell-style "fg=#bf616a"

# Derecha: host y hora
set -g status-right-length 60
set -g status-right "#[fg=#4c566a]#h #[fg=#5e81ac]| #[fg=#81a1c1]%H:%M #[fg=#4c566a]%d-%b"

# Mensajes, bordes de panel y modo copia, en la misma paleta
set -g message-style "bg=#3b4252,fg=#88c0d0"
set -g message-command-style "bg=#3b4252,fg=#88c0d0"
set -g pane-border-style "fg=#3b4252"
set -g pane-active-border-style "fg=#4c566a"   # sutil (antes fg=#5e81ac)
set -g mode-style "bg=#434c5e,fg=#eceff4"

# ─── Paneles (splits) sin prefijo ─────────────────────────
# Heredan el directorio actual, cosa que los binds por defecto (% y ") no hacen.
bind -n 'M-\' split-window -h -c "#{pane_current_path}"   # Alt+\  al costado
bind -n 'M--' split-window -v -c "#{pane_current_path}"   # Alt+-  abajo

# Moverse entre paneles, estilo vim
bind -n M-h select-pane -L
bind -n M-j select-pane -D
bind -n M-k select-pane -U
bind -n M-l select-pane -R

bind -n M-q kill-pane      # Alt+Q  cerrar panel
bind -n M-z resize-pane -Z # Alt+Z  maximizar / restaurar

# ─── Terminal flotante tipo modal (F12) ───────────────────
# Sesion aparte "flotante" mostrada en un popup centrado.
# F12 la abre; F12 estando dentro la cierra, pero la sesion sigue viva
# en segundo plano, asi que recuperas lo que tenias al volver a abrirla.
bind -n F12 if-shell -F '#{==:#{session_name},flotante}' {
  detach-client
} {
  display-popup -xC -yC -w 80% -h 75% -E "tmux new-session -d -s flotante 2>/dev/null; tmux set-option -t flotante status off; tmux attach-session -t flotante"
}

# Aspecto del popup, en la misma paleta Nord
set -g popup-border-lines rounded
set -g popup-style "bg=default,fg=#d8dee9"
set -g popup-border-style "fg=#88c0d0,bg=default"

# ─── Paleta de comandos (Alt+P) ───────────────────────────
# Popup centrado con fzf; ver ~/.local/bin/tmux-palette. Fondo solido Nord y
# borde cian para distinguirla del texto de atras. WezTerm manda Alt+P cuando
# se pulsa Ctrl+Shift+P dentro de tmux.
# Va por run-shell porque display-popup NO expande formatos (#{...}) en su
# comando, y el script necesita el panel y el cliente reales; run-shell si los
# expande y el script abre el popup (--abrir).
bind -n M-p run-shell -b "~/.local/bin/tmux-palette --abrir '#{pane_id}' '#{pane_current_path}' '#{client_name}'"

# ─── Tab scratch con raton (Shift+F12) ────────────────────
# El popup de F12 no admite raton: tmux no enruta eventos de raton hacia
# un popup (en MOUSE SUPPORT no existe la ubicacion "Popup"). Esta tab si
# es un panel normal, asi que ahi funcionan rueda y seleccion.
bind -n S-F12 if-shell -F '#{==:#{window_name},scratch}' {
  last-window
} {
  run-shell "tmux select-window -t scratch 2>/dev/null || tmux new-window -n scratch -c '#{pane_current_path}'"
}

# ─── Shell por defecto ────────────────────────────────────
# El servidor de tmux hereda $SHELL al arrancar; si se inicio antes del
# cambio a zsh seguiria abriendo bash, asi que se fija explicitamente.
set -g default-shell /usr/bin/zsh
```

</details>

---

## 7. Paleta de comandos de tmux (`tmux-palette`)

**Ruta:** `~/.local/bin/tmux-palette` (bash + fzf). Se abre con `Alt+P` en tmux o `Ctrl+Shift+P` en WezTerm (pestaña WSL).

Popup centrado de 62×17, borde redondeado cian, fondo `#2e3440`, título " Paleta de comandos ". Acciones:

| Acción | Atajo directo |
|---|---|
| Nueva sesión (pide nombre; limpia `.` y `:`) | — |
| Ir a sesión (lista con fzf) | — |
| Nueva ventana | `Alt+T` |
| Dividir panel a la derecha / hacia abajo | `Alt+\` / `Alt+-` |
| Maximizar / restaurar panel | `Alt+Z` |
| Renombrar ventana / sesión | — |
| Cerrar panel / ventana (confirmación `[s/N]` en rojo) | `Alt+Q` / `Alt+W` |
| Desconectar de tmux | — |

**Detalle de implementación importante:** `display-popup` no expande formatos (`#{pane_id}`, `#{client_name}`) dentro de su comando. Por eso el bind usa `run-shell`, que sí los expande, y llama a `tmux-palette --abrir <pane> <ruta> <cliente>`; el script abre él mismo el popup con `display-popup -c <cliente>` y se relanza dentro. Así cada acción se aplica al panel desde el que se abrió y no al popup.

Uso sin menú (pruebas): `tmux-palette --accion "Nueva ventana" <pane_id> <ruta> <cliente>`.

<details>
<summary><b>Archivo completo: <code>~/.local/bin/tmux-palette</code></b></summary>

```bash
#!/usr/bin/env bash
# Paleta de comandos de tmux: se abre en un popup (display-popup) y usa fzf.
#
#   tmux-palette <pane_id> <ruta> <cliente>      menu interactivo
#   tmux-palette --accion "<etiqueta>" <pane_id> <ruta> <cliente>   ejecuta una accion sin menu
#
# El pane, la ruta y el cliente se pasan desde el bind de tmux (formatos
# #{pane_id}, #{pane_current_path}, #{client_name}) para que cada accion se
# aplique al panel y al cliente desde donde se abrio el popup, no al popup.

set -u

# Fondo y texto en la paleta Nord (a juego con tmux y WezTerm).
FZF_COLORS='fg:#d8dee9,bg:#2e3440,hl:#88c0d0,fg+:#eceff4,bg+:#3b4252,hl+:#88c0d0,pointer:#88c0d0,prompt:#5e81ac,gutter:#2e3440,info:#4c566a,header:#4c566a,query:#eceff4'
CIAN=$'\033[38;2;136;192;208m'
ROJO=$'\033[38;2;191;97;106m'
GRIS=$'\033[38;2;76;86;106m'
FIN=$'\033[0m'

# Elegir una linea de stdin con fzf. $1 = prompt.
elegir() {
  fzf --ansi --layout=reverse --info=hidden --no-scrollbar --border=none \
    --padding=1,2 --pointer='▌' --prompt="$1" --color="$FZF_COLORS" \
    --delimiter=$'\t' --tabstop=30 --height=100%
}

# Pedir una linea de texto. Resultado en $REPLY.
pedir() {
  printf '%s%s%s ' "$CIAN" "$1" "$FIN"
  read -r REPLY
}

# Confirmar una accion destructiva con [s/N].
confirmar() {
  printf '%s%s [s/N] %s' "$ROJO" "$1" "$FIN"
  local r
  read -r -n1 r
  echo
  [[ $r == [sSyY] ]]
}

# tmux no admite "." ni ":" en nombres de sesion; se limpian tambien los bordes.
limpiar_nombre() {
  local n="${1//[.:]/_}"
  n="${n#"${n%%[![:space:]]*}"}"
  n="${n%"${n##*[![:space:]]}"}"
  printf '%s' "$n"
}

# ejecutar <etiqueta> <pane_id> <ruta> <cliente>
ejecutar() {
  local accion="$1" pane="$2" ruta="$3" cliente="$4" sesion nombre
  sesion=$(tmux display-message -p -t "$pane" '#{session_id}')
  case "$accion" in
    "Nueva ventana") tmux new-window -t "${sesion}:" -c "$ruta" ;;
    "Dividir panel a la derecha") tmux split-window -h -t "$pane" -c "$ruta" ;;
    "Dividir panel hacia abajo") tmux split-window -v -t "$pane" -c "$ruta" ;;
    "Maximizar / restaurar panel") tmux resize-pane -Z -t "$pane" ;;
    "Cerrar panel") confirmar "Cerrar el panel?" && tmux kill-pane -t "$pane" ;;
    "Cerrar ventana") confirmar "Cerrar la ventana?" && tmux kill-window -t "$pane" ;;
    "Renombrar ventana")
      pedir "Nuevo nombre de la ventana:"
      [[ -n $REPLY ]] && tmux rename-window -t "$pane" "$REPLY"
      ;;
    "Renombrar sesión")
      pedir "Nuevo nombre de la sesión:"
      nombre=$(limpiar_nombre "$REPLY")
      [[ -n $nombre ]] && tmux rename-session -t "$sesion" "$nombre"
      ;;
    "Nueva sesión")
      pedir "Nombre de la nueva sesión:"
      nombre=$(limpiar_nombre "$REPLY")
      if [[ -n $nombre ]]; then
        tmux new-session -d -s "$nombre" -c "$ruta" 2>/dev/null
        tmux switch-client -c "$cliente" -t "=$nombre"
      fi
      ;;
    "Ir a sesión")
      nombre=$(tmux list-sessions -F '#S' | elegir 'sesión ❯ ')
      [[ -n $nombre ]] && tmux switch-client -c "$cliente" -t "=$nombre"
      ;;
    "Desconectar de tmux") tmux detach-client -t "$cliente" ;;
  esac
}

# Una linea por accion: etiqueta <tab> atajo (en gris).
menu() {
  local linea
  while IFS='|' read -r etiqueta atajo; do
    printf '%s\t%s%s%s\n' "$etiqueta" "$GRIS" "$atajo" "$FIN"
  done <<'EOF'
Nueva sesión|
Ir a sesión|
Nueva ventana|Alt+T
Dividir panel a la derecha|Alt+\
Dividir panel hacia abajo|Alt+-
Maximizar / restaurar panel|Alt+Z
Renombrar ventana|
Renombrar sesión|
Cerrar panel|Alt+Q
Cerrar ventana|Alt+W
Desconectar de tmux|
EOF
}

if [[ ${1:-} == --accion ]]; then
  ejecutar "$2" "$3" "$4" "$5"
  exit
fi

# --abrir <pane_id> <ruta> <cliente>: lo llama el bind via run-shell, que SI
# expande los formatos (display-popup no los expande dentro de su comando).
# Abre el popup sobre el cliente indicado y relanza este mismo script dentro.
if [[ ${1:-} == --abrir ]]; then
  tmux display-popup -c "$4" -d "$3" -E -xC -yC -w 62 -h 17 -b rounded \
    -T " Paleta de comandos " -s "bg=#2e3440,fg=#d8dee9" -S "fg=#88c0d0,bg=#2e3440" \
    "$(printf '%q ' "$0" "$2" "$3" "$4")"
  exit
fi

pane="${1:-}" ruta="${2:-$HOME}" cliente="${3:-}"
seleccion=$(menu | elegir '❯ ') || exit 0
[[ -z $seleccion ]] && exit 0
ejecutar "${seleccion%%$'\t'*}" "$pane" "$ruta" "$cliente"
```

</details>

---

## 8. zsh (`~/.zshrc`)

`~/.zshrc` es un **archivo real**, no un symlink. Nota: el repo `~/dean.dots` contiene una versión antigua (`zsh/zshrc`, con `fastfetch_centered` y ZDOTDIR) que **ya no se usa**; la configuración vigente es la de `~/.zshrc`.

Bloques, en orden (el orden importa):

1. **Arrancar en `~`**: `[[ $PWD == /mnt/* ]] && cd ~`. Condicionado a `/mnt/*` para no romper `wsl --cd` ni terminales abiertas en un proyecto (VS Code).
2. **Instant prompt de p10k**: debe ir antes de cualquier cosa que imprima.
3. **Historial**: 10 000 entradas, sin duplicados, compartido entre sesiones.
4. **Completado**: `fpath` incluye `~/.local/share/zsh/site-functions` (ahí vive `_countdown`) **antes** de `compinit`; menú navegable, sin distinguir mayúsculas.
5. **eza**: `ls`, `ll`, `la`, `lt` como funciones con iconos, a través del helper `eza_wrap` (eza 0.23.4 de Ubuntu no imprime nada si solo recibe flags; el helper añade `.`). El helper no lleva prefijo `_`: el Bash tool de Claude Code descarta funciones que empiezan con `_` al copiar el entorno.
6. **Banner `cf`** + hooks (`TRAPWINCH`, `line-init`): ver sección 10.
7. `dev`: atajo a `/mnt/c/Users/Antony/Documents/dev`.
8. **PATH**: `~/.local/bin` (zsh no lee `~/.profile`) y `~/.local/share/nvim/mason/bin`.
9. **ytm**: wrapper con `PIPEWIRE_DEBUG=0` para silenciar avisos de libpipewire.
10. **nvm lazy**: el `bin` del node por defecto se pone en el PATH a mano; `nvm.sh` solo se carga la primera vez que se ejecuta `nvm`. Ahorro ~550 ms por shell (arranque de ~0.83 s a ~0.26 s).
11. **zoxide** y **atuin** (después de `compinit`).
12. **zsh-autosuggestions** con color `#4c566a` y estrategia `(history completion)`.
13. **Powerlevel10k** + `~/.p10k.zsh`.

<details>
<summary><b>Archivo completo: <code>~/.zshrc</code></b></summary>

```zsh
# ── Siempre arrancar en ~ ─────────────────────────────────────────────
# WSL abre en el directorio de Windows (/mnt/...) si se lanza desde ahi.
[[ $PWD == /mnt/* ]] && cd ~

# ── Instant prompt de Powerlevel10k ───────────────────────────────────
# Debe ir al principio del todo; nada que escriba en pantalla puede ir antes.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── Historial ─────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY INC_APPEND_HISTORY EXTENDED_HISTORY

# ── Completado ────────────────────────────────────────────────────────
# fpath debe incluir nuestras funciones ANTES de compinit.
fpath=(~/.local/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"

zstyle ':completion:*' menu select                       # menu navegable con flechas
zstyle ':completion:*' verbose yes                       # mostrar descripciones
zstyle ':completion:*' group-name ''                     # agrupar por tipo
zstyle ':completion:*' list-separator '--'              # separador antes de la descripcion
zstyle ':completion:*:descriptions' format 'Completing %d'  # cabecera de cada grupo
zstyle ':completion:*:warnings' format 'Sin coincidencias para: %d'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # ignorar mayus/minus
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# ── perfil (equivalente a Microsoft.PowerShell_profile.ps1) ───────────
# Terminal-Icons -> eza con iconos (necesita Nerd Font: JetBrainsMono NF)
# Nota: eza 0.23.4 de Ubuntu no imprime nada si no recibe una ruta,
# asi que se la anadimos (".") cuando el usuario solo pasa flags.
eza_wrap() {
  local a has_path=0
  for a in "$@"; do [[ $a != -* ]] && has_path=1; done
  if (( has_path )); then command eza "$@"; else command eza "$@" .; fi
}
ls() { eza_wrap --icons --group-directories-first "$@"; }
ll() { eza_wrap -la --icons --group-directories-first "$@"; }   # Get-ChildItem -Force
la() { eza_wrap -a  --icons --group-directories-first "$@"; }
lt() { eza_wrap --tree --level=2 --icons "$@"; }

# clear + fastfetch centrado horizontalmente. Fastfetch dibuja la info junto al
# logo con codigos de mover el cursor, asi que no se puede rellenar linea a linea:
# se mide el bloque (logo + margen + info) y se desplaza entero con
# --logo-padding-left. El margen (3) debe coincidir con logo.padding.right de
# ~/.config/fastfetch/config.jsonc.
cf() {
  clear
  local gap=3 logo_w=0 info_w=0 line pad
  for line in "${(@f)$(fastfetch --pipe false --structure break --logo-padding-top 0 --logo-padding-right 0 | sed 's/\x1b\[[0-9;?]*[A-Za-z]//g')}"; do
    (( ${#line} > logo_w )) && logo_w=${#line}
  done
  for line in "${(@f)$(fastfetch --pipe false --logo none | sed 's/\x1b\[[0-9;?]*m//g')}"; do
    (( ${#line} > info_w )) && info_w=${#line}
  done
  pad=$(( (COLUMNS - (logo_w + gap + info_w)) / 2 ))
  (( pad < 0 )) && pad=0
  fastfetch --logo-padding-left "$pad"
  echo
  _CF_FRESH=1
}

# Al redimensionar el panel (split de tmux, resize de ventana) el banner ya
# impreso no se reacomoda. Mientras la pantalla solo tenga el banner (nada
# ejecutado despues de cf) se repinta al nuevo ancho; si ya hay trabajo en
# pantalla no se toca. preexec apaga la bandera con cualquier comando.
typeset -g _CF_FRESH=
_cf_preexec() { _CF_FRESH= }
autoload -Uz add-zsh-hook
add-zsh-hook preexec _cf_preexec
TRAPWINCH() {
  [[ -n $_CF_FRESH ]] || return 0
  if zle; then
    cf
    print
    zle -I
    zle reset-prompt
  else
    cf
  fi
}

# Banner al abrir cualquier shell interactiva (terminal nueva, split de tmux).
# Se pinta en el primer line-init de zle (editor de linea ya activo) y no en
# precmd ni al cargar: el instant prompt de p10k redibuja desde arriba al
# terminar su traspaso y borraria el banner. Se borra a si mismo.
_cf_first() {
  add-zle-hook-widget -d line-init _cf_first
  cf
  print
  zle -I
  zle reset-prompt
}
autoload -Uz add-zle-hook-widget
zle -N _cf_first
add-zle-hook-widget line-init _cf_first
dev() { cd /mnt/c/Users/Antony/Documents/dev; }             # atajo a proyectos

# ── Binarios de usuario (Claude Code nativo, etc.) ────────────────────
# zsh no lee ~/.profile, asi que ~/.local/bin hay que anadirlo aqui.
export PATH="$HOME/.local/bin:$PATH"

# ── Binarios de los LSP que instala Mason ─────────────────────────────
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

# ── ytm (YouTube Music en terminal) ───────────────────────────────────
# libpipewire escribe avisos de "client.conf" sobre la interfaz porque aqui
# el audio va por PulseAudio de WSLg y no hay servidor pipewire. Se silencian
# solo para ytm (PIPEWIRE_DEBUG=0); el audio no cambia.
ytm() { PIPEWIRE_DEBUG=0 command ytm "$@"; }

# ── nvm ───────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
# Cargar nvm.sh entero + nvm_auto costaba ~550 ms en CADA shell (tambien en
# cada split). Ahora: el bin del node por defecto se pone en el PATH a mano
# (node/npm/npx disponibles al instante) y nvm de verdad solo se carga la
# primera vez que se usa el comando `nvm`.
if [[ -r $NVM_DIR/alias/default ]]; then
  _nvm_def="v${$(<$NVM_DIR/alias/default)#v}"
  [[ -d $NVM_DIR/versions/node/$_nvm_def/bin ]] \
    && path=("$NVM_DIR/versions/node/$_nvm_def/bin" $path)
  unset _nvm_def
fi
nvm() {
  unfunction nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  # El completado de nvm esta escrito para bash; en zsh necesita bashcompinit.
  if [ -s "$NVM_DIR/bash_completion" ]; then
    autoload -U +X bashcompinit && bashcompinit
    \. "$NVM_DIR/bash_completion"
  fi
  nvm "$@"
}

# ── zoxide (cd con memoria) ───────────────────────────────────────────
# Debe ir despues de compinit para que registre su completado.
eval "$(zoxide init zsh)"

# ── atuin (historial con busqueda difusa) ─────────────────────────────
# Reemplaza Ctrl+R y la flecha Arriba. Tambien debe ir despues de compinit.
eval "$(atuin init zsh)"

# ── Sugerencias en linea (estilo fish) ────────────────────────────────
# Muestra en gris el resto del comando segun escribes, sacado del
# historial. Se acepta con la flecha Derecha o Fin.
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#4c566a'   # gris nord3, a juego
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ── Powerlevel10k ─────────────────────────────────────────────────────
source ~/.local/share/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
```

</details>

---

## 9. Prompt: Powerlevel10k compacto

**Ruta:** `~/.p10k.zsh`. Se generó con `p10k configure` (plantilla **lean**) y se le añadió al final un bloque que lo sobrescribe. Ese bloque sustituyó al estilo anterior `nordtron` de 3 líneas con corchetes.

Resultado (2 líneas):

```
~/ruta/completa  main ✚1
❯
```

- Ruta completa sin abreviar, en cian `#88c0d0`.
- Rama git en malva `#b48ead`; modificado `#8fbcbb`; sin seguimiento `#88c0d0`.
- Código de error solo si el último comando falló (`#bf616a`).
- `❯` azul `#5e81ac`, rojo si el último comando falló.
- Sin prompt derecho y sin línea en blanco entre prompts.
- `POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=false`: la plantilla lean usa un formateador propio que ignora los colores `VCS_*_FOREGROUND`; se desactiva para que se respeten.

<details>
<summary><b>Bloque añadido al final de <code>~/.p10k.zsh</code></b></summary>

```zsh
# ══════════════════════════════════════════════════════════════════════
#  Prompt compacto, paleta Nord (sustituye al antiguo estilo nordtron de
#  3 lineas con corchetes). Se aplica encima de la plantilla p10k-lean.
#  Paleta:  #88c0d0 ruta · #b48ead git · #5e81ac simbolo · #bf616a error
# ══════════════════════════════════════════════════════════════════════

# Estructura de 2 lineas:   ruta  rama [estado]   /   ❯
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs status newline prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=

# ── Ruta (ruta completa, sin abreviar) ────────────────────────────────
typeset -g POWERLEVEL9K_DIR_FOREGROUND='#88c0d0'
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND='#88c0d0'
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND='#88c0d0'
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=false
typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=9999
typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=false
typeset -g POWERLEVEL9K_DIR_CLASSES=()

# ── Git ───────────────────────────────────────────────────────────────
# La plantilla lean formatea git con my_git_formatter y DISABLE_GITSTATUS_FORMATTING=true.
# Se desactiva para usar el formato integrado de p10k, que si respeta los
# colores VCS_*_FOREGROUND de abajo.
typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=false
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND='#b48ead'
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='#8fbcbb'
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='#88c0d0'
typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND='#4c566a'

# ── Estado de error: solo aparece si el ultimo comando fallo ──────────
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_ERROR=true
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND='#bf616a'

# ── Simbolo del prompt: azul si todo bien, rojo si el ultimo comando fallo ──
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_{VIINS,VICMD,VIVIS,VIOWR}_CONTENT_EXPANSION='❯ '
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='#5e81ac'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='#bf616a'
typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=
typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=
```

</details>

---

## 10. fastfetch y el banner centrado (`cf`)

**Config:** `~/.config/fastfetch/config.jsonc` → symlink a `~/dean.dots/fastfetch/config.jsonc`.

Diseño:

- Logo `ubuntu_small` con padding superior 2 y derecho 3.
- Saludo `Hola, <usuario>!`.
- Caja 1 (bordes en `#5e81ac`): OS, Kernel (`uname -r | cut -d- -f1`), Shell.
- Título `usuario @ host` (malva / azul / cian).
- Caja 2: CPU, GPU (oculta la integrada), Memoria, Disco (`/`), Uptime.
- Fila de colores con círculos.
- Claves en cian `#88c0d0`, separador ` : ` en `#5e81ac`.

### Función `cf` (en `~/.zshrc`)

`clear` + fastfetch **centrado horizontalmente**. fastfetch dibuja la info al lado del logo usando códigos de movimiento de cursor, así que no se puede centrar rellenando línea por línea. `cf`:

1. Mide el ancho del logo (`--structure break`, sin padding) quitando secuencias ANSI.
2. Mide el ancho de la info (`--logo none`).
3. Calcula `pad = (COLUMNS - (logo + 3 + info)) / 2` (el 3 coincide con `logo.padding.right`).
4. Ejecuta `fastfetch --logo-padding-left $pad`.

### Cuándo se pinta

- **Al abrir cualquier shell interactiva** (pestaña nueva, split de tmux): hook `line-init` de zle (`_cf_first`), que se elimina a sí mismo tras la primera vez. No va en `precmd` ni al cargar el archivo porque el instant prompt de p10k redibuja desde arriba al terminar su traspaso y borraría el banner.
- **Al redimensionar** (split, resize, `Alt+Z`): `TRAPWINCH` repinta el banner al nuevo ancho, **solo** si la pantalla todavía contiene únicamente el banner (bandera `_CF_FRESH`, que `preexec` apaga al ejecutar cualquier comando).
- Manualmente: escribir `cf`.

<details>
<summary><b>Archivo completo: <code>~/.config/fastfetch/config.jsonc</code></b></summary>

```jsonc
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": { "source": "ubuntu_small", "padding": { "top": 2, "right": 3 } },
  "display": {
    "separator": " : ",
    "color": { "keys": "38;2;136;192;208", "separator": "38;2;94;129;172" }
  },
  "modules": [
    { "type": "custom", "key": "", "format": "Hola, {$USER}!" },

    { "type": "custom", "format": "┌──────────────────────────────────────┐", "outputColor": "38;2;94;129;172" },
    { "type": "os",      "key": " OS      ", "format": "{name} {version-id}" },
    { "type": "command", "key": " Kernel  ", "text": "uname -r | cut -d- -f1" },
    { "type": "shell",   "key": " Shell   " },
    { "type": "custom", "format": "└──────────────────────────────────────┘", "outputColor": "38;2;94;129;172" },
    {
      "type": "title",
      "key": "",
      "format": "{user-name} @ {host-name}",
      "color": { "user": "38;2;180;142;173", "at": "38;2;94;129;172", "host": "38;2;136;192;208" }
    },
    { "type": "custom", "format": "┌──────────────────────────────────────┐", "outputColor": "38;2;94;129;172" },
    { "type": "cpu",    "key": " CPU     ", "format": "{name}" },
    { "type": "gpu",    "key": " GPU     ", "hideType": "integrated", "format": "{name}" },
    { "type": "memory", "key": " Memoria ", "format": "{used} / {total}" },
    { "type": "disk",   "key": " Disco   ", "folders": "/", "format": "{size-used} / {size-total}" },
    { "type": "uptime", "key": " Uptime  " },
    { "type": "custom", "format": "└──────────────────────────────────────┘", "outputColor": "38;2;94;129;172" },

    { "type": "colors", "key": " ", "symbol": "circle" }
  ]
}
```

</details>

---

## 11. atuin, zoxide, autosuggestions, eza

| Herramienta | Configuración | Uso |
|---|---|---|
| **atuin** | `~/.config/atuin/config.toml`: `style = "full"`, `enter_accept = true`, `[theme] name = "nordtron"` | `Ctrl+R` y flecha arriba: historial con búsqueda difusa |
| **zoxide** | sin archivo; `eval "$(zoxide init zsh)"` | `z <parte-del-nombre>` salta a directorios frecuentes |
| **zsh-autosuggestions** | color `fg=#4c566a`, estrategia `history completion` | `→` o `Fin` acepta la sugerencia |
| **eza** | funciones `ls/ll/la/lt` en `~/.zshrc` | iconos Nerd Font, carpetas primero; `lt` = árbol de 2 niveles |
| **fzf** | colores Nord dentro de `tmux-palette` | menú de la paleta de comandos |

<details>
<summary><b>Archivo completo: <code>~/.config/atuin/themes/nordtron.toml</code></b></summary>

```toml
[theme]
name = "nordtron"

[colors]
Base       = "#d8dee9"
Annotation = "#5e81ac"
Guidance   = "#4c566a"
Important  = "#88c0d0"
AlertInfo  = "#a3be8c"
AlertWarn  = "#ebcb8b"
AlertError = "#bf616a"
```

</details>

---

## 12. countdown propio

Cuenta regresiva con dígitos grandes, escrita en Python. Reemplazó al binario `antonmedv/countdown` (desinstalado) manteniendo el mismo nombre de comando.

| Pieza | Ruta |
|---|---|
| Script | `~/.local/bin/countdown` (Python 3, ~540 líneas, sin dependencias externas) |
| Config | `~/.config/countdown/config` (`clave = valor`; actual: `style = round`) |
| Autocompletado zsh | `~/.local/share/zsh/site-functions/_countdown` |
| Copia antigua | `~/.config/countdown/countdown.bak.py` (versión anterior del script) |

### Uso

```bash
countdown 25m                 # 25 minutos
countdown 90s                 # 90 segundos
countdown 1h30m Estudio       # con etiqueta (va debajo de los dígitos)
countdown 5:00                # mm:ss
countdown 1:30:00             # h:mm:ss
countdown 10                  # número solo = minutos

countdown 25m -c '#88c0d0' -d red --style ansi -n -b
#   -c/--color        color de los dígitos (nombre, 0-255 o #rrggbb)
#   -d/--done-color   color al terminar
#   --style NOMBRE    estilo solo para esta ejecución
#   -n/--no-bar       sin barra de progreso
#   -b/--no-bell      sin campana al terminar
```

Teclas durante la cuenta (la pantalla no muestra ayuda a propósito): `espacio` pausa/reanuda, `r` reinicia, `q` (o `Esc`, `Ctrl+C`) sale.

### Configuración persistente

```bash
countdown conf                          # muestra estilo y colores actuales
countdown conf --style --list           # lista de estilos (● = actual)
countdown conf --style preview          # vista previa de todos
countdown conf --style preview aurora   # vista previa de uno
countdown conf --style round            # elegir y guardar estilo
countdown conf --color '#88c0d0'        # color de los dígitos
countdown conf --done-color '#bf616a'   # color al terminar
```

Claves del archivo de config: `style`, `color`, `done_color`, `bar`, `bell`.

### Estilos (9)

| Estilo | Descripción |
|---|---|
| `led` | Display LED de siete segmentos, trazo fino (`━ ┃`) |
| `double` | Siete segmentos con trazo doble (`═ ║`) |
| `bold` | Siete segmentos con trazo grueso (`▬ █`) |
| `arcade` | Píxeles retro 5×7 con sombra de contorno |
| `banner` | ASCII con `#` al estilo figlet *banner* |
| `pomo` | Bloques 6×5 en caja (timer pomodoro de Vibe30 day06) |
| `ansi` | ANSI Shadow: letras grandes con relieve |
| `round` | Líneas finas con esquinas redondeadas (**actual**) |
| `aurora` | ANSI Shadow con degradado vertical (requiere color `#rrggbb`) |

Estilos probados y descartados: `block`, `mini`, `dots`, `shade`, `pixel`.

Para probar sin tocar la config real: `HOME=$(mktemp -d) countdown 10s`.

El autocompletado (`countdown <Tab>`, `countdown conf --style <Tab>`) obtiene los estilos en vivo con `countdown conf --complete`, así que un estilo nuevo añadido al diccionario `STYLES` aparece solo.

<details>
<summary><b>Archivo completo: <code>~/.local/share/zsh/site-functions/_countdown</code></b></summary>

```zsh
#compdef countdown

_countdown_colors() {
  local -a c
  c=(black red green yellow blue magenta cyan white gray)
  _describe -t colors 'color (o 0-255, #rrggbb)' c
}

_countdown_styles() {
  local -a styles
  styles=("${(@f)$(command countdown conf --complete 2>/dev/null)}")
  _describe -t styles 'estilo' styles
}

_countdown_conf() {
  local prev=$words[CURRENT-1]
  case $CURRENT in
    3)
      local -a flags
      flags=(
        '--style:elegir o listar estilos'
                '--color:color de los dígitos'
        '--done-color:color al terminar'
      )
      _describe -t flags 'conf' flags
      ;;
    *)
      case $prev in
        --style|-style)
          compadd -X 'opción' -- --list preview
          _countdown_styles
          ;;
        preview) _countdown_styles ;;
        --preview|-p) _countdown_styles ;;
        --color|--done-color|-c|-d) _countdown_colors ;;
      esac
      ;;
  esac
}

_countdown() {
  local curcontext="$curcontext" state line ret=1
  typeset -A opt_args

  if [[ $words[2] == conf ]]; then
    _countdown_conf
    return
  fi

  _arguments -C \
    '(-c --color)'{-c,--color}'[color de los dígitos]:color:_countdown_colors' \
    '(-d --done-color)'{-d,--done-color}'[color al terminar]:color:_countdown_colors' \
    '--style[diseño de los dígitos]:estilo:_countdown_styles' \
    '(-n --no-bar)'{-n,--no-bar}'[sin barra de progreso]' \
    '(-b --no-bell)'{-b,--no-bell}'[sin campana al terminar]' \
    '(-h --help)'{-h,--help}'[ayuda]' \
    '1:tiempo:->first' \
    '*:etiqueta:' && ret=0

  if [[ $state == first ]]; then
    local -a t
    t=('conf:cambiar estilo y colores' 25m 10m 5m 1m 90s 1h 1h30m 5:00)
    _describe -t times 'tiempo' t && ret=0
  fi
  return ret
}

_countdown "$@"
```

</details>

El script completo (`~/.local/bin/countdown`) está en la sección [Anexo A](#anexo-a-localbincountdown).

---

## 13. Claude Code personalizado

Claude Code 2.1.325, instalación nativa: `~/.local/bin/claude` → `~/.local/share/claude/versions/2.1.325`.

### 13.1 `~/.claude/settings.json`

| Clave | Valor | Efecto |
|---|---|---|
| `model` | `opus` | Modelo por defecto |
| `statusLine` | `python3 ~/.claude/statusline.py`, `padding 0`, `refreshInterval 1` | Status line propia; se re-ejecuta cada segundo para reacomodarse tras `Alt+Z` o un split |
| `tui` | `fullscreen` | Interfaz a pantalla completa |
| `theme` | `dark-ansi` | Usa los colores ANSI del terminal (sigue al tema Nord de WezTerm) |
| `skipDangerousModePermissionPrompt` | `true` | No pregunta al entrar en modo bypass |
| `enabledPlugins` | `lua-lsp@claude-plugins-official` | LSP de Lua (útil para `wezterm.lua` y la config de nvim) |

`~/.claude/settings.local.json` fija `"outputStyle": "Nino"`.

<details>
<summary><b>Archivo completo: <code>~/.claude/settings.json</code></b></summary>

```json
{
  "model": "opus",
  "statusLine": {
    "type": "command",
    "command": "python3 ~/.claude/statusline.py",
    "padding": 0,
    "refreshInterval": 1
  },
  "enabledPlugins": {
    "lua-lsp@claude-plugins-official": true
  },
  "modelSettings": {
    "claude-sonnet-5-5": {
      "autoCompactWindow": 400000
    }
  },
  "tui": "fullscreen",
  "skipDangerousModePermissionPrompt": true,
  "theme": "dark-ansi"
}
```

</details>

### 13.2 Status line (`~/.claude/statusline.py`)

Script Python (no hay `jq` instalado) que recibe el JSON de la sesión por stdin y pinta, en paleta Nord:

```
antony@PC → ~/proyecto  git(main +1 !2 ?3)          Opus 5.5 | ctx ━━━─────── 31%/200k | 5h ━━────── 22%  7d ━─────── 9%
```

- **Izquierda:** `usuario@host → carpeta` (acortada a `…/a/b` si es larga) y estado git: `+staged` verde, `!modificados` amarillo, `?nuevos` rojo.
- **Derecha:** modelo, uso de contexto con barra de 10 y tamaño de ventana, límites de uso 5 h y 7 d con barras de 8. Las barras son verdes < 50 %, amarillas < 80 %, rojas a partir de 80 %.
- Si no cabe en una línea, el bloque derecho baja a una segunda línea alineada a la derecha.
- El ancho se lee de `/dev/tty` (stdin/stdout no son tty) y se restan 6 columnas de margen que reserva Claude Code.
- `AIRE = 1` al final: líneas de hueco debajo usando `U+2800` (braille en blanco), porque Claude Code recorta líneas vacías, de espacios o NBSP.
- Guarda el último JSON recibido en `~/.cache/claude-statusline-last.json` para inspeccionar campos.

Campos confirmados del JSON: `model.display_name`, `workspace.current_dir`, `context_window.used_percentage`, `context_window.context_window_size`, `rate_limits.five_hour.used_percentage`, `rate_limits.seven_day.used_percentage`.

Limitación: el indicador "bypass permissions on (shift+tab to cycle)" lo dibuja Claude Code, no viene en el JSON y no se puede mover ni ocultar desde `statusLine` (solo admite `command`, `padding`, `refreshInterval` y `hideVimModeIndicator`).

<details>
<summary><b>Archivo completo: <code>~/.claude/statusline.py</code></b></summary>

```python
#!/usr/bin/env python3
"""Status line de Claude Code. Recibe el JSON de la sesion por stdin y pinta
una linea: a la izquierda usuario@pc -> carpeta + git, a la derecha modelo +
contexto + limites de uso (baja a una 2da linea si la terminal es angosta)."""
import json
import fcntl
import os
import re
import socket
import struct
import subprocess
import sys
import termios

# Paleta Nord (a juego con tmux / fastfetch)
def c(r, g, b, s):
    return f"\x1b[38;2;{r};{g};{b}m{s}\x1b[0m"

CYAN = lambda s: c(136, 192, 208, s)
BLUE = lambda s: c(94, 129, 172, s)
PURPLE = lambda s: c(180, 142, 173, s)
GREEN = lambda s: c(163, 190, 140, s)
YELLOW = lambda s: c(235, 203, 139, s)
RED = lambda s: c(191, 97, 106, s)
DIM = lambda s: c(76, 86, 106, s)
FG = lambda s: c(216, 222, 233, s)

try:
    data = json.load(sys.stdin)
except Exception:
    data = {}

# Copia del ultimo JSON recibido, para ver que campos hay disponibles.
try:
    cache = os.path.expanduser("~/.cache/claude-statusline-last.json")
    os.makedirs(os.path.dirname(cache), exist_ok=True)
    with open(cache, "w") as f:
        json.dump(data, f, indent=2)
except Exception:
    pass


def get(*path, default=None):
    cur = data
    for p in path:
        if not isinstance(cur, dict) or p not in cur:
            return default
        cur = cur[p]
    return cur if cur is not None else default


def bar(pct, width=20):
    pct = max(0.0, min(100.0, float(pct)))
    filled = round(width * pct / 100)
    color = GREEN if pct < 50 else YELLOW if pct < 80 else RED
    return color("━" * filled) + DIM("─" * (width - filled))


def human(n):
    n = int(n)
    if n >= 1_000_000 and n % 1_000_000 == 0:
        return f"{n // 1_000_000}M"
    if n >= 1000:
        return f"{n // 1000}k"
    return str(n)


# ── Linea 1: usuario -> carpeta  git(rama +staged !mod ?nuevos) ─────────
cwd = get("workspace", "current_dir") or get("cwd") or os.getcwd()
home = os.path.expanduser("~")
short = cwd.replace(home, "~", 1) if cwd.startswith(home) else cwd
parts = short.split("/")
if len(parts) > 3:
    short = "…/" + "/".join(parts[-2:])

line1 = (
    PURPLE(os.environ.get("USER", "user"))
    + BLUE("@")
    + CYAN(socket.gethostname())
    + BLUE(" → ")
    + FG(short)
)

try:
    branch = subprocess.run(
        ["git", "-C", cwd, "branch", "--show-current"],
        capture_output=True, text=True, timeout=1,
    )
    if branch.returncode == 0:
        name = branch.stdout.strip() or "HEAD"
        st = subprocess.run(
            ["git", "-C", cwd, "status", "--porcelain"],
            capture_output=True, text=True, timeout=1,
        ).stdout.splitlines()
        staged = sum(1 for l in st if l[:1] not in (" ", "?"))
        mod = sum(1 for l in st if l[1:2] not in (" ", "?"))
        new = sum(1 for l in st if l.startswith("??"))
        extra = ""
        if staged:
            extra += " " + GREEN(f"+{staged}")
        if mod:
            extra += " " + YELLOW(f"!{mod}")
        if new:
            extra += " " + RED(f"?{new}")
        line1 += "  " + BLUE("git(") + CYAN(name) + extra + BLUE(")")
except Exception:
    pass

# ── Bloque derecho: modelo | ctx barra pct/tamano | limites 5h 7d ───────
model = get("model", "display_name", default="Claude")
right = CYAN(model)
ctx_pct = get("context_window", "used_percentage")
ctx_size = get("context_window", "context_window_size")
if ctx_pct is not None:
    right += DIM(" | ") + FG("ctx ") + bar(ctx_pct, 10) + " " + FG(f"{ctx_pct:.0f}%")
    if ctx_size:
        right += DIM(f"/{human(ctx_size)}")
segs = []
for key, label in (("five_hour", "5h"), ("seven_day", "7d")):
    pct = get("rate_limits", key, "used_percentage")
    if pct is not None:
        segs.append(FG(f"{label} ") + bar(pct, 8) + " " + FG(f"{pct:.0f}%"))
if segs:
    right += DIM(" | ") + "  ".join(segs)


def visible_len(text):
    return len(re.sub(r"\x1b\[[0-9;]*m", "", text))


def term_width():
    """Ancho real de la terminal: stdin/stdout no son tty, se pide a /dev/tty."""
    try:
        fd = os.open("/dev/tty", os.O_RDONLY)
        try:
            rows, cols = struct.unpack("hh", fcntl.ioctl(fd, termios.TIOCGWINSZ, b"\0" * 4))
        finally:
            os.close(fd)
        if cols > 0:
            return cols
    except Exception:
        pass
    try:
        return int(os.environ.get("COLUMNS", ""))
    except ValueError:
        return 120


width = term_width() - 6  # Claude Code reserva margen a los lados; si no, recorta con '…'
gap = width - visible_len(line1) - visible_len(right)
if gap >= 2:
    # Todo cabe en una linea: izquierda pegada a la izquierda, derecha a la derecha.
    print(line1 + " " * gap + right)
else:
    # Terminal angosta: el bloque derecho baja a su propia linea, alineado a la derecha.
    print(line1)
    print(" " * max(0, width - visible_len(right)) + right)

# Aire debajo, para separar la status line del modo de Claude Code (bypass
# permissions...). Se usa U+2800 (braille en blanco): se ve vacio pero no es
# espacio, asi que no lo recorta; una linea vacia, solo espacios o NBSP si se
# descarta. Cambia AIRE a 1 o 3 para mas o menos hueco.
AIRE = 1
for _ in range(AIRE):
    print("\u2800")
```

</details>

### 13.3 Estilo de salida "Nino"

**Ruta:** `~/.claude/output-styles/nino.md` (~49 KB). Activado en `~/.claude/settings.local.json` con `"outputStyle": "Nino"`, o desde `/config` → Output style.

Frontmatter:

```yaml
---
name: Nino
description: Nino Nakano (adulta) como tu compañera de programación. Afilada con el código, directa contigo, impecable en lo técnico.
keep-coding-instructions: false
---
```

Define el personaje (tono, muletillas, niveles de intensidad y de cariño, banco de situaciones) con reglas firmes: lo técnico primero, nunca mentir sobre resultados, y la personalidad nunca aparece en código, commits ni documentación. Comandos dentro del chat: `modo serio` / `vuelve, Nino`, `más Nino` / `menos Nino`, `cariño bajo|medio|alto`.

### 13.4 Mod `/countdown` (dentro de Claude Code)

**Ruta:** `~/.claude/dev-mods/c41f6536-a54f-470a-82fc-35974e1bb5d0/countdown/`

```
countdown/
├── .claude-plugin/plugin.json   # nombre, versión 0.1.0, userConfig
├── hooks/hooks.json             # { "modules": ["./register.tsx"] }
├── hooks/register.tsx           # lógica (TypeScript/JSX)
├── types/index.d.ts
└── tsconfig.json
```

- Registra el comando `/countdown` al iniciar la sesión.
- `/countdown 25m [etiqueta]` (también `90s`, `1h30m`, `5:00`, `1:30:00`, número = minutos) abre un panel lateral "Countdown" con dígitos grandes de 5 filas, barra de progreso y porcentaje.
- `/countdown pause` · `resume` · `stop` (o `reset`) · `open`.
- Mientras corre, el tiempo aparece en la línea de estado de Claude; al terminar muestra un toast y una notificación.
- Opciones (`userConfig`): `color` (`#cdd6f4`), `doneColor` (`#f38ba8`), `scale` (`big`/`small`), `glyph` (`█`).

Es independiente del `countdown` de la terminal (sección 12): misma idea, otro entorno.

**Instalación en otra máquina:** el código está en `claude/mods/countdown/`. La carpeta original vive bajo un identificador propio de la instalación (`~/.claude/dev-mods/<id>/countdown`), por lo que `install.sh` no la copia: no está comprobado que copiarla a mano baste para que Claude Code la cargue. Lo fiable es pedirle a Claude Code que registre el mod como dev mod a partir de esa carpeta.

### 13.5 Memoria global

- `~/.claude/CLAUDE.md`: reglas de memoria persistente (en español) e import de `@~/.claude/memory/MEMORY.md`.
- `~/.claude/memory/`: un archivo `.md` por hecho, con frontmatter (`name`, `description`, `metadata.type`) e índice en `MEMORY.md`. Incluye el entorno, las decisiones de estilo Nord, las trampas técnicas, la config de nvim, el countdown y el estado de la música en terminal.

---

## 14. Neovim (LazyVim) a juego

- Config: `~/.config/nvim` (repo git propio, basado en LazyVim). Neovim 0.11.
- Temas en `lua/plugins/theme.lua`: tokyonight, gruvbox, catppuccin, kanagawa y **Nord** (`gbprod/nord.nvim`), todos con transparencia.
- `lua/config/transparency.lua`: tabla `M.themes` con la clave de transparencia de cada tema; `<leader>ut` alterna la transparencia y se reaplica automáticamente al cambiar de colorscheme. Un tema nuevo debe registrarse ahí.
- `<leader>uC` elige colorscheme; se persiste en `stdpath("data")/lazyvim-theme`.
- LSPs instalados por Mason; su `bin` está en el PATH (`~/.local/share/nvim/mason/bin`).
- `win32yank.exe` (incluido en Neovim de Windows) da el portapapeles compartido.
- Se probó una configuración de render de Markdown (render-markdown, glow, preview con CSS) y se **revirtió** por completo.

---

## 15. Música en terminal (ytm-player)

- `ytm-player` 2.2.0 instalado con `pipx` (`~/.local/bin/ytm`), usa `mpv` 0.41 y `yt-dlp`.
- Audio de WSL por WSLg/PulseAudio (`~/.asoundrc` apunta a pulse; paquetes `libasound2t64`, `libasound2-plugins`, `pulseaudio-utils`).
- Wrapper `ytm()` en `~/.zshrc` con `PIPEWIRE_DEBUG=0` para silenciar avisos de libpipewire (no hay servidor pipewire en WSLg).
- Config en `~/.config/ytm-player/` (contiene cookies y sesión de Google: **no versionar ni compartir**).
- Intento previo descartado: `ytermusic` beta-0.1.5 (errores 403 en descargas), desinstalado.

---

## 16. Atajos de teclado: referencia rápida

| Capa | Atajo | Acción |
|---|---|---|
| WezTerm | `Ctrl+Shift+M` | Pestaña WSL + tmux (`conf-term`) |
| WezTerm | `Ctrl+Shift+P` | Paleta (tmux si es WSL, WezTerm si no) |
| WezTerm | `Ctrl+Shift+Alt+P` | Paleta de WezTerm |
| WezTerm | `Ctrl+Shift+E` | Cambiar tema |
| WezTerm | `Ctrl+Shift+O` | Transparente / opaco |
| WezTerm | `Ctrl+Shift+T` / `W` | Nueva / cerrar pestaña |
| tmux | `Alt+P` | Paleta de comandos |
| tmux | `Alt+T` / `Alt+W` | Nueva / cerrar ventana |
| tmux | `Alt+←/→` | Cambiar de ventana |
| tmux | `Alt+\` / `Alt+-` | Split derecha / abajo |
| tmux | `Alt+H/J/K/L` | Moverse entre paneles |
| tmux | `Alt+Z` / `Alt+Q` | Zoom / cerrar panel |
| tmux | `F12` / `Shift+F12` | Flotante / ventana scratch |
| zsh | `Ctrl+R`, `↑` | Historial atuin |
| zsh | `→`, `Fin` | Aceptar sugerencia |
| zsh | `z <dir>` | Saltar con zoxide |
| zsh | `cf` | Repintar banner centrado |
| countdown | `espacio` / `r` / `q` | Pausa / reinicio / salir |
| nvim | `<leader>uC` / `<leader>ut` | Tema / transparencia |
| Claude Code | `/countdown 25m` | Countdown en panel |

---

## 17. Problemas conocidos y trampas técnicas

**tmux**
- `display-popup` no expande formatos `#{...}` en su comando; `run-shell` sí (por eso `tmux-palette --abrir`).
- `set -gu 'status-format[0]'` deja la opción vacía, no restaura el valor por defecto. Hay que copiar el original antes de sobrescribirlo.
- `resize-pane -Z` no hace nada con un único panel.
- tmux no enruta eventos de ratón a un popup: por eso existe la ventana `scratch` además del F12.

**WezTerm / wsl.exe**
- `wsl.exe -d Ubuntu -- tmux ... '#S'` pasa por un shell y `#S` se toma como comentario: usar `--exec` para argumentos con `#` o nombres escritos por el usuario.
- WezTerm 20240203 en Windows: `use_resize_increments` no funciona; el icono de la barra nativa no se puede ocultar; la paleta de comandos solo acepta `command_palette_bg_color`, `_fg_color`, `_font_size`, `_rows` (sin centrar ni blur); `window_content_alignment` solo existe en nightly.
- **Hueco bajo la barra de tmux:** son los píxeles sobrantes porque la altura de la ventana no es múltiplo de la fila (23 px con JetBrainsMono 11 y `line_height 1.15`). Se corrigió una vez con `SetWindowPos` (+1 px de alto); vuelve a aparecer al redimensionar a mano o anclar con Win+flechas. Se decidió no instalar nightly.
- Un `Alt+P` enviado con `SendKey` llega a tmux como Meta gracias a `send_composed_key_when_left_alt_is_pressed = false`.

**zsh / p10k / fastfetch**
- El banner debe pintarse en `line-init`, no en `precmd`: el instant prompt de p10k lo borraría.
- fastfetch no se puede centrar línea a línea (usa movimiento de cursor); se mide y se desplaza con `--logo-padding-left`.
- No nombrar helpers de shell con prefijo `_` (el Bash tool de Claude Code los descarta).
- En `zsh`, `echo =====` falla (`=cmd` es expansión de ruta de comando): usar comillas.

**Claude Code**
- Las líneas vacías o de espacios en la status line se recortan: usar `U+2800`.
- El indicador del modo de permisos no se puede mover ni ocultar.

---

## 18. Pendientes

- Logo con imagen en fastfetch (estilo kitty): falta la imagen; `allow-passthrough` está desactivado en tmux, probar primero fuera de tmux.
- Opcional: fijar la posición inicial de la ventana de WezTerm (hoy solo se fija el tamaño).
- `~/dean.dots` está desincronizado con la config real (`zshrc`, `tmux.conf`, README describen una versión anterior: ZDOTDIR, Catppuccin, sesión `main`). Decidir si se actualiza el repo con estos archivos o se archiva.

---

## 19. Mapa de archivos

| Ruta | Qué es |
|---|---|
| `C:\Users\Antony\.config\wezterm\wezterm.lua` | Config de WezTerm |
| `%LOCALAPPDATA%\wezterm-theme` | Tema activo (`nord`) |
| `%LOCALAPPDATA%\wezterm-opacity` | Opacidad activa (`0.85`) |
| `~/.tmux.conf` | Config de tmux |
| `~/.local/bin/tmux-palette` | Paleta de comandos (bash + fzf) |
| `~/.zshrc` | Config de zsh |
| `~/.p10k.zsh` | Powerlevel10k (lean + bloque compacto Nord) |
| `~/.local/share/powerlevel10k/` | Powerlevel10k (git) |
| `~/.config/fastfetch/config.jsonc` → `~/dean.dots/fastfetch/config.jsonc` | Banner |
| `~/.config/atuin/config.toml`, `themes/nordtron.toml` | atuin |
| `~/.local/bin/countdown` | countdown (Python) |
| `~/.config/countdown/config` | Config del countdown |
| `~/.local/share/zsh/site-functions/_countdown` | Autocompletado del countdown |
| `~/.claude/settings.json`, `settings.local.json` | Ajustes de Claude Code |
| `~/.claude/statusline.py` | Status line de Claude Code |
| `~/.claude/output-styles/nino.md` | Estilo de salida Nino |
| `~/.claude/dev-mods/.../countdown/` | Mod `/countdown` |
| `~/.claude/CLAUDE.md`, `~/.claude/memory/` | Memoria global |
| `~/.config/nvim/` | Neovim (LazyVim) |
| `~/.config/ytm-player/` | ytm-player (contiene credenciales) |
| `~/dean.dots/` | Repo de dotfiles (desactualizado salvo fastfetch) |

---

## Anexo A: `~/.local/bin/countdown`

<details>
<summary><b>Archivo completo</b></summary>

```python
#!/usr/bin/env python3
"""countdown: cuenta regresiva con dígitos grandes para la terminal.

uso:
  countdown TIEMPO [ETIQUETA...] [opciones]
  countdown conf [--style [--list | preview [NOMBRE] | NOMBRE]]
                 [--color COLOR] [--done-color COLOR]

TIEMPO: 25m | 90s | 1h30m | 5:00 | 1:30:00 | 10 (minutos)

opciones:
  -c, --color COLOR        color de los dígitos (nombre, 0-255 o #rrggbb)
  -d, --done-color COLOR   color al terminar
  --style NOMBRE           diseño de los dígitos (ver: countdown conf --style --list)
  -n, --no-bar             sin barra de progreso
  -b, --no-bell            sin campana al terminar

config en ~/.config/countdown/config (clave = valor):
  style, color, done_color, bar, bell
"""
import colorsys, difflib, os, re, select, shutil, sys, termios, time, tty

CONF_PATH = os.path.expanduser("~/.config/countdown/config")

# ---------------------------------------------------------------- fuentes
SEG = {"0": "abcdef", "1": "bc", "2": "abdeg", "3": "abcdg", "4": "bcfg",
       "5": "acdfg", "6": "acdefg", "7": "abc", "8": "abcdefg", "9": "abcdfg"}
DIM, UNDIM = "\x1b[2m", "\x1b[22m"




def segments(text, h, v):
    """Display de siete segmentos de 7 líneas."""
    rows = [""] * 7
    for ch in text:
        if ch == ":":
            cells = ["   ", "   ", " ● ", "   ", " ● ", "   ", "   "]
        else:
            sg = SEG[ch]

            def hb(k): return " " + (h * 5 if k in sg else "     ") + " "
            def sd(l, r): return (v if l in sg else " ") + "     " + (v if r in sg else " ")

            cells = [hb("a"), sd("f", "b"), sd("f", "b"), hb("g"),
                     sd("e", "c"), sd("e", "c"), hb("d")]
        for r in range(7):
            rows[r] += cells[r] + " "
    return rows


def compose(text, font, gap=1):
    """Une los glifos de `font` (lista de filas) en una sola línea de filas."""
    height = len(font["0"])
    rows = [""] * height
    for ch in text:
        g = font[ch]
        w = max(len(x) for x in g)
        for r in range(height):
            rows[r] += g[r].ljust(w) + " " * gap
    return [r.rstrip() if False else r for r in rows]


# 6x5, dígitos de bloques del timer pomodoro (ascii/digits.go de Vibe30-day06)
POMO = {
    "0": [" ████ ", "██  ██", "██  ██", "██  ██", " ████ "],
    "1": ["  ██  ", " ███  ", "  ██  ", "  ██  ", " ████ "],
    "2": [" ████ ", "██  ██", "   ██ ", "  ██  ", "██████"],
    "3": [" ████ ", "██  ██", "   ██ ", "██  ██", " ████ "],
    "4": ["██  ██", "██  ██", "██████", "    ██", "    ██"],
    "5": ["██████", "██    ", "█████ ", "    ██", "█████ "],
    "6": [" ████ ", "██    ", "█████ ", "██  ██", " ████ "],
    "7": ["██████", "    ██", "   ██ ", "  ██  ", "  ██  "],
    "8": [" ████ ", "██  ██", " ████ ", "██  ██", " ████ "],
    "9": [" ████ ", "██  ██", " █████", "    ██", " ████ "],
    ":": ["  ", "██", "  ", "██", "  "],
}

# 7x7 con '#', al estilo figlet "banner"
BANNER = {
    "0": [" ##### ", "##   ##", "##  ###", "## # ##", "###  ##", "##   ##", " ##### "],
    "1": ["  ##   ", " ###   ", "  ##   ", "  ##   ", "  ##   ", "  ##   ", " ######"],
    "2": [" ##### ", "##   ##", "    ## ", "  ###  ", " ##    ", "##     ", "#######"],
    "3": [" ##### ", "##   ##", "     ##", "  #### ", "     ##", "##   ##", " ##### "],
    "4": ["   ### ", "  #### ", " ## ## ", "##  ## ", "#######", "    ## ", "    ## "],
    "5": ["#######", "##     ", "###### ", "     ##", "     ##", "##   ##", " ##### "],
    "6": [" ##### ", "##   ##", "##     ", "###### ", "##   ##", "##   ##", " ##### "],
    "7": ["#######", "##   ##", "    ## ", "   ##  ", "  ##   ", "  ##   ", "  ##   "],
    "8": [" ##### ", "##   ##", "##   ##", " ##### ", "##   ##", "##   ##", " ##### "],
    "9": [" ##### ", "##   ##", "##   ##", " ######", "     ##", "##   ##", " ##### "],
    ":": ["  ", "##", "##", "  ", "##", "##", "  "],
}

# 5x7 clásica (cero con diagonal), para el estilo arcade
ARCADE = {
    "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
    "1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
    "3": [".###.", "#...#", "....#", "..##.", "....#", "#...#", ".###."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
    "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
    "6": [".###.", "#...#", "#....", "####.", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
    "9": [".###.", "#...#", "#...#", ".####", "....#", "#...#", ".###."],
    ":": [".", ".", "#", ".", "#", ".", "."],
}

# ANSI Shadow (figlet), 6 líneas
ANSI = {
    "0": [" ██████╗ ", "██╔═████╗", "██║██╔██║", "████╔╝██║", "╚██████╔╝", " ╚═════╝ "],
    "1": [" ██╗", "███║", "╚██║", " ██║", " ██║", " ╚═╝"],
    "2": ["██████╗ ", "╚════██╗", " █████╔╝", "██╔═══╝ ", "███████╗", "╚══════╝"],
    "3": ["██████╗ ", "╚════██╗", " █████╔╝", " ╚═══██╗", "██████╔╝", "╚═════╝ "],
    "4": ["██╗  ██╗", "██║  ██║", "███████║", "╚════██║", "     ██║", "     ╚═╝"],
    "5": ["███████╗", "██╔════╝", "███████╗", "╚════██║", "███████║", "╚══════╝"],
    "6": [" ██████╗ ", "██╔════╝ ", "███████╗ ", "██╔═══██╗", "╚██████╔╝", " ╚═════╝ "],
    "7": ["███████╗", "╚════██║", "    ██╔╝", "   ██╔╝ ", "   ██║  ", "   ╚═╝  "],
    "8": [" █████╗ ", "██╔══██╗", "╚█████╔╝", "██╔══██╗", "╚█████╔╝", " ╚════╝ "],
    "9": [" █████╗ ", "██╔══██╗", "╚██████║", " ╚═══██║", " █████╔╝", " ╚════╝ "],
    ":": ["   ", "██╗", "╚═╝", "██╗", "╚═╝", "   "],
}

# líneas redondeadas, 5 filas
ROUND = {
    "0": ["╭───╮", "│   │", "│   │", "│   │", "╰───╯"],
    "1": ["  ╷  ", " ╶┤  ", "  │  ", "  │  ", " ╶┴╴ "],
    "2": ["╭───╮", "    │", "╭───╯", "│    ", "╰───╴"],
    "3": ["╭───╮", "    │", " ───┤", "    │", "╰───╯"],
    "4": ["╷   ╷", "│   │", "╰───┤", "    │", "    ╵"],
    "5": ["╭────", "│    ", "╰───╮", "    │", "╰───╯"],
    "6": ["╭────", "│    ", "├───╮", "│   │", "╰───╯"],
    "7": ["╶───╮", "    │", "    │", "    │", "    ╵"],
    "8": ["╭───╮", "│   │", "├───┤", "│   │", "╰───╯"],
    "9": ["╭───╮", "│   │", "╰───┤", "    │", "╰───╯"],
    ":": [" ", "●", " ", "●", " "],
}

_EDGE_CHAR = {
    frozenset("u"): "─", frozenset("d"): "─", frozenset("l"): "│", frozenset("r"): "│",
    frozenset("ul"): "┌", frozenset("ur"): "┐", frozenset("dl"): "└", frozenset("dr"): "┘",
    frozenset("lr"): "│", frozenset("ud"): "─",
    frozenset("ulr"): "┬", frozenset("dlr"): "┴", frozenset("udl"): "├", frozenset("udr"): "┤",
    frozenset("udlr"): "┼",
}
_CONCAVE = {"ul": "┘", "ur": "└", "dl": "┐", "dr": "┌"}


def arcade(text):
    """Píxeles de 2 columnas con sombra de contorno desplazada abajo-derecha."""
    filled, col = set(), 0
    for ch in text:
        g = ARCADE[ch]
        for r, row in enumerate(g):
            for c, v in enumerate(row):
                if v == "#":
                    filled.update((r, (col + c) * 2 + k) for k in (0, 1))
        col += len(g[0]) + 1
    height, width, dr, dc = 7, col * 2, 1, 2
    shadow = {(r + dr, c + dc) for r, c in filled}
    rows = []
    for r in range(height + dr):
        line = ""
        for c in range(width + dc):
            if (r, c) in filled:
                line += "█"
            elif (r, c) in shadow:
                edges = frozenset(k for k, (rr, cc) in
                                  (("u", (r - 1, c)), ("d", (r + 1, c)),
                                   ("l", (r, c - 1)), ("r", (r, c + 1)))
                                  if (rr, cc) not in shadow)
                if edges:
                    ch = _EDGE_CHAR[edges]
                else:
                    diag = [k for k, (rr, cc) in
                            (("ul", (r - 1, c - 1)), ("ur", (r - 1, c + 1)),
                             ("dl", (r + 1, c - 1)), ("dr", (r + 1, c + 1)))
                            if (rr, cc) not in shadow]
                    ch = _CONCAVE[diag[0]] if len(diag) == 1 else ("┼" if diag else " ")
                line += (DIM + ch + UNDIM) if ch != " " else " "
            else:
                line += " "
        rows.append(line)
    return rows


def boxed(lines, pad_x=2, pad_y=1):
    w = max(len(re.sub(r"\x1b\[[0-9;]*m", "", l)) for l in lines)
    top = "┌" + "─" * (w + 2 * pad_x) + "┐"
    bot = "└" + "─" * (w + 2 * pad_x) + "┘"
    blank = "│" + " " * (w + 2 * pad_x) + "│"
    body = []
    for l in lines:
        plain = len(re.sub(r"\x1b\[[0-9;]*m", "", l))
        body.append("│" + " " * pad_x + l + " " * (w - plain + pad_x) + "│")
    return [top] + [blank] * pad_y + body + [blank] * pad_y + [bot]


def gradient(lines, rgb):
    """Degradado vertical desde `rgb` hacia el mismo tono girado 70° (solo con #rrggbb)."""
    if not rgb:
        return lines
    h, sat, val = colorsys.rgb_to_hsv(*(x / 255 for x in rgb))
    r2, g2, b2 = colorsys.hsv_to_rgb((h + 70 / 360) % 1, max(0.55, min(1, sat + 0.1)), val)
    end = (r2 * 255, g2 * 255, b2 * 255)
    n = max(1, len(lines) - 1)
    out = []
    for i, line in enumerate(lines):
        t = i / n
        c = [round(rgb[k] + (end[k] - rgb[k]) * t) for k in range(3)]
        out.append(f"\x1b[38;2;{c[0]};{c[1]};{c[2]}m{line}")
    return out


# ---------------------------------------------------------------- estilos
# nombre -> (descripción, función(text, opts) -> líneas)
STYLES = {
    "led":    ("Display LED de siete segmentos, trazo fino",
               lambda t, o: segments(t, "━", "┃")),
    "double": ("Siete segmentos con trazo doble",
               lambda t, o: segments(t, "═", "║")),
    "bold":   ("Siete segmentos con trazo grueso",
               lambda t, o: segments(t, "▬", "█")),
    "arcade": ("Píxeles retro con sombra de contorno",
               lambda t, o: arcade(t)),
    "banner": ("ASCII con # al estilo figlet banner",
               lambda t, o: compose(t, BANNER)),
    "pomo":   ("Bloques en caja, como el timer pomodoro de Vibe30",
               lambda t, o: boxed(compose(t, POMO))),
    "ansi":   ("ANSI Shadow: letras grandes con relieve",
               lambda t, o: compose(t, ANSI, gap=0)),
    "round":  ("Líneas finas con esquinas redondeadas",
               lambda t, o: compose(t, ROUND)),
    "aurora": ("ANSI Shadow con degradado de color vertical",
               lambda t, o: gradient(compose(t, ANSI, gap=0), o.get("rgb"))),
}


def render(style, text, opts):
    return STYLES[style][1](text, opts)


# ---------------------------------------------------------------- utilidades
NAMES = {"black": 0, "red": 1, "green": 2, "yellow": 3, "blue": 4,
         "magenta": 5, "cyan": 6, "white": 7, "gray": 8, "grey": 8}


def die(msg):
    sys.exit(f"countdown: {msg}")


def fg(spec):
    spec = str(spec).strip().lower()
    if spec in NAMES:
        return f"\x1b[38;5;{NAMES[spec]}m"
    if re.fullmatch(r"#[0-9a-f]{6}", spec):
        r, g, b = (int(spec[i:i + 2], 16) for i in (1, 3, 5))
        return f"\x1b[38;2;{r};{g};{b}m"
    if spec.isdigit() and int(spec) < 256:
        return f"\x1b[38;5;{spec}m"
    die(f"color desconocido '{spec}'")


def to_rgb(spec):
    spec = str(spec).strip().lower()
    if re.fullmatch(r"#[0-9a-f]{6}", spec):
        return tuple(int(spec[i:i + 2], 16) for i in (1, 3, 5))
    return None


def parse_time(s):
    s = s.strip().lower()
    if re.fullmatch(r"\d+(:\d+){1,2}", s):
        p = [int(x) for x in s.split(":")]
        return (p[0] * 3600 + p[1] * 60 + p[2]) if len(p) == 3 else p[0] * 60 + p[1]
    m = re.fullmatch(r"(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?", s)
    if m and s:
        h, mi, se = (int(x or 0) for x in m.groups())
        return h * 3600 + mi * 60 + se
    if s.isdigit():
        return int(s) * 60
    return 0


def fmt(sec):
    sec = max(0, int(-(-sec // 1)))
    h, m, s = sec // 3600, sec % 3600 // 60, sec % 60
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m:02d}:{s:02d}"


def truthy(v):
    return str(v).lower() in ("1", "true", "yes", "on")


def load_config():
    cfg = {}
    try:
        for line in open(CONF_PATH):
            line = line.split("#", 1)[0].strip()
            if "=" in line:
                k, v = line.split("=", 1)
                cfg[k.strip()] = v.strip()
    except OSError:
        pass
    return cfg


def save_config(key, value):
    os.makedirs(os.path.dirname(CONF_PATH), exist_ok=True)
    try:
        lines = open(CONF_PATH).read().splitlines()
    except OSError:
        lines = []
    for n, line in enumerate(lines):
        if line.split("#", 1)[0].split("=", 1)[0].strip() == key and "=" in line:
            lines[n] = f"{key} = {value}"
            break
    else:
        lines.append(f"{key} = {value}")
    open(CONF_PATH, "w").write("\n".join(lines) + "\n")


def split_eq(argv):
    """--opt=valor -> --opt valor"""
    out = []
    for a in argv:
        if a.startswith("--") and "=" in a:
            k, v = a.split("=", 1)
            out += [k, v]
        else:
            out.append(a)
    return out


def check_style(name):
    if name in STYLES:
        return name
    close = difflib.get_close_matches(name, STYLES, n=1)
    hint = f" ¿Quisiste decir '{close[0]}'?" if close else ""
    die(f"el estilo '{name}' no existe.{hint} Lista: countdown conf --style --list")


def options_from(cfg, color=None):
    return {"rgb": to_rgb(color or cfg.get("color", "#cdd6f4"))}


def print_preview(name, cfg, text="12:34"):
    color = fg(cfg.get("color", "#cdd6f4"))
    print(f"\x1b[1m{name}\x1b[0m  \x1b[2m{STYLES[name][0]}\x1b[0m")
    for line in render(name, text, options_from(cfg)):
        print(f"  {color}{line}\x1b[0m")
    print()


# ---------------------------------------------------------------- conf
def conf_cmd(args):
    args = split_eq(args)
    cfg = load_config()
    current = cfg.get("style", "led")
    if current not in STYLES:
        current = "led"

    if not args:
        print(f"estilo      {current}")
        print(f"color       {cfg.get('color', '#cdd6f4')}")
        print(f"done_color  {cfg.get('done_color', '#f38ba8')}")
        print(f"\nconfig: {CONF_PATH}")
        print("ver estilos: countdown conf --style --list")
        return 0

    # salidas para el autocompletado
    if args[0] == "--complete":
        for n, (d, _) in STYLES.items():
            print(f"{n}:{d}")
        return 0
    if args[0] == "--names":
        print("\n".join(STYLES))
        return 0

    key = args[0]
    rest = args[1:]

    if key in ("--style", "-style"):
        if not rest or rest[0] in ("--list", "-list", "-l", "list"):
            w = max(len(n) for n in STYLES)
            print("Estilos disponibles:\n")
            for n, (d, _) in STYLES.items():
                mark = "●" if n == current else " "
                print(f"  {mark} {n:<{w}}  {d}")
            print("\n● = estilo actual")
            print("elegir:   countdown conf --style NOMBRE")
            print("ver todos: countdown conf --style preview")
            return 0
        if rest[0] in ("preview", "--preview", "-p"):
            names = [check_style(rest[1])] if len(rest) > 1 else list(STYLES)
            for n in names:
                print_preview(n, cfg)
            return 0
        name = check_style(rest[0])
        save_config("style", name)
        print(f"Estilo guardado: {name}\n")
        print_preview(name, cfg)
        return 0

    if key in ("--preview", "-p"):
        names = [check_style(rest[0])] if rest else list(STYLES)
        for n in names:
            print_preview(n, cfg)
        return 0

    if key in ("--color", "-c", "--done-color", "-d"):
        if not rest:
            die(f"falta el valor de {key}")
        fg(rest[0])  # valida
        k = "color" if key in ("--color", "-c") else "done_color"
        save_config(k, rest[0])
        print(f"{k} guardado: {rest[0]}")
        return 0

    die(f"opción desconocida para conf: '{key}' (prueba: countdown conf --style --list)")


# ---------------------------------------------------------------- cuenta regresiva
def run(argv):
    cfg = load_config()
    color = cfg.get("color", "#cdd6f4")
    done_color = cfg.get("done_color", "#f38ba8")
    style = cfg.get("style", "led")
    if style not in STYLES:
        style = "led"
    opts = options_from(cfg)
    bar = truthy(cfg.get("bar", "true"))
    bell = truthy(cfg.get("bell", "true"))
    words, i = [], 0
    argv = split_eq(argv)

    def val():
        nonlocal i
        i += 1
        if i >= len(argv):
            die(f"falta el valor de {argv[i - 1]}")
        return argv[i]

    while i < len(argv):
        a = argv[i]
        if a in ("-h", "--help"):
            print(__doc__.strip()); return 0
        elif a in ("-c", "--color"): color = val()
        elif a in ("-d", "--done-color"): done_color = val()
        elif a == "--style": style = val()
        elif a in ("-n", "--no-bar"): bar = False
        elif a in ("-b", "--no-bell"): bell = False
        elif a.startswith("-") and len(a) > 1 and not a[1].isdigit():
            die(f"opción desconocida '{a}' (ayuda: countdown --help)")
        else: words.append(a)
        i += 1
    if not words:
        print(__doc__.strip()); return 1
    if style not in STYLES:
        check_style(style)
    total = parse_time(words[0])
    if total <= 0:
        die(f"no entiendo el tiempo '{words[0]}' (prueba 25m, 90s, 1h30m, 5:00)")
    label = " ".join(words[1:])
    c_run, c_done = fg(color), fg(done_color)

    out = sys.stdout
    interactive = sys.stdin.isatty()
    old = termios.tcgetattr(0) if interactive else None
    out.write("\x1b[?1049h\x1b[?25l")
    if interactive:
        tty.setcbreak(0)

    end = time.monotonic() + total
    paused_left = None
    done = False
    try:
        while True:
            now = time.monotonic()
            left = paused_left if paused_left is not None else end - now
            if left <= 0 and not done:
                done, left = True, 0
                if bell:
                    out.write("\a")
            cols, rows = shutil.get_terminal_size()
            opts["rgb"] = to_rgb(done_color if done else color)
            lines = render(style, fmt(left), opts)
            body = [(c_done if done else c_run, l) for l in lines]
            if label:
                body += [("", ""), (c_done if done else c_run, "\x1b[1m" + label)]
            if bar:
                w = max(10, min(cols - 6, 38))
                pct = min(1.0, (total - left) / total)
                f = round(pct * w)
                body.append(("", ""))
                body.append((c_done if done else c_run,
                             "━" * f + DIM + "─" * (w - f) + UNDIM + f"  {int(pct * 100)}%"))
            top = max(0, (rows - len(body)) // 2)
            out.write("\x1b[2J")
            for n, (sty, line) in enumerate(body):
                plain = re.sub(r"\x1b\[[0-9;]*m", "", line)
                x = max(0, (cols - len(plain)) // 2)
                out.write(f"\x1b[{top + n + 1};{x + 1}H{sty}{line}\x1b[0m")
            out.flush()

            if interactive:
                ready, _, _ = select.select([0], [], [], 0.2)
                if ready:
                    k = os.read(0, 8).decode(errors="ignore")
                    if k in ("q", "Q", "\x03", "\x1b"):
                        break
                    if k == " " and not done:
                        if paused_left is None:
                            paused_left = end - time.monotonic()
                        else:
                            end = time.monotonic() + paused_left
                            paused_left = None
                    if k in ("r", "R"):
                        end, paused_left, done = time.monotonic() + total, None, False
            else:
                time.sleep(0.2)
                if done:
                    break
    except KeyboardInterrupt:
        pass
    finally:
        if old:
            termios.tcsetattr(0, termios.TCSADRAIN, old)
        out.write("\x1b[?25h\x1b[?1049l")
        out.flush()
    return 0


def main(argv):
    if argv and argv[0] == "conf":
        return conf_cmd(argv[1:])
    return run(argv)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
```

</details>
