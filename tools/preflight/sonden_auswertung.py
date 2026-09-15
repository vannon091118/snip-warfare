# -*- coding: utf-8 -*-
"""Sonden Lauf Auswertung. Eigene Zuständigkeit: Die Auswertung eines
Szenario-Laufs — Perf-Zeilen prüfen, Bilder visuell und per OCR lesen,
Reihen analysieren und gegen Referenzen halten. pruef_sonden ruft nur
noch; alle Urteile fallen hier."""

import json
from pathlib import Path

from .kern import PROJEKT_STAMM, fehler


def szenario_auswerten(pfad: Path, data: dict, tail: list[str], agent: str,
                       gesammelt: list[str]) -> None:
    """Ein fertig gelaufenes Szenario auswerten: Perf, Bilder, Reihen."""
    sid = str(data["id"])
    from tools.sonden.sonden_perf_analyse import (
        perf_zeilen_lesen,
        perf_pruefen,
        perf_referenz_schreiben,
    )
    perf_liste = perf_zeilen_lesen(tail)
    for perf in perf_liste:
        gesammelt.append(
            f"PERF {sid} {perf['reihe']}: p50={perf['p50']:.1f}ms p95={perf['p95']:.1f}ms max={perf['max']:.1f}ms proben={perf['proben']}"
        )
        grenze_p95 = float(data.get("perf_p95_max_ms", 50.0))
        grenze_max = float(data.get("perf_max_ms", 200.0))
        for text in perf_pruefen(perf, grenze_p95, grenze_max):
            # Lade-/Compiler-Stops sind Hinweise, keine Spielzeit-Verstöße.
            if text.startswith("Lade-/Compiler-Stop"):
                gesammelt.append(f"PERF-HINWEIS {sid} {perf['reihe']}: {text}")
                continue
            fehler("E029", pfad.relative_to(PROJEKT_STAMM), 1, f"SONDE-PERF-ABWEICHUNG: {text}")
    if perf_liste:
        perf_referenz_schreiben(agent, sid, perf_liste)
    _bilder_auswerten(pfad, data, tail, sid, agent, gesammelt)
    _reihen_auswerten(pfad, data, sid, agent, gesammelt)


def _bilder_auswerten(pfad: Path, data: dict, tail: list[str], sid: str,
                      agent: str, gesammelt: list[str]) -> None:
    """Jede Bild-Zeile des Laufs durch OCR und die visuelle Brücke."""
    from tools.sonden.sonden_ocr_bruecke import ocr_fuer_bild
    from tools.sonden.sonden_visuelle_bruecke import visuell_fuer_bild
    for z in tail:
        if "sonden_bilder" in z and z.strip().endswith(".png"):
            png = Path(z.strip().split()[-1]) if " " in z else None
            if png is None:
                continue
            ocr_zeile = ocr_fuer_bild(png, sid)
            if ocr_zeile:
                gesammelt.append(ocr_zeile)
            for vis_zeile in visuell_fuer_bild(png, sid, str(data.get("visuell", ""))):
                gesammelt.append(vis_zeile)


def _reihen_auswerten(pfad: Path, data: dict, sid: str, agent: str,
                      gesammelt: list[str]) -> None:
    """Reihen-Szenarien: Bilder analysieren, Referenz schreiben und halten."""
    hat_reihen = any(
        isinstance(s, dict) and str(s.get("art", "")) in {"anim_frame", "kette_frame"}
        for s in data.get("schritte", [])
    )
    if not hat_reihen:
        return
    from tools.sonden.sonden_reihen_analyse import (
        reihen_bilder_lesen,
        reihen_ordner,
        reihe_analysieren,
    )
    from tools.sonden.sonden_reihen_referenz import (
        referenz_schreiben,
        referenz_vergleichen,
    )
    ordner = reihen_ordner(agent, sid)
    bilder = reihen_bilder_lesen(ordner)
    if not bilder:
        return
    analyse = reihe_analysieren(bilder)
    referenz_schreiben(agent, sid, analyse)
    gesammelt.append(
        f"REIHE {sid}: bilder={analyse['bilder']} bewegung_max={analyse['bewegung_max']} summe={analyse['bewegung_summe']} grau={analyse['grau_hänger']}"
    )
    for befund in referenz_vergleichen(agent, sid, analyse):
        fehler("E028", pfad.relative_to(PROJEKT_STAMM), 1, f"SONDE-ABWEICHUNG: {befund}")
