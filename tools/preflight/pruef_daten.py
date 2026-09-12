# -*- coding: utf-8 -*-
"""Prüfkategorie daten (E005, E011): UTF-8-Lesbarkeit und Dateninventar.
Die E005-Prüfung läuft bereits beim Datei-Sammeln; hier steht die Ausgabe."""

import re

from .kern import PROJEKT_STAMM, zeile_bei, klassen_name_lesen


def gib_dateninventar_aus(dateien):
    print("=" * 78)
    print("DATENINVENTAR (exakte Namen der erzeugten Datenobjekte je Datei)")
    print("=" * 78)
    daten_praefixe = ("Objekt_", "Ressource_", "Tier_")
    gefunden = False
    for pfad, code in dateien:
        rel_pfad = pfad.relative_to(PROJEKT_STAMM)
        erzeugungen = []
        for treffer in re.finditer(r"\b([A-Z][A-Za-z_][A-Za-z0-9_]*)\.new\(\)", code):
            if treffer.group(1).startswith(daten_praefixe):
                erzeugungen.append((treffer.group(1), zeile_bei(code, treffer.start())))
        if not erzeugungen:
            continue
        gefunden = True
        name = klassen_name_lesen(code) or "-"
        print("%s (Klasse %s):" % (rel_pfad, name))
        for klasse, zeile in erzeugungen:
            print("    Zeile %4d: %s.new()  ->  Datenobjekt %s" % (zeile, klasse, klasse))
    if not gefunden:
        print("keine Datenobjekt-Erzeugungen gefunden")
    print("=" * 78)
