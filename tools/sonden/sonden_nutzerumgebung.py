# -*- coding: utf-8 -*-
"""Sonden Nutzerumgebung. Eigene Zuständigkeit: je Szenario-Lauf eine eigene,
leere Nutzerdaten-Ablage bereitstellen.

Ohne Isolation lädt jeder Lauf den Speicherstand des vorigen, die Welt wächst
von Mal zu Mal und keine Messung ist wiederholbar. Der Ablageort wird nur für
den Kindprozess gesetzt; die echten Spielstände bleiben unberührt.
"""

import os
import shutil


def umgebung_fuer(projekt_stamm, agent: str, szenario_id: str) -> dict:
    """Umgebungsvariablen des Kindprozesses mit eigener Nutzerdaten-Ablage."""
    ziel = projekt_stamm / ".sonden" / "nutzerdaten" / agent / szenario_id
    if ziel.exists():
        shutil.rmtree(ziel, ignore_errors=True)
    ziel.mkdir(parents=True, exist_ok=True)
    umgebung = os.environ.copy()
    if os.name == "nt":
        umgebung["APPDATA"] = str(ziel)
    else:
        umgebung["XDG_DATA_HOME"] = str(ziel)
        umgebung["HOME"] = str(ziel)
    return umgebung
