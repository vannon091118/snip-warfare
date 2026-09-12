# -*- coding: utf-8 -*-
"""Einstieg der Index-Familie: erzeugt Root-, Domaenen- und Datenindex.

Diese Datei ist bewusst eine duenne Schale. Die Inhalte liegen in tools/index/
und tragen dort je eine eigene Zustaendigkeit: kern, inventar, matrix, daten,
root_index, domaenen_index, daten_index, letzte_aenderung und erzeugen.

    python tools/index_generieren.py

Der Lauf ist idempotent: Ohne Aenderung am Code bleibt jede Datei unberuehrt,
und die eine Last-Datei meldet dann keine Aenderung.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from index.erzeugen import neu_erzeugen


def hauptprogramm():
    """Erzeugt die Index-Familie und meldet, was geschrieben wurde."""
    neu_erzeugen()
    return 0


if __name__ == "__main__":
    raise SystemExit(hauptprogramm())
