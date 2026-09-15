# -*- coding: utf-8 -*-
"""Sonden Perf Analyse. Eigene Zuständigkeit: Die Performance-Messung der
Sonden — SONDE-PERF-Zeilen lesen, gegen Schwellwerte prüfen und als
Referenz ablegen. Die Reihen-Analyse (Bewegungs-Kurven) wohnt daneben."""

import json
import re
from pathlib import Path

from tools.preflight.kern import PROJEKT_STAMM

VIS_STAMM = PROJEKT_STAMM / ".local_dev" / "vis_tools"
REIHEN_REFERENZ = VIS_STAMM / "reihen_referenz.json"

# Schwellwerte der Performance-Messung: Die p95-Frame-Zeit eines Sonden-
# Laufs darf 50 ms nicht dauerhaft übersteigen (unter 20 FPS), der Maximal-
# Wert 200 ms nicht (ein eingefrorener Frame). Szenarien können über das
# Feld "perf_p95_max_ms" eigene Grenzen setzen.
PERF_P95_STANDARD_MS = 50.0
PERF_MAX_STANDARD_MS = 200.0

PERF_MUSTER = re.compile(
    r"SONDE-PERF: (?:reihe|kette|gesamt)(?:(\S+))? p50=([\d.]+) p95=([\d.]+) max=([\d.]+) proben=(\d+)"
)


def perf_zeilen_lesen(zeilen: list[str]) -> list[dict]:
    """Liest SONDE-PERF-Zeilen und liefert je Zeile ein Wörterbuch mit
    reihe/kette, p50, p95, max und proben."""
    befunde: list[dict] = []
    for z in zeilen:
        treffer = PERF_MUSTER.search(z)
        if treffer:
            befunde.append({
                "reihe": (treffer.group(1) or "gesamt").lstrip("="),
                "p50": float(treffer.group(2)),
                "p95": float(treffer.group(3)),
                "max": float(treffer.group(4)),
                "proben": int(treffer.group(5)),
            })
    return befunde


def perf_pruefen(perf: dict, p95_max_ms: float = PERF_P95_STANDARD_MS,
                 max_max_ms: float = PERF_MAX_STANDARD_MS) -> list[str]:
    """Prüft eine Perf-Messung gegen die Schwellwerte und liefert Befunde."""
    texte: list[str] = []
    if perf["p95"] > p95_max_ms:
        texte.append(f"p95-Frame-Zeit {perf['p95']:.1f} ms über Schwellwert {p95_max_ms:.0f} ms (Reihe {perf['reihe']})")
    if perf["max"] > max_max_ms:
        texte.append(f"Max-Frame-Zeit {perf['max']:.1f} ms über Schwellwert {max_max_ms:.0f} ms (Reihe {perf['reihe']})")
    return texte


def perf_referenz_schreiben(agent: str, sid: str, perf_liste: list[dict]) -> Path:
    """Legt die Perf-Messungen je Szenario als Referenz ab, damit spätere
    Läufe dagegen gehalten werden."""
    alle: dict = {}
    if REIHEN_REFERENZ.is_file():
        try:
            alle = json.loads(REIHEN_REFERENZ.read_text(encoding="utf-8"))
        except Exception:
            alle = {}
    alle.setdefault("perf", {})[f"{agent}/{sid}"] = perf_liste
    REIHEN_REFERENZ.parent.mkdir(parents=True, exist_ok=True)
    REIHEN_REFERENZ.write_text(json.dumps(alle, indent=1, ensure_ascii=False), encoding="utf-8")
    return REIHEN_REFERENZ
