# -*- coding: utf-8 -*-
"""Prüfkategorie locregel (E041): Die 100-LOC-Regel als Architektur-Erzwingung.

Differenzierte Zeilen-Grenzen je Datei-Suffix, nur für GD-Klassen in den
Fach-Ordnern. Ein God-File scheitert künftig am rot fallenden Commit, nicht
an der Disziplin. Ausnahmen (nie geprüft): tools/*, lauf_pruefung_*.gd,
test_*.py, shinon/*.py, *.tscn. Die Nachlass-Liste locregel_nachlass.json
trägt die bestehenden Monster-Dateien mit ihrem Ist-Wert; jeder Zerlegungs-
Slice streicht seinen Eintrag, die Liste muss leer enden."""

import json as _json
import re

from .kern import PROJEKT_STAMM, fehler

GRENZEN_NACH_SUFFIX = (
    ("_basis.gd", 80),
    ("_registry.gd", 100),
    ("_mutation", 60),
    ("_maschine.gd", 120),
    ("_manager.gd", 150),
    ("_status.gd", 120),
    ("_darsteller.gd", 100),
)

GRENZEN_NAME_ERGAENZUNG = {
    "_mutation": "_mutation*.gd",
}

GEPRUEFTE_ORDNER = ("game/", "world/", "core/", "economy/", "population/", "military/")

NACHLASS_PFAD = "tools/preflight/locregel_nachlass.json"


def _grenze_fuer(datei_name: str):
    name = datei_name.lower()
    for suffix, grenze in GRENZEN_NACH_SUFFIX:
        if suffix == "_mutation":
            if "_mutation" in name and name.endswith(".gd"):
                return grenze, GRENZEN_NAME_ERGAENZUNG["_mutation"]
            continue
        if name.endswith(suffix):
            return grenze, suffix
    return None, None


def _nachlass_lesen() -> dict:
    pfad = PROJEKT_STAMM / NACHLASS_PFAD
    if not pfad.is_file():
        return {}
    try:
        daten = _json.loads(pfad.read_text(encoding="utf-8"))
    except Exception:
        return {}
    if isinstance(daten, dict):
        return daten
    return {}


def pruefe_locregel(dateien) -> None:
    """E041: Zeilen-Grenze je Suffix; Nachlass-Dateien tragen ihren Ist-Wert."""
    nachlass = _nachlass_lesen()
    for pfad, code in dateien:
        rel = str(pfad.relative_to(PROJEKT_STAMM)).replace("\\", "/")
        normalisiert = rel.lower()
        # Ausnahmen: Werkzeuge, Lauf-Prüfungen, Tests, Shinon, Szenen.
        if rel.startswith("tools/"):
            continue
        if normalisiert.startswith("lauf_pruefung_"):
            continue
        if pfad.name.lower().startswith("lauf_pruefung_"):
            continue
        if not rel.endswith(".gd"):
            continue
        if not any(normalisiert.startswith(ordner) for ordner in GEPRUEFTE_ORDNER):
            continue
        # Nur Klassen-Dateien prüfen; Szenen-Skripte ohne class_name ruhen auf
        # ihrer Szene und fallen nicht unter die Grenze.
        treffer = re.search(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", code, re.M)
        if treffer is None:
            continue
        zeilen_zahl = code.count("\n") + 1
        grenze, suffix_label = _grenze_fuer(pfad.name)
        if grenze is None:
            continue
        if zeilen_zahl <= grenze:
            continue
        # Nachlass: Bestehende Monster tragen ihren eingetragenen Ist-Wert,
        # bis ihr Zerlegungs-Slice sie streicht.
        if rel in nachlass:
            ist_wert = int(nachlass[rel].get("ist_zeilen", zeilen_zahl))
            if zeilen_zahl <= ist_wert:
                continue
            fehler("E041", rel, 1,
                   "Nachlass-Eintrag ueberschritten: %d Zeilen, vereinbart waren %d; "
                   "der Zerlegungs-Slice muss die Datei striechen oder den Ist-Wert halten" %
                   (zeilen_zahl, ist_wert))
            continue
        fehler("E041", rel, 1,
               "Zeilen-Grenze verletzt: %d Zeilen in einer %s-Datei, erlaubt sind %d; "
               "die Verantwortung gehoert in eigene Maschinen" %
               (zeilen_zahl, suffix_label, grenze))
