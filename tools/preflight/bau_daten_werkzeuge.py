# -*- coding: utf-8 -*-
"""Bau-Daten-Werkzeuge. Eigene Zuständigkeit: Bau- und Katalogdaten lesen
und in die Tag-Sicht bringen. Reine Lesehilfe, kein Befund, kein Urteil."""

import json
from pathlib import Path

from .kern import PROJEKT_STAMM, fehler

GEBAEUDE_DATEN = "world/data/gebaeude.json"
KATALOG_DATEN = "world/data/element_katalog.json"


def lade_json(rel: str):
    """Eine JSON-Datei aus dem Projektstamm lesen, sonst None."""
    pfad = PROJEKT_STAMM / rel
    if not pfad.is_file():
        return None
    try:
        return json.loads(pfad.read_text(encoding="utf-8"))
    except Exception:
        return None


def katalog_tags(katalog) -> dict:
    """Tag -> Objekt-IDs. Die einzige Quelle der Objekt-Tags."""
    tags: dict = {}
    for eintrag in katalog or []:
        for tag in eintrag.get("ziel_tags", []) or []:
            tags.setdefault(str(tag), []).append(str(eintrag.get("id", "")))
    return tags


def pruefe_assets(katalog) -> None:
    """Jeder textur_pfad muss als Datei existieren; fehlende Assets sind Befunde."""
    for eintrag in katalog or []:
        pfad = str(eintrag.get("textur_pfad", ""))
        if not pfad.startswith("res://"):
            continue
        relativ = pfad[len("res://"):]
        if not (PROJEKT_STAMM / relativ).is_file():
            fehler("E045", KATALOG_DATEN, 1,
                   "Objekt %s verweist auf fehlendes Asset %s" %
                   (str(eintrag.get("id", "")), pfad))


def lies(rel: str) -> str:
    """Eine GDScript-Datei lesen; fehlt sie, kommt ein leerer Text."""
    pfad = PROJEKT_STAMM / Path(rel)
    if not pfad.is_file():
        return ""
    try:
        return pfad.read_text(encoding="utf-8")
    except OSError:
        return ""
