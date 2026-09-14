# -*- coding: utf-8 -*-
"""Werkzeuge der Kategorie engine_bruecken: E050 Register-Vertrag, E051 Queue-Schema."""

import json
import re
from pathlib import Path

from .kern import PROJEKT_STAMM, fehler

REGISTER_DATEI = "core/data/engine_register.json"
ENGINE_ORDNER = ("game/", "world/", "core/", "economy/", "population/", "military/")


def register_vertrag(dateien) -> None:
    """E050: Jede Klasse, die Kern_Engine extendet, steht im Register."""
    register_pfad = PROJEKT_STAMM / REGISTER_DATEI
    register: dict = {}
    if register_pfad.is_file():
        register = (json.loads(register_pfad.read_text(encoding="utf-8")) or {}).get("engines", {})
    for pfad in dateien:
        rel = str(pfad).replace("\\", "/")
        if not rel.startswith(ENGINE_ORDNER) or rel.startswith("tools/"):
            continue
        try:
            text = Path(pfad).read_text(encoding="utf-8")
        except OSError:
            continue
        if not re.search(r"^extends Kern_Engine\b", text, re.M):
            continue
        klasse = re.search(r"^class_name\s+(\w+)", text, re.M)
        name = klasse.group(1) if klasse else rel.rsplit("/", 1)[-1]
        if name not in register:
            fehler("E050", rel, 1, "Engine-Klasse %s fehlt im Register %s; keine Anmeldung ohne Eintrag" % (name, REGISTER_DATEI))


def event_queue_schema(dateien) -> None:
    """E051: Queue-Einträge tragen art und daten, nie ziel_engine."""
    for pfad in dateien:
        try:
            text = Path(pfad).read_text(encoding="utf-8")
        except OSError:
            continue
        rel = str(pfad).replace("\\", "/")
        if "ziel_engine" in text:
            fehler("E051", rel, 1, "Event-Queue-Eintraege tragen art und daten, nie ziel_engine; jede Engine filtert selbst")
