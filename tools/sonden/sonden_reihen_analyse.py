# -*- coding: utf-8 -*-
"""Sonden Reihen Analyse. Eigene Zuständigkeit: Aus den Frame-für-Frame-
Bildern einer Sonden-Reihe (anim_frame / kette_frame) wird eine messbare
Prüfreferenz: Bewegungs-Kurve, Frame-Abstände und ein Referenz-Hash je
Reihe. Die Referenz wird als JSON abgelegt und von der visuellen Brücke
gegen spätere Läufe geprüft — Mechanik, Animation und Ketten werden so
Frame für Frame beweisbar, nicht nur am Endbild.

Eigene Zuständigkeit, keine Verbindung zu OCR oder Gate-Skripten.
"""

import json
from pathlib import Path

from tools.sonden.sonden_pfade_vis import REIHEN_REFERENZ
BEWEGUNG_SCHWELLE = 0.001


def _lade_grau():
    import importlib.util
    import sys

    pfad = VIS_STAMM / "grau_detector.py"
    if not pfad.is_file():
        return None
    spez = importlib.util.spec_from_file_location("_reihen_grau", str(pfad))
    modul = importlib.util.module_from_spec(spez)
    sys.modules[spez.name] = modul
    assert spez.loader is not None
    spez.loader.exec_module(modul)
    return modul


def reihen_ordner(agent: str, sid: str) -> Path:
    return PROJEKT_STAMM / "tools" / "logs" / "sonden_bilder" / agent / "reihen" / sid


def reihe_analysieren(bilder: list[Path]) -> dict:
    """Misst eine Bildreihe: je Folgeschritt der Bewegungs-Anteil gegen den
    Vorgänger, die Kantendichte je Bild, und ob ein Grau-Hänger vorliegt."""
    import cv2
    import numpy as np

    grau_werkzeug = _lade_grau()
    kurve: list[float] = []
    dichten: list[float] = []
    bilder_geladen: list = []
    for pfad in bilder:
        bild = cv2.imread(str(pfad), cv2.IMREAD_COLOR)
        if bild is None:
            continue
        bilder_geladen.append(bild)
        kanten = cv2.Canny(cv2.cvtColor(bild, cv2.COLOR_BGR2GRAY), 60, 160)
        dichten.append(float(kanten.mean()))
    for i in range(1, len(bilder_geladen)):
        a = cv2.cvtColor(bilder_geladen[i - 1], cv2.COLOR_BGR2GRAY).astype(np.float64)
        b = cv2.cvtColor(bilder_geladen[i], cv2.COLOR_BGR2GRAY).astype(np.float64)
        delta = float(np.abs(a - b).mean() / 255.0)
        kurve.append(round(delta, 6))
    grau_hänger = False
    if grau_werkzeug is not None and bilder_geladen:
        grau_hänger, _bericht = grau_werkzeug.ist_grau(bilder_geladen[-1])
    return {
        "bilder": len(bilder_geladen),
        "bewegungskurve": kurve,
        "kantendichten": [round(d, 3) for d in dichten],
        "bewegung_max": max(kurve) if kurve else 0.0,
        "bewegung_summe": round(sum(kurve), 6),
        "grau_hänger": grau_hänger,
    }


def reihen_bilder_lesen(ordner: Path) -> list[Path]:
    if not ordner.is_dir():
        return []
    return sorted(ordner.glob("*.png"))
