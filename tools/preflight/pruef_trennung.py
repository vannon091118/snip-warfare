# -*- coding: utf-8 -*-
"""Prüfkategorie trennung (E006, E007, E010): Daten-/Logik-Markierung und
bekannte Array-Elementtypen."""

import re

from .kern import PROJEKT_STAMM, ARRAY_BASISTYPEN, fehler, zeile_bei, klassen_name_lesen

# ALLE_KLASSEN wird vom Hauptprogramm gesetzt, bevor die Prüfung läuft.
ALLE_KLASSEN = set()


def pruefe_trennung(dateien):
    for pfad, code in dateien:
        rel_pfad = pfad.relative_to(PROJEKT_STAMM)
        name = klassen_name_lesen(code) or str(rel_pfad)
        hat_arrays = re.search(r"^var\s+\w+\s*:\s*Array\[", code, re.M) is not None
        if not hat_arrays:
            continue
        if "## Kategorie daten" not in code:
            fehler("E006", rel_pfad, 1,
                   "Klasse '%s' enthält Daten-Arrays, markiert die Trennung " % name +
                   "aber nicht mit '## Kategorie daten'")
        if "## Kategorie logik" not in code:
            fehler("E007", rel_pfad, 1,
                   "Klasse '%s' enthält Daten-Arrays, markiert die logische " % name +
                   "Seite aber nicht mit '## Kategorie logik'")
        for treffer in re.finditer(r":\s*Array\[([A-Za-z_][A-Za-z0-9_]*)\]", code):
            element_typ = treffer.group(1)
            if element_typ in ARRAY_BASISTYPEN:
                continue
            if element_typ not in ALLE_KLASSEN:
                fehler("E010", rel_pfad, zeile_bei(code, treffer.start()),
                       "Array-Typ '%s' ist keine bekannte Datenklasse" % element_typ)
