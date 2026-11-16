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
