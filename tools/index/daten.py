# -*- coding: utf-8 -*-
"""Daten-Index: Die JSON-Pools des Projekts mit Besitzer und Verbrauchern.

Eine Zuständigkeit: Jede Datei unter einem `data`-Ordner wird mit ihrem Pfad,
ihrer Domaene, ihren obersten Schluesseln und den Klassen gelesen, die sie
namentlich nennen. So weiss der Daten-Index, wem ein Pool gehoert und wer ihn
verbraucht, ohne dass ein Mensch eine Tabelle pflegen muss.
"""

import json

from .kern import DOMAENEN, PROJEKT_STAMM, gd_dateien


def _domaene_von(relativ):
    """Besitzer-Domaene eines Datenpools; sonst sein data-Ordner als Herkunft."""
    for schluessel, _kuerzel, _praefix, ordner in DOMAENEN:
        if relativ.startswith(ordner):
            return schluessel
    return relativ.split("/data/", 1)[0] + "/data" if "/data/" in relativ else "-"


def _oberste_schluessel(daten):
    """Oberste Schluessel eines Pools; bei Listen die Laenge."""
    if isinstance(daten, dict):
        return list(daten.keys())
    if isinstance(daten, list):
        return ["[Liste]"]
    return []


def _eintraege(daten):
    if isinstance(daten, dict):
        return len(daten)
    if isinstance(daten, list):
        return len(daten)
    return 1


def pools_sammeln(dateien=None):
    """Liest jeden JSON-Pool samt Domaene, Schluesseln und Verbrauchern."""
    dateien = gd_dateien() if dateien is None else dateien
    pools = []
    for pfad in sorted(PROJEKT_STAMM.rglob("*.json")):
        relativ = str(pfad.relative_to(PROJEKT_STAMM)).replace("\\", "/")
        if "/data/" not in relativ or relativ.startswith((".godot/", ".git/")):
            continue
        try:
            daten = json.loads(pfad.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            daten = None
        monat = pfad.name
        verbraucher = [verzeichnis for verzeichnis, code in dateien if monat in code]
        pools.append({
            "pfad": relativ,
            "name": monat,
            "domaene": _domaene_von(relativ),
            "schluessel": _oberste_schluessel(daten) if daten is not None else [],
            "eintraege": _eintraege(daten) if daten is not None else 0,
            "lesbar": daten is not None,
            "verbraucher": sorted(verbraucher),
        })
    return pools


def zusammenfassung(pools):
    """Zahlen fuer Kopfzeilen und Delta: Pools, lesbare Pools, Verwaiste."""
    return {
        "pools": len(pools),
        "lesbar": sum(1 for pool in pools if pool["lesbar"]),
        "verwaist": sum(1 for pool in pools if not pool["verbraucher"]),
    }
