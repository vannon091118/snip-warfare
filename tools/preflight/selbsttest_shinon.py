# -*- coding: utf-8 -*-
"""Selbsttest Shinon. Eigene Zuständigkeit: Der Shinon-Anteil des E000."""

import importlib.util
import sys

from .kern import PROJEKT_STAMM


def _lade_shinon_klasse(rel_pfad, modul_name, klassen_name):
    pfad = PROJEKT_STAMM / rel_pfad
    spez = importlib.util.spec_from_file_location(modul_name, str(pfad))
    modul = importlib.util.module_from_spec(spez)
    sys.modules[spez.name] = modul
    assert spez.loader is not None
    spez.loader.exec_module(modul)
    return getattr(modul, klassen_name)


def pruefe(probleme: list[str]) -> None:
    try:
        gate = _lade_shinon_klasse("shinon/shinon_gate.py", "_shinon_gate_selbsttest", "ShinonGate")()
        if not any(b.code == "E030" for b in gate.pruefe_text("1. Hallo Welt mit fuenf Woertern im Satz.\n===========\n")):
            probleme.append("Shinon Banner nicht gemeldet")
        if not any(b.code == "E031" for b in gate.pruefe_text("- Bullet mit genug Woertern im Satz.\n")):
            probleme.append("Shinon Bullet nicht gemeldet")
        if not any(b.code == "E032" for b in gate.pruefe_text("Ohne Nummer aber mit genug Woertern im Satz.\n")):
            probleme.append("Shinon Nummerierung nicht gemeldet")
        if not any(b.code == "E033" for b in gate.pruefe_text("1. Kurz.\n")):
            probleme.append("Shinon Bildsprache nicht gemeldet")
        if not any(b.code == "E037" for b in gate.pruefe_text("1. Fertige Arbeit und nun der Fuss.\n\U0001F916 Generated with Codebuff\nCo-Authored-By: Codebuff <noreply@codebuff.com>\n")):
            probleme.append("Shinon Footer nicht gemeldet")
        endlos = "1. Der Nutzer wollte X und dann hat Shinon Y gemacht und dann wurde Z gebaut und dann kam noch W dazu und dann fehlte noch V und dann musste auch U her und dann war immer noch nicht Schluss und dann wurde alles noch einmal geprueft und dann war der Tag vorbei."
        if not any(b.code == "E039" for b in gate.pruefe_text(endlos + "\n")):
            probleme.append("Shinon Stil nicht gemeldet")
        ReadmePruefer = _lade_shinon_klasse("shinon/shinon_readme_pruefer.py", "_shinon_readme_selbsttest", "ShinonReadmePruefer")
        if not ReadmePruefer().pruefen(PROJEKT_STAMM / "__shinon_probe_nicht_existent_readme__.md"):
            probleme.append("Shinon Readme nicht gemeldet")
        SteuerungPruefer = _lade_shinon_klasse("shinon/shinon_steuerung_pruefer.py", "_shinon_steuerung_selbsttest", "ShinonSteuerungPruefer")
        if not SteuerungPruefer().pruefen(PROJEKT_STAMM / "__shinon_probe_nicht_existent_steuerung__.json"):
            probleme.append("Shinon Steuerung nicht gemeldet")
    except Exception as e:
        probleme.append(f"Shinon Selbsttest Ausnahme: {e}")
