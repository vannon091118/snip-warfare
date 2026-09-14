# -*- coding: utf-8 -*-
"""Watcher Orphan. Eigene Zuständigkeit: Fenster-Waisen plattformübergreifend."""

import subprocess


def kill_orphans_fenster() -> int:
    gekillt = 0
    for cmd in (
        ["taskkill", "/F", "/IM", "godot_console.exe"],
        ["taskkill", "/F", "/IM", "godot.exe"],
        ["pkill", "-9", "godot"],
    ):
        try:
            r = subprocess.run(cmd, capture_output=True, timeout=5)
            if r.returncode == 0:
                gekillt += 1
        except Exception:
            pass
    return gekillt
