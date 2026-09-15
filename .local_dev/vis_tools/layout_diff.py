# -*- coding: utf-8 -*-
"""Layout- und Bounding-Box-Diff. Eigene Zuständigkeit: Ein Referenz-UI-
Layout gegen den aktuellen Frame vergleichen und fehlende CanvasLayer oder
verschobene Knoten rein räumlich erkennen — ohne OCR und ohne Textsuche.

Methode: Beide Bilder werden grau gestellt, verwischt, kantengefiltert und
in Gitterzellen zerlegt. Jede Zelle, deren Kantendichte sich über einen
Schwellwert unterscheidet, ist ein Fund — als Bounding-Box gemeldet.
"""

import sys
from pathlib import Path

import numpy as np

PROJEKT_STAMM = Path(__file__).resolve().parents[2]

GITTER = 8
ZELLE_SCHWELLWERT = 0.02
MIN_FUND_PIXEL = 40


def bild_laden(pfad: Path) -> np.ndarray:
    import cv2

    bild = cv2.imread(str(pfad), cv2.IMREAD_COLOR)
    if bild is None:
        raise FileNotFoundError(f"Bild nicht lesbar: {pfad}")
    return bild


def kantenbild(bild: np.ndarray) -> np.ndarray:
    import cv2

    grau = cv2.cvtColor(bild, cv2.COLOR_BGR2GRAY)
    verwischt = cv2.GaussianBlur(grau, (5, 5), 0)
    return cv2.Canny(verwischt, 50, 150)


def kanten_matrix(kanten: np.ndarray, gitter: int) -> np.ndarray:
    """Zerlegt das Kantenbild in ein gitter x gitter Feld der Zell-Dichten."""
    h, w = kanten.shape
    zeilen = np.array_split(np.arange(h), gitter)
    spalten = np.array_split(np.arange(w), gitter)
    feld = np.zeros((gitter, gitter), dtype=np.float64)
    for i, zr in enumerate(zeilen):
        for j, zc in enumerate(spalten):
            zelle = kanten[np.ix_(zr, zc)]
            feld[i, j] = float(zelle.mean()) / 255.0
    return feld


def fundament_rahmen(masken: list[tuple[int, int, int, int]]) -> tuple[int, int, int, int]:
    """Vereinigt Fundzellen zu einem einzigen Bounding-Rahmen (x, y, w, h)."""
    x0 = min(m[0] for m in masken)
    y0 = min(m[1] for m in masken)
    x1 = max(m[0] + m[2] for m in masken)
    y1 = max(m[1] + m[3] for m in masken)
    return x0, y0, x1 - x0, y1 - y0


def layout_diff(referenz: Path, aktuell: Path) -> list[tuple[int, int, int, int, float]]:
    """Vergleicht beide Bilder und liefert die Fund-Rahmen mit Abweichung."""
    import cv2

    bild_a = bild_laden(referenz)
    bild_b = bild_laden(aktuell)
    if bild_a.shape != bild_b.shape:
        h = min(bild_a.shape[0], bild_b.shape[0])
        w = min(bild_a.shape[1], bild_b.shape[1])
        bild_a = bild_a[:h, :w]
        bild_b = bild_b[:h, :w]
    feld_a = kanten_matrix(kantenbild(bild_a), GITTER)
    feld_b = kanten_matrix(kantenbild(bild_b), GITTER)
    delta = np.abs(feld_a - feld_b)
    h, w = kantenbild(bild_a).shape
    cell_h = h // GITTER
    cell_w = w // GITTER
    funde: list[tuple[int, int, int, int, float]] = []
    for i in range(GITTER):
        for j in range(GITTER):
            if delta[i, j] > ZELLE_SCHWELLWERT:
                x = j * cell_w
                y = i * cell_h
                funde.append((x, y, cell_w, cell_h, float(delta[i, j])))
    return funde


def hauptprogramm() -> int:
    if len(sys.argv) != 3:
        print("Aufruf: python layout_diff.py <referenz.png> <aktuell.png>")
        return 2
    referenz = Path(sys.argv[1])
    aktuell = Path(sys.argv[2])
    funde = layout_diff(referenz, aktuell)
    if not funde:
        print("Layout-Diff: keine Abweichung")
        return 0
    for x, y, bw, bh, abw in funde:
        print(f"ABWEICHUNG bei ({x},{y}) {bw}x{bh} Dichte-Delta {abw:.3f}")
    x, y, bw, bh = fundament_rahmen([(f[0], f[1], f[2], f[3]) for f in funde])
    print(f"Gesamt-Rahmen: ({x},{y}) {bw}x{bh} Zellen: {len(funde)}")
    return 1


if __name__ == "__main__":
    sys.exit(hauptprogramm())
