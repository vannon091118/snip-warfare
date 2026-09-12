# -*- coding: utf-8 -*-
"""Prüfkategorie determinismus (E012, E013, E014, E019): Kein wilder Zufall,
keine Zeit-Seeds, Mutationsschemata mit Startzustand und Matrix-Zuordnung."""

import re

from .kern import (PROJEKT_STAMM, ERLAUBTE_ZUFALLS_KLASSEN, ZUFALLS_MUSTER,
                   ZEIT_SEED_MUSTER, ZWEITER_RNG_MUSTER,
                   fehler, zeile_von, zeile_bei, klassen_name_lesen)


def _sammle_zufallsfundstellen(code, klasse):
    if klasse in ERLAUBTE_ZUFALLS_KLASSEN:
        return []
    return list(ZUFALLS_MUSTER.finditer(code))


def _matrix_zuordnung_aus_code(code):
    zuordnung = {}
    muster = re.compile(
        r'"([^"\n]+)"\s*:\s*\n\s*return\s+([A-Za-z_][A-Za-z0-9_]*)\.new\(\)')
    for treffer in muster.finditer(code):
        zuordnung[treffer.group(1)] = treffer.group(2)
    return zuordnung


def pruefe_determinismus(dateien):
    for pfad, code in dateien:
        rel_pfad = pfad.relative_to(PROJEKT_STAMM)
        normalisiert = str(rel_pfad).replace("\\", "/")
        name = klassen_name_lesen(code) or ""
        for treffer in _sammle_zufallsfundstellen(code, name):
            fehler("E012", rel_pfad, zeile_bei(code, treffer.start()),
                   "Verbotener Zufallsaufruf '%s' in '%s'; Zufall läuft nur in "
                   "Kern_Zufall innerhalb einer Mutation und wird als Zustand "
                   "festgehalten" % (treffer.group(0).strip(), name or rel_pfad))
        for treffer in ZEIT_SEED_MUSTER.finditer(code):
            fehler("E012", rel_pfad, zeile_bei(code, treffer.start()),
                   "Zeitbasierte Seedquelle '%s' in '%s'; Seed kommt ausschließlich aus Weltzustand und Kern_Zufall, keine Zeitquelle" %
                   (treffer.group(0).strip(), name or rel_pfad))
        for treffer in ZWEITER_RNG_MUSTER.finditer(code):
            if name in ERLAUBTE_ZUFALLS_KLASSEN:
                continue
            # RandomNumberGenerator ist immer eine zweite Zufallswelt.
            if "RandomNumberGenerator" in treffer.group(0):
                fehler("E012", rel_pfad, zeile_bei(code, treffer.start()),
                       "Zweite Zufallsquelle '%s' in '%s'; nur Kern_Zufall ist erlaubt" %
                       (treffer.group(0).strip(), name or rel_pfad))
        if "extends Kern_Mutationsschema" in code:
            if "start_zustand" not in code:
                fehler("E014", rel_pfad, zeile_von(code, "class_name"),
                       "Mutationsschema '%s' legt keine Startzustände fest; ohne "
                       "Startzustand läuft keine Mutation" % name)
            pruefe_matrix_zuordnung(pfad, rel_pfad, code, name)


def pruefe_matrix_zuordnung(pfad, rel_pfad, code, schema_name):
    matrix_pfad_treffer = re.search(r'MATRIX_PFAD\s:?=?\s*"res://([^"]+)"', code)
    if matrix_pfad_treffer is None:
        return
    matrix_datei = PROJEKT_STAMM / matrix_pfad_treffer.group(1)
    if not matrix_datei.is_file():
        fehler("E019", rel_pfad, zeile_von(code, "MATRIX_PFAD"),
               "Mutationsmatrix '%s' fehlt auf der Festplatte" % matrix_pfad_treffer.group(1))
        return
    try:
        matrix_datei.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        fehler("E019", rel_pfad, zeile_von(code, "MATRIX_PFAD"),
               "Mutationsmatrix '%s' ist nicht als UTF-8 lesbar" % matrix_pfad_treffer.group(1))
        return
    zuordnung_in_code = _matrix_zuordnung_aus_code(code)
    klassen_im_ordner = set()
    for nachbar in pfad.parent.glob("*.gd"):
        try:
            klassen_im_ordner.add(klassen_name_lesen(nachbar.read_text(encoding="utf-8")))
        except OSError:
            continue
    klassen_im_ordner.discard(None)
    for mut_name, klasse in sorted(zuordnung_in_code.items()):
        if klasse not in klassen_im_ordner:
            fehler("E013", rel_pfad, zeile_von(code, '"%s"' % mut_name),
                   "Schema '%s': Mutation '%s' ist der Klasse '%s' zugeordnet, "
                   "aber es gibt keine solche Mutations-Klasse im selben Ordner" %
                   (schema_name, mut_name, klasse))
