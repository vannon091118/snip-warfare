# -*- coding: utf-8 -*-
"""Sonden Reihen Referenz. Eigene Zuständigkeit: Das Ablegen und Halten
der Reihen-Prüfreferenzen — Hash über die Bewegungs-Kurve, schreiben der
Referenz-Datei, vergleichen eines neuen Laufs gegen den alten Stand."""

import json
import hashlib
from pathlib import Path

from tools.sonden.sonden_pfade_vis import REIHEN_REFERENZ
BEWEGUNG_SCHWELLE = 0.001


def referenz_hash(analyse: dict) -> str:
    """Stabiler Hash der Bewegungskurve — die Kurve ist die Referenz, nicht
    das einzelne Bild. Rauschen in Pixeln stört nicht, Rhythmus schon."""
    kanonisch = json.dumps(analyse["bewegungskurve"], sort_keys=True)
    return hashlib.sha1(kanonisch.encode()).hexdigest()[:16]


def referenz_schreiben(agent: str, sid: str, analyse: dict) -> Path:
    alle: dict = {}
    if REIHEN_REFERENZ.is_file():
        try:
            alle = json.loads(REIHEN_REFERENZ.read_text(encoding="utf-8"))
        except Exception:
            alle = {}
    schlüssel = f"{agent}/{sid}"
    analyse["referenz_hash"] = referenz_hash(analyse)
    alle[schlüssel] = analyse
    REIHEN_REFERENZ.parent.mkdir(parents=True, exist_ok=True)
    REIHEN_REFERENZ.write_text(json.dumps(alle, indent=1, ensure_ascii=False), encoding="utf-8")
    return REIHEN_REFERENZ


def referenz_vergleichen(agent: str, sid: str, analyse: dict) -> list[str]:
    """Vergleicht die aktuelle Kurve mit der abgelegten Referenz. Fehlt die
    Referenz, wird nichts bemängelt (erster Lauf erzeugt sie)."""
    befunde: list[str] = []
    if not REIHEN_REFERENZ.is_file():
        return befunde
    try:
        alle = json.loads(REIHEN_REFERENZ.read_text(encoding="utf-8"))
    except Exception:
        return befunde
    alt = alle.get(f"{agent}/{sid}")
    if not alt:
        return befunde
    alt_kurve = alt.get("bewegungskurve", [])
    neu_kurve = analyse["bewegungskurve"]
    if alt.get("bewegung_max", 0.0) > BEWEGUNG_SCHWELLE and analyse["bewegung_max"] <= BEWEGUNG_SCHWELLE:
        befunde.append(f"Reihe {sid} war in Bewegung (max {alt['bewegung_max']}), jetzt still ({analyse['bewegung_max']})")
    if alt_kurve and neu_kurve and len(alt_kurve) == len(neu_kurve):
        abstand = max(abs(a - b) for a, b in zip(alt_kurve, neu_kurve))
        if abstand > 0.05:
            befunde.append(f"Reihe {sid} weicht im Rhythmus ab (max Differenz {abstand:.4f} gegen Referenz {alt.get('referenz_hash', '')})")
    return befunde
