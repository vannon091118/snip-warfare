# -*- coding: utf-8 -*-
"""Git Dateien. Eigene Zuständigkeit: Geänderte Dateien sammeln."""

import subprocess
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent.parent

DOMAENEN_PRAEFIXE = ["core/", "game/", "world/", "ui/", "economy/", "population/", "military/", "tools/sonden/", "tools/preflight/", "tools/warteschlange/", "shinon/"]


def lauf(cmd: list[str]) -> tuple[int, str, str]:
    r = subprocess.run(cmd, cwd=str(PROJEKT_STAMM), capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=60)
    return r.returncode, r.stdout or "", r.stderr or ""


def geaenderte_dateien() -> list[str]:
    namen: list[str] = []
    for args in (["git", "diff", "--name-only"], ["git", "diff", "--cached", "--name-only"], ["git", "ls-files", "--others", "--exclude-standard"]):
        code, out, _ = lauf(args)
        if code == 0:
            for z in out.splitlines():
                n = z.strip().replace("\\", "/")
                if n and "__pycache__" not in n and not n.endswith(".pyc"):
                    namen.append(n)
    uniq = sorted(set(namen), key=lambda p: (next((i for i, pref in enumerate(DOMAENEN_PRAEFIXE) if p.startswith(pref)), 99), p))
    return uniq
