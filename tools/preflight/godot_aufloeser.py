# -*- coding: utf-8 -*-
"""Godot Aufloeser. Eigene Zuständigkeit: Ein einziger Weg zu Godot.

Kein pruef_*.py kopiert diese Logik mehr. Der Aufloeser wird aus kern
geräumt und in die eigene Klasse verlegt.
"""

import os
import shutil
from pathlib import Path

from .projekt_stamm import PROJEKT_STAMM

GODOT_FEHLER_MUSTER = ("ERROR", "WARNING", "Parse Error", "SCRIPT ERROR")
GODOT_EXTERN_FALLBACK = Path("C:/Users/Vannon/Desktop/godu/godot_console.exe")
GODOT_LOKAL_KANDIDATEN = [
    Path("tools/godot/godot_console.exe"),
    Path("tools/godot/godot.exe"),
]


def aufloese_godot(befehl_arg: str = "godot") -> str | None:
    umgebung = os.environ.get("GODOT_BIN", "").strip()
    if umgebung != "":
        return umgebung
    if befehl_arg != "godot":
        return befehl_arg
    for kandidat in GODOT_LOKAL_KANDIDATEN:
        voller = PROJEKT_STAMM / kandidat
        if voller.is_file():
            return str(voller)
    if shutil.which("godot") is not None:
        return "godot"
    if GODOT_EXTERN_FALLBACK.is_file():
        return str(GODOT_EXTERN_FALLBACK)
    return None
