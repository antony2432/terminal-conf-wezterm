#!/usr/bin/env bash
# Instala la configuración de terminal (WezTerm + tmux + zsh + Claude Code)
# desde este repositorio. Ejecutar dentro de WSL (Ubuntu).
#
#   ./install.sh              copia los archivos a su sitio
#   ./install.sh --link       enlaza (symlink) los archivos de Linux al repo
#                             (WezTerm siempre se copia: Windows no sigue symlinks de WSL)
#   ./install.sh --deps       instala además paquetes apt, Powerlevel10k, atuin y nvm
#   ./install.sh --dry-run    muestra lo que haría sin tocar nada
#   ./install.sh --ytm        instala además la música en terminal (ytm-player,
#                             mpv, audio de WSLg y ~/.asoundrc). Por defecto NO se instala.
#
# Las opciones se pueden combinar: ./install.sh --deps --ytm
# Antes de sobrescribir un archivo existente se guarda una copia en
# ~/.terminal-conf-backup/<fecha>/ con la misma ruta relativa a $HOME.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODO=copiar
DEPS=0
DRY=0
YTM=0
for a in "$@"; do
  case "$a" in
    --link) MODO=enlazar ;;
    --deps) DEPS=1 ;;
    --dry-run) DRY=1 ;;
    --ytm) YTM=1 ;;
    -h|--help) awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 0 ;;
    *) echo "Opción desconocida: $a" >&2; exit 1 ;;
  esac
done

BACKUP="$HOME/.terminal-conf-backup/$(date +%Y%m%d-%H%M%S)"

info() { printf '\033[38;2;136;192;208m==>\033[0m %s\n' "$*"; }
aviso() { printf '\033[38;2;235;203;139m!!\033[0m %s\n' "$*"; }
run() { if (( DRY )); then echo "   [dry-run] $*"; else "$@"; fi; }

# respaldar <destino>: copia el destino existente al directorio de backup.
respaldar() {
  local dest="$1" rel
  [[ -e $dest || -L $dest ]] || return 0
  if [[ $dest == "$HOME"/* ]]; then rel="${dest#"$HOME"/}"; else rel="externo${dest}"; fi
  run mkdir -p "$(dirname "$BACKUP/$rel")"
  run cp -a "$dest" "$BACKUP/$rel"
}

# instalar <origen en el repo> <destino> [forzar_copia]
instalar() {
  local src="$REPO/$1" dest="$2" forzar="${3:-0}"
  if [[ -L $dest && $(readlink -f "$dest") == "$(readlink -f "$src")" ]]; then
    echo "   = $dest (ya enlazado)"
    return
  fi
  # En modo copia, si el contenido ya es idéntico (aunque el destino sea un
  # symlink a otro sitio, p. ej. ~/dean.dots) no se toca.
  if [[ ($MODO == copiar || $forzar == 1) && -f $src && -f $dest ]] && cmp -s "$src" "$dest"; then
    echo "   = $dest (sin cambios)"
    return
  fi
  respaldar "$dest"
  run mkdir -p "$(dirname "$dest")"
  if [[ $MODO == enlazar && $forzar == 0 ]]; then
    run rm -rf "$dest"
    run ln -s "$src" "$dest"
    echo "   → $dest (symlink)"
  else
    run rm -rf "$dest"
    run cp -a "$src" "$dest"
    echo "   → $dest"
  fi
}

# ─── Dependencias (opcional) ────────────────────────────────────────────
if (( DEPS )); then
  info "Paquetes apt"
  run sudo apt update
  run sudo apt install -y zsh tmux git fzf eza zoxide fastfetch zsh-autosuggestions \
    python3 rsync curl

  if ! command -v atuin >/dev/null; then
    info "atuin"
    run bash -c "curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh"
  fi

  if [[ ! -d $HOME/.local/share/powerlevel10k ]]; then
    info "Powerlevel10k"
    run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.local/share/powerlevel10k"
  fi

  if [[ ! -d $HOME/.nvm ]]; then
    info "nvm (después: nvm install --lts && nvm alias default node)"
    run bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | PROFILE=/dev/null bash"
  fi

  if [[ $(getent passwd "$USER" | cut -d: -f7) != */zsh ]]; then
    info "zsh como shell por defecto"
    run chsh -s "$(command -v zsh)"
  fi
fi

# ─── Linux (WSL) ────────────────────────────────────────────────────────
info "zsh"
instalar zsh/zshrc "$HOME/.zshrc"
instalar zsh/p10k.zsh "$HOME/.p10k.zsh"
instalar zsh/completions/_countdown "$HOME/.local/share/zsh/site-functions/_countdown"

info "tmux"
instalar tmux/tmux.conf "$HOME/.tmux.conf"

info "Scripts en ~/.local/bin"
instalar bin/tmux-palette "$HOME/.local/bin/tmux-palette"
instalar bin/countdown "$HOME/.local/bin/countdown"

info "fastfetch, atuin, countdown"
instalar fastfetch/config.jsonc "$HOME/.config/fastfetch/config.jsonc"
instalar atuin/config.toml "$HOME/.config/atuin/config.toml"
instalar atuin/themes/nordtron.toml "$HOME/.config/atuin/themes/nordtron.toml"
instalar countdown/config "$HOME/.config/countdown/config"

if (( YTM )); then
  info "Música en terminal (ytm-player)"
  run sudo apt install -y pipx mpv libmpv2 libasound2t64 libasound2-plugins pulseaudio-utils
  if command -v ytm >/dev/null 2>&1 || [[ -d $HOME/.local/share/pipx/venvs/ytm-player ]]; then
    echo "   = ytm-player (ya instalado)"
  else
    run pipx install ytm-player
  fi
  info "Audio (ALSA → PulseAudio de WSLg)"
  instalar audio/asoundrc "$HOME/.asoundrc"
else
  aviso "Música en terminal (ytm-player) omitida. Para instalarla: ./install.sh --ytm"
fi

info "Claude Code"
instalar claude/settings.json "$HOME/.claude/settings.json"
instalar claude/settings.local.json "$HOME/.claude/settings.local.json"
instalar claude/statusline.py "$HOME/.claude/statusline.py"
instalar claude/CLAUDE.md "$HOME/.claude/CLAUDE.md"
instalar claude/output-styles/nino.md "$HOME/.claude/output-styles/nino.md"
if [[ ! -e $HOME/.claude/memory/MEMORY.md ]]; then
  run mkdir -p "$HOME/.claude/memory"
  (( DRY )) || printf '# Índice de memoria global\n' > "$HOME/.claude/memory/MEMORY.md"
  echo "   → $HOME/.claude/memory/MEMORY.md (índice vacío)"
fi
aviso "El mod /countdown (claude/mods/countdown) no se instala solo: ver README, sección 13.4."

info "Neovim"
if [[ -d $HOME/.config/nvim/.git ]]; then
  aviso "~/.config/nvim ya es un repositorio git; no se toca. La copia del repo está en nvim/."
else
  instalar nvim "$HOME/.config/nvim"
fi

# ─── Windows (WezTerm) ──────────────────────────────────────────────────
info "WezTerm (Windows)"
if command -v cmd.exe >/dev/null 2>&1; then
  WIN_HOME="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"
  WIN_LOCAL="$(wslpath "$(cmd.exe /c 'echo %LOCALAPPDATA%' 2>/dev/null | tr -d '\r')")"
  instalar wezterm/wezterm.lua "$WIN_HOME/.config/wezterm/wezterm.lua" 1
  # El estado (tema/opacidad) solo se crea si no existe, para no pisar lo que se elija con Ctrl+Shift+E/O.
  for f in wezterm-theme wezterm-opacity; do
    if [[ ! -e $WIN_LOCAL/$f ]]; then
      run cp "$REPO/wezterm/$f" "$WIN_LOCAL/$f"
      echo "   → $WIN_LOCAL/$f"
    fi
  done
else
  aviso "No se encontró cmd.exe (¿no es WSL?). Copia wezterm/wezterm.lua a %USERPROFILE%\\.config\\wezterm\\ a mano."
fi

echo
if [[ -d $BACKUP ]]; then
  info "Copias de lo que había antes: $BACKUP"
fi
info "Listo. Abre una terminal nueva (o: exec zsh) y en WezTerm pulsa Ctrl+Shift+M."
