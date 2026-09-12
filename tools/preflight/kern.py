# -*- coding: utf-8 -*-
"""Gemeinsame Grundlagen des Preflight-Pakets: Projektstamm, Fehlerliste,
Zeilen-Helfer und Datei-Sammlung. Jede Prüf-Klasse importiert von hier,
damit es genau eine Fehlerliste und genau eine Datei-Sammlung gibt."""

from pathlib import Path
import re

PROJEKT_STAMM = Path(__file__).resolve().parent.parent.parent

KATEGORIE_PRAEFIXE = {
    "Objekt_": "world/logic/kategorie_objekt",
    "Natur_": "world/logic/kategorie_objekt",
    "Gebaeude_": "world/logic/kategorie_objekt",
    "Ressource_": "game/logic/kategorie_ressourcen",
    "Tier_": "world/logic/kategorie_tier",
    "Einheit_": "game/logic/kategorie_einheit",
    "Job_": "game/logic/kategorie_job",
    "Ui_": "ui",
    "Lager_": "economy/logic/storage",
    "Orchestrator_": "world/logic/kategorie_orchestrator",
    "Pop_": "population",
    "Welt_": None,          # Welt_ darf domänenübergreifend liegen
    "Kern_": "core",
}

KATEGORIEN_TRENNUNG = ("## Kategorie daten", "## Kategorie logik")

ERLAUBTE_ZUFALLS_KLASSEN = ("Kern_Zufall",)

ZUFALLS_MUSTER = re.compile(
    r"\b(randi|randf|randi_range|randf_range|randfn|randomize)\s*\(")

ZEIT_SEED_MUSTER = re.compile(
    r"Time\.get_unix_time_from_system|Time\.get_ticks_msec|OS\.get_unix_time|OS\.get_ticks_msec")

ZWEITER_RNG_MUSTER = re.compile(
    r"\bRandomNumberGenerator\b|\.seed\s*=|randomize\s*\(")

ARRAY_BASISTYPEN = {
    "String", "int", "float", "bool", "Vector2", "Vector2i", "Vector3",
    "Dictionary", "Node", "Node2D", "Texture2D", "Color", "StringName",
    "RefCounted", "Resource", "AnimatedSprite2D", "Sprite2D", "Control",
    "PackedScene", "Label", "Button", "TextureRect",
}

GODOT_FEHLER_MUSTER = ("ERROR", "WARNING", "Parse Error", "SCRIPT ERROR")

# Relativer Headless Referenzpfad (extern, nicht im Repo). Wird nur als letzter
# Fallback verwendet. Bevorzugt werden GODOT_BIN, --godot-befehl, tools/godot/*.
GODOT_EXTERN_FALLBACK = Path("C:/Users/Vannon/Desktop/godu/godot_console.exe")
GODOT_LOKAL_KANDIDATEN = [
    Path("tools/godot/godot_console.exe"),
    Path("tools/godot/godot.exe"),
]

FEHLER = []


def fehler(code, datei, zeile, text):
    eintrag = (code, str(datei), zeile, text)
    if eintrag not in FEHLER:
        FEHLER.append(eintrag)


def zeile_von(code_index, suchtext):
    position = code_index.find(suchtext)
    if position < 0:
        return 1
    return code_index.count("\n", 0, position) + 1


def zeile_bei(code_index, position):
    return code_index.count("\n", 0, position) + 1


def _verzeichnis_ignoriert(pfad) -> bool:
    # Ignorierte Ordner (Addon-/Testumgebung) gehoeren nicht zum Projektvertrag.
    rel = pfad.relative_to(PROJEKT_STAMM)
    teile = rel.parts
    if not teile:
        return False
    return teile[0] in {"addons", "mcp_tools", ".godot", ".freebuff", "tools/godot"} or (
        len(teile) > 1 and "/".join(teile[:2]) == "tools/godot")


def lies_dateien():
    dateien = []
    for pfad in sorted(PROJEKT_STAMM.rglob("*.gd")):
        if _verzeichnis_ignoriert(pfad):
            continue
        try:
            code = pfad.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            fehler("E005", pfad.relative_to(PROJEKT_STAMM), 1,
                   "Datei ist nicht als UTF-8 lesbar")
            continue
        dateien.append((pfad, code))
    return dateien


def klassen_name_lesen(code):
    treffer = re.search(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", code, re.M)
    return treffer.group(1) if treffer else None


def _lade_lauf_log():
    """Lädt das Lauf-Log-Modul granular; Fehlschlag ist E000 fail-closed."""
    import importlib.util as _ilu_l
    import sys as _sys_l
    _log_pfad = PROJEKT_STAMM / "tools" / "lauf_log.py"
    _log_spez = _ilu_l.spec_from_file_location("_lauf_log_lauf", str(_log_pfad))
    _log_mod = _ilu_l.module_from_spec(_log_spez)
    _sys_l.modules[_log_spez.name] = _log_mod
    assert _log_spez.loader is not None
    _log_spez.loader.exec_module(_log_mod)
    return _log_mod.LaufLog()
