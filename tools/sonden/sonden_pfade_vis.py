# -*- coding: utf-8 -*-
"""Sonden Pfade Vis. Eigene Zuständigkeit: Die Pfade der visuellen
Sonden-Welt — der Werkzeug-Stamm und die Reihen-Referenz-Datei. Genau
eine Klasse besitzt diese Konstanten; alle anderen importieren sie."""

from pathlib import Path

from tools.preflight.kern import PROJEKT_STAMM

VIS_STAMM = PROJEKT_STAMM / ".local_dev" / "vis_tools"
REIHEN_REFERENZ = VIS_STAMM / "reihen_referenz.json"
REFERENZ_LAYOUT = VIS_STAMM / "referenz_layout.png"
KONTAKTBOGEN = VIS_STAMM / "frames" / "kontaktbogen.png"
