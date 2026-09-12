# -*- coding: utf-8 -*-
"""Prüfkategorie shinon (E030 bis E039): Root Gate shinon/commit_msg.txt
mechanisch, granular über die Shinon-Klassen."""

import importlib.util
import sys

from .kern import PROJEKT_STAMM, fehler


def _lade_modul(rel_pfad, modul_name):
    pfad = PROJEKT_STAMM / rel_pfad
    spez = importlib.util.spec_from_file_location(modul_name, str(pfad))
    modul = importlib.util.module_from_spec(spez)
    sys.modules[spez.name] = modul
    assert spez.loader is not None
    spez.loader.exec_module(modul)
    return modul


def pruefe_shinon():
    try:
        gate_modul = _lade_modul("shinon/shinon_gate.py", "_shinon_gate_lauf")
        ShinonGate = gate_modul.ShinonGate
    except Exception as lauf_fehler:
        fehler("E000", "shinon/shinon_gate.py", 1,
               f"Shinon Gate nicht importierbar: {lauf_fehler}")
        return
    gate = ShinonGate()
    for befund in gate.pruefen():
        fehler(befund.code, befund.datei, befund.zeile, befund.text)
    # E035 und E036 werden ebenfalls ueber das shinon Modul geprueft, granular je Klasse.
    try:
        readme_modul = _lade_modul("shinon/shinon_readme_pruefer.py", "_shinon_readme_lauf")
        for befund in readme_modul.ShinonReadmePruefer().pruefen():
            fehler(befund.code, befund.datei, befund.zeile, befund.text)
    except Exception as lauf_fehler:
        fehler("E000", "shinon/shinon_readme_pruefer.py", 1,
               f"Shinon Readme Pruefer nicht importierbar: {lauf_fehler}")
    try:
        steuerung_modul = _lade_modul("shinon/shinon_steuerung_pruefer.py", "_shinon_steuerung_lauf")
        for befund in steuerung_modul.ShinonSteuerungPruefer().pruefen():
            fehler(befund.code, befund.datei, befund.zeile, befund.text)
    except Exception as lauf_fehler:
        fehler("E000", "shinon/shinon_steuerung_pruefer.py", 1,
               f"Shinon Steuerung Pruefer nicht importierbar: {lauf_fehler}")
