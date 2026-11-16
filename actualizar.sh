#!/usr/bin/env bash
# Copia la configuración en uso de esta máquina al repositorio, para hacer
# commit de los cambios. Es la operación inversa de install.sh.
#
#   ./actualizar.sh           actualiza los archivos del repo
#   git diff                  revisar qué cambió antes del commit

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

traer() {
  local src="$1" dest="$REPO/$2"
  if [[ ! -e $src ]]; then
    printf '   ! no existe: %s\n' "$src"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ -d $src ]]; then
    rsync -a --delete --exclude .git "$src/" "$dest/"
  else
    cp "$(readlink -f "$src")" "$dest"
  fi
  printf '   ← %s\n' "$src"
}

traer "$HOME/.zshrc" zsh/zshrc
traer "$HOME/.p10k.zsh" zsh/p10k.zsh
traer "$HOME/.local/share/zsh/site-functions/_countdown" zsh/completions/_countdown
traer "$HOME/.tmux.conf" tmux/tmux.conf
traer "$HOME/.local/bin/tmux-palette" bin/tmux-palette
traer "$HOME/.local/bin/countdown" bin/countdown
traer "$HOME/.config/fastfetch/config.jsonc" fastfetch/config.jsonc
traer "$HOME/.config/atuin/config.toml" atuin/config.toml
traer "$HOME/.config/atuin/themes/nordtron.toml" atuin/themes/nordtron.toml
traer "$HOME/.config/countdown/config" countdown/config
traer "$HOME/.asoundrc" audio/asoundrc
traer "$HOME/.claude/settings.json" claude/settings.json
traer "$HOME/.claude/settings.local.json" claude/settings.local.json
traer "$HOME/.claude/statusline.py" claude/statusline.py
traer "$HOME/.claude/CLAUDE.md" claude/CLAUDE.md
traer "$HOME/.claude/output-styles/nino.md" claude/output-styles/nino.md
traer "$HOME/.config/nvim" nvim

# El mod vive en una carpeta con un identificador propio de la instalación.
mod=$(find "$HOME/.claude/dev-mods" -maxdepth 2 -type d -name countdown 2>/dev/null | head -1)
[[ -n $mod ]] && traer "$mod" claude/mods/countdown

if command -v cmd.exe >/dev/null 2>&1; then
  WIN_HOME="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"
  traer "$WIN_HOME/.config/wezterm/wezterm.lua" wezterm/wezterm.lua
fi

echo
echo "Hecho. Revisa con: git -C \"$REPO\" status && git -C \"$REPO\" diff"
