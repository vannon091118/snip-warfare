# -*- coding: utf-8 -*-
"""Szenario Validierer. Eigene Zuständigkeit: Ein Szenario ist gültig oder nicht."""

import json
from pathlib import Path

from tools.sonden.sonden_pfade import PROJEKT_STAMM
from tools.sonden.sonden_vertrag import ERLAUBTE_MODI, ERLAUBTE_SCHRITT_ARTEN


def validiere_szenario(pfad: Path) -> list[str]:
    probs: list[str] = []
    try:
        text = pfad.read_text(encoding="utf-8")
        data = json.loads(text)
    except Exception as e:
        return [f"JSON ungelesen: {e}"]
    for s in data.get("schritte", []):
        if not isinstance(s, dict) or str(s.get("art", "")) not in ERLAUBTE_SCHRITT_ARTEN:
            probs.append(f"schritt art ungueltig: {s}")
    if "id" not in data or not str(data["id"]).strip():
        probs.append("Feld 'id' fehlt oder leer")
    if "seed" not in data:
        probs.append("Feld 'seed' fehlt")
    if "deckt" not in data or not isinstance(data["deckt"], list) or not data["deckt"]:
        probs.append("Feld 'deckt' (Liste Pfade) fehlt oder leer")
    else:
        for eintrag in data["deckt"]:
            if not isinstance(eintrag, str) or not eintrag.strip():
                probs.append(f"deckt-Eintrag leer: {eintrag!r}")
                continue
            roher = eintrag.strip()
            ohne_res = roher[len("res://"):] if roher.startswith("res://") else roher
            candidate = PROJEKT_STAMM / ohne_res
            if not candidate.exists():
                probs.append(f"deckt verweist auf fehlenden Pfad: {eintrag}")
    if "modus" in data and str(data["modus"]) not in ERLAUBTE_MODI:
        probs.append(f"modus muss {ERLAUBTE_MODI} sein, war {data['modus']!r}")
    if "schritte" in data and not isinstance(data["schritte"], list):
        probs.append("schritte muss Liste sein")
    return probs
