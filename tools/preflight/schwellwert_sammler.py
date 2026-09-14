# -*- coding: utf-8 -*-
"""Schwellwert Sammler. Eigene Zuständigkeit: JSON-Schwellen sammeln."""

import json as _json

from .kern import PROJEKT_STAMM


def sammle_json_schwellwerte():
    schluessel_mengen = {"schwellwert", "verbrauch_je_takt", "takt_minuten", "tag_minuten", "nacht_minuten"}
    schluessel_keywords = {
        "schwellwert": ["schwellwert", "schwelle", "kaelte", "hitze", "hunger", "waerme", "nahrung"],
        "verbrauch_je_takt": ["verbrauch", "je_takt", "verteilung", "takt", "nahrung"],
        "takt_minuten": ["takt_minuten", "takt", "rhythmus", "weltrhythmus"],
        "tag_minuten": ["tag_minuten", "tag", "rhythmus", "weltrhythmus"],
        "nacht_minuten": ["nacht_minuten", "nacht", "rhythmus", "weltrhythmus"],
    }
    ergebnis = {}
    wert_keywords = {}
    for p in sorted(PROJEKT_STAMM.rglob("*.json")):
        if ".godot" in p.parts or "addons" in p.parts:
            continue
        try:
            daten = _json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue
        rel = str(p.relative_to(PROJEKT_STAMM)).replace("\\", "/")
        def walk(v, pfad):
            if isinstance(v, dict):
                for k, val in v.items():
                    walk(val, pfad + [str(k)])
            elif isinstance(v, list):
                for i, val in enumerate(v):
                    walk(val, pfad + [str(i)])
            elif isinstance(v, (int, float)) and not isinstance(v, bool):
                if pfad and pfad[-1] in schluessel_mengen:
                    fv = float(v)
                    if any(seg.startswith("_dokumentation") for seg in pfad):
                        return
                    if fv == 0.0:
                        return
                    ergebnis.setdefault(fv, []).append(f"{rel}:{'/'.join(pfad)}")
                    kws = schluessel_keywords.get(pfad[-1], [])
                    wert_keywords.setdefault(fv, set()).update(k.lower() for k in kws)
        walk(daten, [])
    return ergebnis, wert_keywords
