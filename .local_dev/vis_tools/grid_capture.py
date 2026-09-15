# -*- coding: utf-8 -*-
"""Frame-Matrix (Contact Sheet). Eigene Zuständigkeit: Ein 5-Sekunden-Lauf
des Godot-Fensters wird alle 500 ms fotografiert und zu einem 3x3-Raster
montiert. Der Agent liest aus einem einzigen Bild den zeitlichen Ablauf:
Boot, Chunk-Laden, Render.

Kein Spielcode kennt diese Datei. Sie beobachtet nur das Fenster.
"""

import subprocess
import sys
import time
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parents[2]
BILDER_ORDNER = PROJEKT_STAMM / ".local_dev" / "vis_tools" / "frames"
AUSGABE = PROJEKT_STAMM / ".local_dev" / "vis_tools" / "frames" / "kontaktbogen.png"

INTERVALL_MS = 500
DAUER_S = 5.0
RASTER = 3


def screenshots_greifen(dauer_s: float, intervall_ms: int, ausgabe_ordner: Path) -> list[Path]:
    """Greift im laufenden Betrieb alle intervall_ms Millisekunden ein Bild.
    Benutzt die Godot-eigene Bildgreif-Sonde, wenn sie läuft; sonst den
    Bildschirm-Ausschnitt des Godot-Fensters über Pillow ImageGrab."""
    from PIL import ImageGrab

    ausgabe_ordner.mkdir(parents=True, exist_ok=True)
    for alt in ausgabe_ordner.glob("rahmen_*.png"):
        alt.unlink()
    bilder: list[Path] = []
    start = time.monotonic()
    index = 0
    while time.monotonic() - start < dauer_s:
        bild = ImageGrab.grab()
        pfad = ausgabe_ordner / f"rahmen_{index:03d}.png"
        bild.save(pfad)
        bilder.append(pfad)
        index += 1
        time.sleep(intervall_ms / 1000.0)
    return bilder


def raster_montieren(bilder: list[Path], kacheln: int, ziel: Path) -> Path:
    """Montiert die Bilder zu einem kacheln x kacheln Raster. Überschüssige
    Bilder bleiben unbenutzt; fehlende Kacheln bleiben schwarz."""
    from PIL import Image

    if not bilder:
        raise ValueError("Keine Bilder zum Montieren")
    erstes = Image.open(bilder[0]).convert("RGB")
    kw, kh = erstes.size
    ziel_Ordner = ziel.parent
    ziel_Ordner.mkdir(parents=True, exist_ok=True)
    bogen = Image.new("RGB", (kw * kacheln, kh * kacheln), (0, 0, 0))
    for i, pfad in enumerate(bilder[: kacheln * kacheln]):
        x = (i % kacheln) * kw
        y = (i // kacheln) * kh
        bogen.paste(Image.open(pfad).convert("RGB"), (x, y))
    bogen.save(ziel)
    return ziel


def godot_starten(godot_befehl: str, szene: str) -> subprocess.Popen:
    """Startet das Godot-Fenster für den Testlauf als Hintergrundprozess."""
    befehl = [godot_befehl, "--path", str(PROJEKT_STAMM)]
    if szene:
        befehl.append(szene)
    return subprocess.Popen(befehl, cwd=str(PROJEKT_STAMM))


def hauptprogramm() -> int:
    godot_befehl = sys.argv[1] if len(sys.argv) > 1 else "godot"
    szene = sys.argv[2] if len(sys.argv) > 2 else ""
    prozess = godot_starten(godot_befehl, szene)
    try:
        time.sleep(1.0)
        bilder = screenshots_greifen(DAUER_S, INTERVALL_MS, BILDER_ORDNER)
    finally:
        prozess.terminate()
        try:
            prozess.wait(timeout=10)
        except subprocess.TimeoutExpired:
            prozess.kill()
    ziel = raster_montieren(bilder, RASTER, AUSGABE)
    print(f"Kontaktbogen: {ziel.relative_to(PROJEKT_STAMM)} ({len(bilder)} Rahmen)")
    return 0


if __name__ == "__main__":
    sys.exit(hauptprogramm())
