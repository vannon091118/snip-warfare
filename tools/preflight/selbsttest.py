# -*- coding: utf-8 -*-
"""E000 Selbsttest: Die Kernprüfungen werden gegen bekannte Beispiele
ausgeführt; weicht ein Ergebnis ab, ist der Preflight selbst unbrauchbar."""

import importlib.util
import sys

from .kern import PROJEKT_STAMM, ERLAUBTE_ZUFALLS_KLASSEN, ZUFALLS_MUSTER
from .pruef_determinismus import _sammle_zufallsfundstellen, _matrix_zuordnung_aus_code


def _lade_shinon_klasse(rel_pfad, modul_name, klassen_name):
    pfad = PROJEKT_STAMM / rel_pfad
    spez = importlib.util.spec_from_file_location(modul_name, str(pfad))
    modul = importlib.util.module_from_spec(spez)
    sys.modules[spez.name] = modul
    spez.loader.exec_module(modul)
    return getattr(modul, klassen_name)


def selbsttest():
    probleme = []
    probe_quelle = "extends RefCounted\nclass_name E000_Probe\nvar wert := randi()\n"
    if len(_sammle_zufallsfundstellen(probe_quelle, "E000_Probe")) != 1:
        probleme.append("Zufallsdetektor fand randi() in einer Fremdklasse nicht")
    kern_quelle = "extends RefCounted\nclass_name Kern_Zufall\nvar wert := randi()\n"
    if len(_sammle_zufallsfundstellen(kern_quelle, "Kern_Zufall")) != 0:
        probleme.append("Zufallsdetektor meldet erlaubte Aufrufe in Kern_Zufall")
    matrix_quelle = ('match str(eintrag.get("name", "")):\n'
                     '\t"TestA":\n'
                     '\t\treturn Probe_MutationA.new()\n'
                     '\t"TestB":\n'
                     '\t\treturn Probe_MutationB.new()\n')
    zuordnung = _matrix_zuordnung_aus_code(matrix_quelle)
    if zuordnung != {"TestA": "Probe_MutationA", "TestB": "Probe_MutationB"}:
        probleme.append("Matrix-Zuordnung wurde falsch ausgelesen: %r" % zuordnung)
    # Zufallsmuster aus dem Kern muss mit den Fundstellen übereinstimmen.
    if ZUFALLS_MUSTER.search(probe_quelle) is None:
        probleme.append("Zufallsmuster aus dem Kern findet randi() nicht")
    if "Kern_Zufall" not in ERLAUBTE_ZUFALLS_KLASSEN:
        probleme.append("Kern_Zufall fehlt in der Erlaubnisliste")
    # Shinon Gate Selbsttest: Banner, Bullet, Nummerierung und Bildsprache muessen sicher greifen.
    try:
        gate = _lade_shinon_klasse("shinon/shinon_gate.py", "_shinon_gate_selbsttest", "ShinonGate")()
        if not any(b.code == "E030" for b in gate.pruefe_text("1. Hallo Welt mit fuenf Woertern im Satz.\n===========\n")):
            probleme.append("Shinon Banner Pruefer meldet Banner nicht")
        if not any(b.code == "E031" for b in gate.pruefe_text("- Bullet mit genug Woertern im ganzen Satz.\n")):
            probleme.append("Shinon Bullet Pruefer meldet Bullet nicht")
        if not any(b.code == "E032" for b in gate.pruefe_text("Ohne Nummer aber mit genug Woertern im Satz.\n")):
            probleme.append("Shinon Nummerierung Pruefer meldet fehlende Nummer nicht")
        if not any(b.code == "E033" for b in gate.pruefe_text("1. Kurz.\n")):
            probleme.append("Shinon Bildsprache Pruefer meldet zu kurzen Satz nicht")
        if not any(b.code == "E037" for b in gate.pruefe_text("1. Fertige Arbeit und nun der Fuss.\n\U0001F916 Generated with Codebuff\nCo-Authored-By: Codebuff <noreply@codebuff.com>\n")):
            probleme.append("Shinon Footer Pruefer meldet den Agent-Footer nicht")
        endlos_text = "1. Der Nutzer wollte X und dann hat Shinon Y gemacht und dann wurde Z gebaut und dann kam noch W dazu und dann fehlte noch V und dann musste auch U her und dann war immer noch nicht Schluss und dann wurde alles noch einmal geprueft und dann war der Tag vorbei."
        if not any(b.code == "E039" for b in gate.pruefe_text(endlos_text + "\n")):
            probleme.append("Shinon Stil Pruefer meldet die Endlos-Aufzaehlung nicht")
        ReadmePruefer = _lade_shinon_klasse("shinon/shinon_readme_pruefer.py", "_shinon_readme_selbsttest", "ShinonReadmePruefer")
        if not ReadmePruefer().pruefen(PROJEKT_STAMM / "__shinon_probe_nicht_existent_readme__.md"):
            probleme.append("Shinon Readme Pruefer meldet fehlende Readme nicht")
        SteuerungPruefer = _lade_shinon_klasse("shinon/shinon_steuerung_pruefer.py", "_shinon_steuerung_selbsttest", "ShinonSteuerungPruefer")
        if not SteuerungPruefer().pruefen(PROJEKT_STAMM / "__shinon_probe_nicht_existent_steuerung__.json"):
            probleme.append("Shinon Steuerung Pruefer meldet fehlende Steuerung nicht")
    except Exception as lauf_fehler:
        probleme.append(f"Shinon Gate Selbsttest wirft Ausnahme: {lauf_fehler}")
    return probleme
