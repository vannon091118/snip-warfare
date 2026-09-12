# -*- coding: utf-8 -*-
"""Prüfkategorie pfade (E015): alle res://-Einträge müssen relativ und
existent sein, in GDScript, Szenen und JSON."""

import re

from .kern import PROJEKT_STAMM, _verzeichnis_ignoriert, fehler, zeile_bei

PFAD_ZIEL_ENDUNGEN = (".svg", ".png", ".json", ".tscn", ".gd", ".ogg",
                      ".wav", ".mp3", ".ttf", ".otf", ".tres")


def pruefe_pfade(dateien):
    for pfad, code in dateien:
        rel_pfad = pfad.relative_to(PROJEKT_STAMM)
        # ASCII-Pflicht: Der Moebel-Umlaut-Fehler (NFC gegen NFD) zeigte,
        # dass nicht-ASCII-Dateinamen bei Zip-, Git- und OS-Uebergaben
        # still auseinanderfallen. Projektpfade bleiben daher rein ASCII.
        if not str(rel_pfad).isascii():
            fehler("E015", rel_pfad, 1,
                   "Dateipfad enthaelt nicht-ASCII-Zeichen; Namen ohne Umlaute fuehren (res-Regel)")
    for treffer in re.finditer(r'"(res://[^"]+)"', code):
        # Format-Platzhalter wie %s sind Schablonen, keine wirklichen Pfade;
        # sie werden als Anker geprueft, nicht als Datei auf der Festplatte.
        if "%s" in treffer.group(1) or "%d" in treffer.group(1):
            continue
        _pruefe_res_pfad(treffer.group(1), rel_pfad, code, treffer.start())
    for tscn_pfad in sorted(p for p in PROJEKT_STAMM.rglob("*.tscn") if not _verzeichnis_ignoriert(p)):
        rel_pfad = tscn_pfad.relative_to(PROJEKT_STAMM)
        try:
            inhalt = tscn_pfad.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            fehler("E005", rel_pfad, 1, "Szenendatei ist nicht als UTF-8 lesbar")
            continue
        for treffer in re.finditer(r'path="(res://[^"]+)"', inhalt):
            _pruefe_res_pfad(treffer.group(1), rel_pfad, inhalt, treffer.start())
    for json_pfad in sorted(p for p in PROJEKT_STAMM.rglob("*.json") if not _verzeichnis_ignoriert(p)):
        if ".godot" in json_pfad.parts:
            continue
        rel_pfad = json_pfad.relative_to(PROJEKT_STAMM)
        try:
            inhalt = json_pfad.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for treffer in re.finditer(r'"([^"]*\.(?:svg|png|json|tscn|ogg|wav))"', inhalt):
            wert = treffer.group(1)
            if wert.startswith("res://"):
                _pruefe_res_pfad(wert, rel_pfad, inhalt, treffer.start())
            else:
                fehler("E015", rel_pfad, zeile_bei(inhalt, treffer.start()),
                       "Pfad-Eintrag '%s' ist nicht projektrelativ im Format res://" % wert)


def _pruefe_res_pfad(pfad_angabe, rel_pfad, code, position):
    zeile = zeile_bei(code, position)
    if not pfad_angabe.startswith("res://"):
        fehler("E015", rel_pfad, zeile,
               "Pfad-Eintrag '%s' ist nicht projektrelativ im Format res://" % pfad_angabe)
        return
    relativ = pfad_angabe[len("res://"):]
    if not relativ.isascii():
        fehler("E015", rel_pfad, zeile,
               "Pfad-Eintrag '%s' enthaelt nicht-ASCII-Zeichen; Namen ohne Umlaute fuehren (res-Regel)" % pfad_angabe)
    ziel = PROJEKT_STAMM / relativ
    if not ziel.is_file():
        fehler("E015", rel_pfad, zeile,
               "Pfad-Eintrag '%s' existiert nicht" % pfad_angabe)
