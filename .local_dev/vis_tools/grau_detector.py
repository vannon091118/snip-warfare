# -*- coding: utf-8 -*-
"""Graubild- und Histogramm-Detector. Eigene Zuständigkeit: Die Farb-
verteilung im Rendering-Viewport messen und mechanisch entscheiden, ob
der Viewport bei der Standard-Clear-Color (Grau) hängen bleibt oder
Kacheln gezeichnet werden.

Kein Spielcode kennt diese Datei. Sie liest nur Bilder.
"""

import sys
from pathlib import Path

import numpy as np

PROJEKT_STAMM = Path(__file__).resolve().parents[2]

# Standard-Clear-Color Grau: Der Kanal-Mittelwert liegt eng beieinander und
# die Streuung ist gering, weil nichts als die Grundfarbe gemalt wurde.
GRAU_TOLERANZ = 6.0
GRAU_STREUUNG_MAX = 8.0


def bild_laden(pfad: Path) -> np.ndarray:
    import cv2

    bild = cv2.imread(str(pfad), cv2.IMREAD_COLOR)
    if bild is None:
        raise FileNotFoundError(f"Bild nicht lesbar: {pfad}")
    return bild


def ist_grau(bild: np.ndarray) -> tuple[bool, str]:
    """True, wenn alle drei Kanäle im Mittel gleich und praktisch streuungsfrei sind."""
    kanäle = [bild[:, :, i].astype(np.float64) for i in range(3)]
    mittel = [float(k.mean()) for k in kanäle]
    streuung = float(np.std(bild))
    spanne = max(mittel) - min(mittel)
    hängt = spanne <= GRAU_TOLERANZ and streuung <= GRAU_STREUUNG_MAX
    bericht = f"Kanal-Mittel: {mittel} Streuung: {streuung:.2f} -> {'GRAU-HÄNGER' if hängt else 'gerendert'}"
    return hängt, bericht


def histogramm_unterschied(bild_a: np.ndarray, bild_b: np.ndarray) -> float:
    """Vergleicht die Farbverteilung zweier Bilder über je ein 3x256-Histogramm.
    Rückgabe: Korrelations-Distanz (0 = identisch, 1 = völlig verschieden)."""
    import cv2

    hist_a = cv2.calcHist([bild_a], [0, 1, 2], None, [8, 8, 8], [0, 256, 0, 256, 0, 256])
    hist_b = cv2.calcHist([bild_b], [0, 1, 2], None, [8, 8, 8], [0, 256, 0, 256, 0, 256])
    cv2.normalize(hist_a, hist_a)
    cv2.normalize(hist_b, hist_b)
    return float(cv2.compareHist(hist_a, hist_b, cv2.HISTCMP_BHATTACHARYYA))


def kachel_beweis(bild: np.ndarray) -> tuple[bool, str]:
    """True, wenn das Bild Kachel-Struktur trägt: Kantendichte im unteren
    Bildbereich deutlich über der eines leeren Viewports."""
    import cv2

    grau = cv2.cvtColor(bild, cv2.COLOR_BGR2GRAY)
    kanten = cv2.Canny(grau, 60, 160)
    dichte = float(kanten.mean())
    return dichte > 1.0, f"Kantendichte: {dichte:.2f}"


def pruefe_bild(pfad: Path) -> int:
    bild = bild_laden(pfad)
    hänger, bericht_g = ist_grau(bild)
    print(f"{pfad.name}: {bericht_g}")
    kacheln, bericht_k = kachel_beweis(bild)
    print(f"{pfad.name}: {bericht_k}")
    if hänger:
        print(f"FEHLER: Viewport bleibt bei Grau haengen: {pfad}")
        return 1
    if not kacheln:
        print(f"FEHLER: Keine Kachel-Struktur erkennbar: {pfad}")
        return 1
    return 0


def hauptprogramm() -> int:
    if len(sys.argv) < 2:
        print("Aufruf: python grau_detector.py <bild1> [bild2 ...]")
        return 2
    ergebnis = 0
    bilder = [Path(a) for a in sys.argv[1:]]
    geladen = [bild_laden(b) for b in bilder]
    for pfad, bild in zip(bilder, geladen):
        ergebnis = max(ergebnis, pruefe_bild(pfad))
    for i in range(1, len(geladen)):
        d = histogramm_unterschied(geladen[i - 1], geladen[i])
        print(f"Histogramm-Abstand {bilder[i-1].name} <-> {bilder[i].name}: {d:.4f}")
    return ergebnis


if __name__ == "__main__":
    sys.exit(hauptprogramm())
