# -*- coding: utf-8 -*-
"""Sonden visuelle Brücke. Eigene Zuständigkeit: Ein Sonden-Bild wird durch
die visuellen Detektoren aus .local_dev/vis_tools gelesen — Grau-Hänger,
Kachel-Beweis und optionaler Layout-Diff gegen die Referenz. Das ist die
Playwright-artige visuelle Prüfung der Sonden: Das Bild muss nicht nur
existieren, es muss messbar rendern.

Die Szenario-Datei steuert es über das Feld "visuell":
  ""           -> Standardprüfung (kein Grau-Hänger, Kachel-Struktur nötig)
  "grau"       -> nur Grau-Hänger-Prüfung
  "kacheln"    -> nur Kachel-Struktur-Prüfung
  "layout"     -> Standardprüfung plus Layout-Diff gegen referenz_layout.png
  "keine"      -> visuelle Prüfung ausdrücklich aus (rein logische Sonde)

Die Brücke meldet selbst keine Fehler, sie liefert Zeilen; pruef_sonden
gibt die VISUELL-Zeilen ins Lauf-Log, harte Verletzungen werden als
SONDE-WIDERSPRUCH-Zeilen zurückgegeben und landen so als E026 im Preflight.
"""

from pathlib import Path

from tools.preflight.kern import PROJEKT_STAMM
from tools.sonden.sonden_pfade_vis import REFERENZ_LAYOUT, VIS_STAMM


def _lade_werkzeug(name: str):
    import importlib.util
    import sys

    pfad = VIS_STAMM / name
    if not pfad.is_file():
        return None
    spez = importlib.util.spec_from_file_location(f"_vis_sonde_{name[:-3]}", str(pfad))
    modul = importlib.util.module_from_spec(spez)
    sys.modules[spez.name] = modul
    assert spez.loader is not None
    spez.loader.exec_module(modul)
    return modul


def visuell_fuer_bild(png_pfad: Path, sid: str, modus: str = "") -> list[str]:
    """Liest ein Sonden-Bild und liefert VISUELL-Zeilen. Harte Verletzungen
    kommen als SONDE-WIDERSPRUCH-Zeile zurück und werden so zu E026."""
    zeilen: list[str] = []
    if "sonden_bilder" not in str(png_pfad) or not str(png_pfad).endswith(".png"):
        return zeilen
    modus = (modus or "").strip().lower()
    if modus == "keine":
        zeilen.append(f"VISUELL {sid}: modus=keine, übersprungen")
        return zeilen
    fs = PROJEKT_STAMM / Path(str(png_pfad).replace("res://", ""))
    if not fs.is_file():
        return zeilen
    try:
        import cv2

        bild = cv2.imread(str(fs), cv2.IMREAD_COLOR)
        if bild is None:
            zeilen.append(f"SONDE-WIDERSPRUCH: {sid} Sonden-Bild nicht lesbar: {fs.name}")
            return zeilen
    except ImportError:
        zeilen.append(f"VISUELL {sid}: opencv fehlt, visuelle Prüfung übersprungen")
        return zeilen
    detector = _lade_werkzeug("grau_detector.py")
    if detector is None:
        zeilen.append(f"VISUELL {sid}: grau_detector fehlt, visuelle Prüfung übersprungen")
        return zeilen
    pruefe_grau = modus in ("", "grau", "layout")
    pruefe_kacheln = modus in ("", "kacheln", "layout")
    if pruefe_grau:
        hänger, bericht = detector.ist_grau(bild)
        zeilen.append(f"VISUELL {sid} grau: {bericht}")
        if hänger:
            zeilen.append(f"SONDE-WIDERSPRUCH: {sid} Sonden-Bild bleibt bei der Standard-Clear-Color haengen ({bericht})")
    if pruefe_kacheln:
        kacheln, bericht_k = detector.kachel_beweis(bild)
        zeilen.append(f"VISUELL {sid} kacheln: {bericht_k}")
        if not kacheln:
            zeilen.append(f"SONDE-WIDERSPRUCH: {sid} Sonden-Bild traegt keine Kachel-Struktur ({bericht_k})")
    if modus == "layout":
        layout = _lade_werkzeug("layout_diff.py")
        if layout is None or not REFERENZ_LAYOUT.is_file():
            zeilen.append(f"VISUELL {sid} layout: keine Referenz ({REFERENZ_LAYOUT.name}), übersprungen")
        else:
            funde = layout.layout_diff(REFERENZ_LAYOUT, fs)
            zeilen.append(f"VISUELL {sid} layout: {len(funde)} abweichende Zellen")
            if funde:
                x, y, bw, bh = layout.fundament_rahmen([(f[0], f[1], f[2], f[3]) for f in funde])
                zeilen.append(f"SONDE-ABWEICHUNG: {sid} Layout weicht ab, Gesamt-Rahmen ({x},{y}) {bw}x{bh} in {len(funde)} Zellen")
    return zeilen
