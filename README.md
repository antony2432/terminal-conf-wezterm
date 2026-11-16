# terminal-conf-wezterm

Configuración de terminal para **Windows 11 + WSL2 (Ubuntu)**: WezTerm translúcido con blur, tmux, zsh con Powerlevel10k, banner de fastfetch, paleta de comandos propia, countdown propio y Claude Code personalizado, todo en paleta **Nord**.

> 📖 **Documentación completa** (arquitectura, cada archivo explicado, atajos, problemas conocidos): [`docs/CONFIGURACION.md`](docs/CONFIGURACION.md)

---

## Qué incluye

| App / servicio | Para qué | Config en el repo |
|---|---|---|
| **WezTerm** (Windows) | Emulador de terminal: Acrylic, opacidad 0.85, tema Nord, atajos `Ctrl+Shift+*` | `wezterm/` |
| **tmux** | Multiplexor: barra Nord de 2 filas, splits con `Alt`, terminal flotante `F12` | `tmux/tmux.conf` |
| **Paleta de comandos** | Popup con fzf (`Alt+P` / `Ctrl+Shift+P`): sesiones, ventanas, paneles | `bin/tmux-palette` |
| **zsh** | Shell: historial, completado, nvm en modo lazy, banner al abrir | `zsh/zshrc` |
| **Powerlevel10k** | Prompt compacto de 2 líneas (ruta + rama, `❯`) | `zsh/p10k.zsh` |
| **fastfetch** | Banner de sistema centrado (`cf`) | `fastfetch/config.jsonc` |
| **atuin** | Historial con búsqueda difusa (`Ctrl+R`), tema Nord | `atuin/` |
| **zoxide** | `cd` con memoria (`z <dir>`) | — |
| **zsh-autosuggestions** | Sugerencias en gris desde el historial | — |
| **eza** | `ls` / `ll` / `la` / `lt` con iconos | — |
| **countdown** | Cuenta regresiva con dígitos grandes, 9 estilos | `bin/countdown`, `countdown/`, `zsh/completions/_countdown` |
| **Claude Code** | Status line Nord, estilo de salida "Nino", mod `/countdown` | `claude/` |
| **Neovim** (LazyVim) | Editor con tema Nord transparente | `nvim/` |
| **ytm-player** *(opcional)* | YouTube Music en terminal | `audio/asoundrc` |

---

## Dependencias

### Windows

| Requisito | Notas |
|---|---|
| Windows 11 | Necesario para el blur Acrylic |
| [WezTerm](https://wezfurlong.org/wezterm/) 20240203 | Instalador oficial |
| [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) | Instalar en Windows (iconos de eza, prompt y fastfetch) |
| WSL2 con Ubuntu | `wsl --install -d Ubuntu` |
| Neovim para Windows *(opcional)* | Trae `win32yank.exe` (portapapeles compartido) |

### WSL / Ubuntu

| Tipo | Paquetes | Cómo se instala |
|---|---|---|
| apt | `zsh tmux git fzf eza zoxide fastfetch zsh-autosuggestions python3 rsync curl` | `install.sh --deps` |
| Externos | Powerlevel10k (git), atuin, nvm + Node LTS | `install.sh --deps` |
| Claude Code | `claude` (instalador nativo) | Manual: `curl -fsSL https://claude.ai/install.sh \| bash` |
| Neovim | ≥ 0.11 | Manual |
| Opcional: música | `pipx mpv libmpv2 libasound2t64 libasound2-plugins pulseaudio-utils` + `pipx install ytm-player` | `install.sh --ytm` |

Versiones probadas: zsh 5.9 · tmux 3.6 · fastfetch 2.57 · eza 0.23 · zoxide 0.9.8 · atuin 18.8 · fzf 0.67 · Python 3.14 · Node 24 · Neovim 0.11 · Claude Code 2.1.

---

## Instalación

Dentro de WSL:

```bash
git clone git@github.com:antony2432/terminal-conf-wezterm.git ~/terminal-conf-wezterm
cd ~/terminal-conf-wezterm

./install.sh --dry-run        # ver qué haría, sin tocar nada
./install.sh --deps           # instalar dependencias + colocar la configuración
```

Después: cerrar y abrir WezTerm y pulsar **`Ctrl+Shift+M`** (abre WSL + tmux).

### Opciones de `install.sh`

| Opción | Efecto |
|---|---|
| *(ninguna)* | Copia los archivos a su sitio |
| `--deps` | Instala además paquetes apt, Powerlevel10k, atuin y nvm |
| `--ytm` | Instala además la música en terminal (ytm-player, mpv, audio WSLg, `~/.asoundrc`). **Apagado por defecto** |
| `--link` | Usa symlinks al repo en vez de copias (WezTerm siempre se copia) |
| `--dry-run` | Solo muestra lo que haría |

Se pueden combinar: `./install.sh --deps --ytm`.

- Antes de sobrescribir algo, guarda una copia en `~/.terminal-conf-backup/<fecha>/`.
- Lo que ya es idéntico no se toca; se puede ejecutar varias veces.
- `wezterm.lua` se copia a `%USERPROFILE%\.config\wezterm\`. El tema y la opacidad solo se crean si no existen.
- Si `~/.config/nvim` ya es un repositorio git, no se toca.
- El mod `/countdown` de Claude Code se instala a mano: ver [documentación, 13.4](docs/CONFIGURACION.md#134-mod-countdown-dentro-de-claude-code).

---

## Mantener el repo actualizado

```bash
cd ~/terminal-conf-wezterm
./actualizar.sh               # copia la configuración en uso al repo
git diff                      # revisar
git add -A && git commit -m "Describe el cambio" && git push
```

`actualizar.sh` no regenera las copias de archivos incrustadas en `docs/CONFIGURACION.md`; si el cambio es relevante, actualizar también esa sección.

---

## Atajos principales

| Atajo | Acción |
|---|---|
| `Ctrl+Shift+M` | WSL + tmux (sesión `conf-term`) |
| `Ctrl+Shift+P` / `Alt+P` | Paleta de comandos |
| `Ctrl+Shift+E` / `Ctrl+Shift+O` | Cambiar tema / transparencia de WezTerm |
| `Alt+T` / `Alt+W` | Nueva / cerrar ventana de tmux |
| `Alt+\` / `Alt+-` | Dividir panel |
| `Alt+H/J/K/L` · `Alt+Z` · `Alt+Q` | Moverse · maximizar · cerrar panel |
| `F12` | Terminal flotante |

Lista completa: [documentación, sección 16](docs/CONFIGURACION.md#16-atajos-de-teclado-referencia-rápida).

---

## Estructura

```
terminal-conf-wezterm/
├── README.md                 # este archivo
├── docs/CONFIGURACION.md     # documentación detallada
├── install.sh                # repo → sistema
├── actualizar.sh             # sistema → repo
├── wezterm/                  # wezterm.lua, tema y opacidad
├── tmux/                     # tmux.conf
├── bin/                      # tmux-palette, countdown
├── zsh/                      # zshrc, p10k.zsh, completions/
├── fastfetch/                # config.jsonc
├── atuin/                    # config.toml, themes/
├── countdown/                # config
├── audio/                    # asoundrc (opcional)
├── claude/                   # settings, statusline.py, output style, mod /countdown
└── nvim/                     # copia de la config de Neovim (original: antony2432/nvm-config)
```

## Qué no incluye

No contiene secretos: credenciales de Claude Code, memoria de Claude (`~/.claude/memory/`), cookies de ytm-player ni la key de atuin. Sí contiene archivos personales (estilo de salida `claude/output-styles/nino.md`, `claude/CLAUDE.md`, rutas con el nombre de usuario); tenerlo en cuenta al decidir si el repositorio es público.
