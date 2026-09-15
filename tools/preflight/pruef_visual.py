# -*- coding: utf-8 -*-
"""Prüfkategorie visual (E052-E054): Die visuelle Lauf-Stufe 2.

Drei Werkzeuge aus .local_dev/vis_tools werden in den Preflight gezogen:
  E052 Frame-Matrix: Der Kontaktbogen des 5-Sekunden-Laufs muss existieren
      und zeichnen; der Grau-Detector darf auf keinem Rahmen anschlagen.
  E053 Grau-Detector: Der Viewport darf nicht bei der Standard-Clear-Color
      haengen bleiben; Kachel-Struktur muss messbar sein.
  E054 Layout-Diff: Der aktuelle Frame darf vom Referenz-Layout nur in
      gemeldeten Zellen abweichen; eine fehlende Referenz ist E054.

Fail-closed: Fehlt ein Werkzeug oder schlägt es fehl, meldet die Kategorie.
Die OCR-Sonden bleiben bestehen, diese Kategorie ersetzt ihre Bildbeurteilung.
"""

import subprocess
import sys
from pathlib import Path

from .kern import PROJEKT_STAMM, fehler

VIS_STAMM = PROJEKT_STAMM / ".local_dev" / "vis_tools"
KONTAKTBOGEN = VIS_STAMM / "frames" / "kontaktbogen.png"
REFERENZ_LAYOUT = VIS_STAMM / "referenz_layout.png"


def _lade_werkzeug(name: str):
    """Lädt ein Werkzeugmodul aus .local_dev/vis_tools ohne Paket-Import."""
    import importlib.util

    pfad = VIS_STAMM / name
    if not pfad.is_file():
        return None
    spez = importlib.util.spec_from_file_location(f"_vis_{name[:-3]}", str(pfad))
    modul = importlib.util.module_from_spec(spez)
    sys.modules[spez.name] = modul
    assert spez.loader is not None
    spez.loader.exec_module(modul)
    return modul


def _erwarte_abhängigkeiten() -> bool:
    try:
        import cv2  # noqa: F401
        import numpy  # noqa: F401
        import PIL  # noqa: F401
        return True
    except ImportError as e:
        fehler("E052", ".local_dev/vis_tools", 1, f"Pakete fehlen: {e}; pip install pillow opencv-python numpy")
        return False


def pruefe_visual(godot_befehl: str = "godot") -> None:
    if not _erwarte_abhängigkeiten():
        return
    grid = _lade_werkzeug("grid_capture.py")
    detector = _lade_werkzeug("grau_detector.py")
    layout = _lade_werkzeug("layout_diff.py")
    if grid is None or detector is None or layout is None:
        fehler("E052", ".local_dev/vis_tools", 1, "Vis-Werkzeuge fehlen in .local_dev/vis_tools (fail-closed)")
        return

    # E052: Frame-Matrix aufnehmen und montieren
    try:
        from .godot_aufloeser import aufloese_godot

        binär = aufloese_godot(godot_befehl)
        if binär is None:
            fehler("E052", "visual", 0, "Godot nicht gefunden (fail-closed)")
            return
        prozess = grid.godot_starten(binär, "")
        try:
            import time

            time.sleep(1.0)
            bilder = grid.screenshots_greifen(grid.DAUER_S, grid.INTERVALL_MS, grid.BILDER_ORDNER)
        finally:
            prozess.terminate()
            try:
                prozess.wait(timeout=10)
            except subprocess.TimeoutExpired:
                prozess.kill()
        ziel = grid.raster_montieren(bilder, grid.RASTER, grid.AUSGABE)
        print(f"E052 Frame-Matrix: {len(bilder)} Rahmen -> {ziel.name}")
    except Exception as e:
        fehler("E052", ".local_dev/vis_tools", 1, f"Frame-Matrix fehlgeschlagen: {e}")
        return

    # E053: Grau-Detector auf den Kontaktbogen
    try:
        import cv2

        bogen = cv2.imread(str(KONTAKTBOGEN), cv2.IMREAD_COLOR)
        if bogen is None:
            fehler("E053", ".local_dev/vis_tools", 1, f"Kontaktbogen nicht lesbar: {KONTAKTBOGEN}")
            return
        hänger, bericht = detector.ist_grau(bogen)
        kacheln, bericht_k = detector.kachel_beweis(bogen)
        print(f"E053 Grau-Detector: {bericht}; {bericht_k}")
        if hänger:
            fehler("E053", "visual", 1, f"Viewport bleibt bei Grau haengen: {bericht}")
        elif not kacheln:
            fehler("E053", "visual", 1, f"Keine Kachel-Struktur im Viewport: {bericht_k}")
    except Exception as e:
        fehler("E053", ".local_dev/vis_tools", 1, f"Grau-Detector fehlgeschlagen: {e}")

    # E054: Layout-Diff gegen die Referenz, wenn eine existiert
    if not REFERENZ_LAYOUT.is_file():
        print("E054 Layout-Diff: keine Referenz (referenz_layout.png), uebersprungen")
        return
    try:
        funde = layout.layout_diff(REFERENZ_LAYOUT, KONTAKTBOGEN)
        if not funde:
            print("E054 Layout-Diff: keine Abweichung")
            return
        for x, y, bw, bh, abw in funde:
            fehler("E054", "visual", 1, f"Layout-Abweichung bei ({x},{y}) {bw}x{bh} Dichte-Delta {abw:.3f}")
    except Exception as e:
        fehler("E054", ".local_dev/vis_tools", 1, f"Layout-Diff fehlgeschlagen: {e}")
