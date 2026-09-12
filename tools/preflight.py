# -*- coding: utf-8 -*-
"""Preflight des Projekts: dünner Aufrufer über das granulare Paket
tools/preflight/. Je Prüfkategorie eine eigene Klasse in eigener Datei.

Verbindliche Regeltexte: Architektur.md. Kein Commit gilt als fertig,
solange dieser Preflight nicht vollständig grün ist.

Fehlercodes (Übersicht, Details in den Prüf-Modulen):
  E000  Preflight-Selbsttest fehlgeschlagen (keine False Truth)
  E001 bis E009   Naming, Präfix, Ordner, class_name, UTF-8, Trennung
  E010 bis E015   Array-Typen, Zufall, Matrix, Pfade
  E016 bis E018   Godot-Lauf
  E019 bis E022   Registries und Assets
  E023, E024      RT Pyramide und Biom Pflicht
  E025            Warnungs-Scan
  E030 bis E039   Shinon Gate
  E040            Datenparitaet
  E041            LOC-Regel: differenzierte Zeilen-Grenze je Datei-Suffix

Prüfkategorien (Flags):
  klassen        E001 E002 E003 E004 E008 E009 E021
  trennung       E006 E007 E010
  daten          E005 E011 E040
  datenparitaet  E040
  determinismus  E012 E013 E014 E019
  pfade          E015
  registries     E020 E022
  godot          E016 E017 E018 E025
  warnungen      E025
  shinon         E030 bis E039
  assets         E022
  pyramide       E023 E024
  biome          E024
  einheitlich    E023 E024
  welt           E012 E019 E023
  locregel       E041

Ausführung aus dem Projektstamm:
    python tools/preflight.py                            volle Abdeckung
    python tools/preflight.py --kategorie determinismus  nur ein Bereich
    python tools/preflight.py --kategorie klassen --kategorie pfade
    python tools/preflight.py --ohne-godot               ohne Engine-Lauf
    python tools/preflight.py --godot-befehl PFAD        anderer Godot-Pfad

Ohne Befunde endet das Skript mit Exit-Code 0, mit Befunden mit 1 und bei
unbrauchbarem Preflight (E000, unbekannte Flags) mit 2.
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from preflight.kern import (FEHLER, PROJEKT_STAMM, fehler, klassen_name_lesen,
                            lies_dateien)
from preflight.pruef_klassen import pruefe_klassen
from preflight.pruef_trennung import pruefe_trennung
from preflight.pruef_daten import gib_dateninventar_aus
from preflight.pruef_determinismus import pruefe_determinismus
from preflight.pruef_pfade import pruefe_pfade
from preflight.pruef_registries import pruefe_registries
from preflight.pruef_datenparitaet import pruefe_datenparitaet
from preflight.pruef_pyramide import pruefe_pyramide
from preflight.pruef_shinon import pruefe_shinon
from preflight.pruef_godot import godot_lauf
from preflight.pruef_warnungen import pruefe_warnungen
from preflight.pruef_locregel import pruefe_locregel
from preflight.pruef_whitespace import pruefe_whitespace
from preflight.selbsttest import selbsttest

PRUEFKATEGORIEN = {
    "klassen": ("E001", "E002", "E003", "E004", "E008", "E009", "E021"),
    "trennung": ("E006", "E007", "E010"),
    "daten": ("E005", "E011", "E040"),
    "datenparitaet": ("E040",),
    "determinismus": ("E012", "E013", "E014", "E019"),
    "pfade": ("E015",),
    "registries": ("E020", "E022"),
    "godot": ("E016", "E017", "E018", "E025"),
    "warnungen": ("E025",),
    "shinon": ("E030", "E031", "E032", "E033", "E034", "E035", "E036", "E037", "E038", "E039"),
    "assets": ("E022",),
    "pyramide": ("E023", "E024"),
    "biome": ("E024",),
    "einheitlich": ("E023", "E024"),
    "welt": ("E012", "E019", "E023"),
    "locregel": ("E041",),
    "whitespace": ("E042",),
}

ALLE_KLASSEN = set()


def hauptprogramm():
    global ALLE_KLASSEN
    parser = argparse.ArgumentParser(description="Preflight des Projekts")
    parser.add_argument("--kategorie", action="append", default=[],
                        help="nur diese Prüfkategorie ausführen (%s)" %
                             ", ".join(sorted(PRUEFKATEGORIEN)))
    parser.add_argument("--ohne-godot", action="store_true",
                        help="Godot-Lauf überspringen")
    parser.add_argument("--godot-befehl", default="godot",
                        help="Befehl oder Pfad der Godot-Engine")
    parser.add_argument("--fix", action="store_true",
                        help="Whitespace-Maengel (E042) automatisch reparieren (nur mit --kategorie whitespace)")
    parser.add_argument("--hilfe-fehler", action="store_true",
                        help="Zeigt die Zuordnung Godot Zeile zu E016/E017/E018")
    argumente = parser.parse_args()
    if argumente.fix and "whitespace" not in {k.lower() for k in argumente.kategorie}:
        print("E000: --fix ist nur mit --kategorie whitespace erlaubt")
        return 2
    if argumente.fix:
        from preflight.pruef_whitespace import fix_dateien
        anzahl = fix_dateien()
        print(f"E042 --fix: {anzahl} Dateien bereinigt")

    if argumente.hilfe_fehler:
        return _hilfe_debug_uebersetzer()

    unbekannt = [k for k in argumente.kategorie if k.lower() not in PRUEFKATEGORIEN]
    if unbekannt:
        print("E000: unbekannte Prüfkategorie(n): %s; erlaubt: %s" %
              (", ".join(unbekannt), ", ".join(sorted(PRUEFKATEGORIEN))))
        return 2
    gewaehlt = {k.lower() for k in argumente.kategorie} or set(PRUEFKATEGORIEN)
    aktive_codes = {code for kategorie in gewaehlt
                    for code in PRUEFKATEGORIEN[kategorie]}
    godot_aktiv = "godot" in gewaehlt and not argumente.ohne_godot

    print("Prüfkategorien: %s" % ", ".join(sorted(gewaehlt)))
    probleme = selbsttest()
    if probleme:
        print("E000: Preflight-Selbsttest fehlgeschlagen:")
        for problem in probleme:
            print("  - %s" % problem)
        return 2
    print("E000: Selbsttest bestanden (keine False Truth)")

    dateien = lies_dateien()
    ALLE_KLASSEN = {klassen_name_lesen(code) for _, code in dateien}
    ALLE_KLASSEN.discard(None)
    # Die Trennungs-Prüfung kennt alle Klassen für die Array-Typen-Prüfung.
    import preflight.pruef_trennung as trennung_modul
    trennung_modul.ALLE_KLASSEN = ALLE_KLASSEN

    if "klassen" in gewaehlt:
        pruefe_klassen(dateien)
    if "trennung" in gewaehlt:
        pruefe_trennung(dateien)
    if "determinismus" in gewaehlt:
        pruefe_determinismus(dateien)
    if "pfade" in gewaehlt:
        pruefe_pfade(dateien)
    if "registries" in gewaehlt:
        pruefe_registries(dateien)
    if "warnungen" in gewaehlt or "godot" in gewaehlt:
        pruefe_warnungen(dateien)
    if "shinon" in gewaehlt:
        pruefe_shinon()
    if "pyramide" in gewaehlt or "biome" in gewaehlt or "einheitlich" in gewaehlt:
        pruefe_pyramide(dateien)
    if "daten" in gewaehlt or "datenparitaet" in gewaehlt:
        pruefe_datenparitaet(dateien)
    if "locregel" in gewaehlt:
        pruefe_locregel(dateien)
    if "whitespace" in gewaehlt:
        pruefe_whitespace(dateien)
    if godot_aktiv:
        godot_lauf(argumente.godot_befehl)

    if "daten" in gewaehlt:
        gib_dateninventar_aus(dateien)

    gefiltert = [eintrag for eintrag in FEHLER if eintrag[0] in aktive_codes]
    print("Klassen gesamt: %d; GDScript-Dateien: %d" % (len(ALLE_KLASSEN), len(dateien)))
    if "shinon" in gewaehlt and any(eintrag[0].startswith("E03") for eintrag in gefiltert):
        print("SHINON GATE: blockiert — shinon/commit_msg.txt verletzt E030 bis E034.")
        print("Regel: Ganze nummerierte bildliche Saetze ohne Banner und ohne Bullet. Siehe AGENTS.md Regel 5.")
    gefiltert = _schreibe_scope_log(gewaehlt, argumente, gefiltert, dateien)
    if gefiltert:
        print("BEFUNDE (%d):" % len(gefiltert))
        for code, datei, zeile, text in sorted(gefiltert):
            print("  %s | %s:%s | %s" % (code, datei, zeile, text))
        return 1
    print("PREFLIGHT OK: keine Befunde in den gewählten Kategorien")
    return 0


def _schreibe_scope_log(gewaehlt, argumente, gefiltert, dateien):
    """Scope-Log: Jede Kategorien-Auswahl schreibt ihr eigenes Log."""
    try:
        from preflight.kern import _lade_lauf_log
        lauf_log = _lade_lauf_log()
        scope_name = "+" + "+".join(sorted(gewaehlt)) if argumente.kategorie else "voll"
        ergebnis_zeilen = [
            "Pruefkategorien: %s" % ", ".join(sorted(gewaehlt)),
            "Klassen gesamt: %d; GDScript-Dateien: %d" % (len(ALLE_KLASSEN), len(dateien)),
            "Befunde: %d" % len(gefiltert),
        ]
        for code, datei, zeile, text in sorted(gefiltert):
            ergebnis_zeilen.append("%s | %s:%s | %s" % (code, datei, zeile, text))
        log_pfad = lauf_log.schreibe("preflight_letzter_lauf", "Scope %s" % scope_name, ergebnis_zeilen)
        print("Lauf-Log: %s" % log_pfad.relative_to(PROJEKT_STAMM))
    except Exception as log_fehler:
        # Fail-closed: Ein nicht schreibbares Log ist selbst ein Befund.
        fehler("E018", "tools/logs", 0, "Scope-Log nicht schreibbar: %s" % log_fehler)
        gefiltert = [eintrag for eintrag in FEHLER if eintrag[0] in aktive_codes_gewaehlt(gewaehlt)]
    return gefiltert


def aktive_codes_gewaehlt(gewaehlt):
    return {code for kategorie in gewaehlt for code in PRUEFKATEGORIEN[kategorie]}


def _hilfe_debug_uebersetzer():
    try:
        import importlib.util as _ilu_h
        import sys as _sys_h
        _h_pfad = PROJEKT_STAMM / "tools" / "debug_uebersetzer.py"
        _h_spez = _ilu_h.spec_from_file_location("_debug_hilfe", str(_h_pfad))
        _h_mod = _ilu_h.module_from_spec(_h_spez)
        _sys_h.modules[_h_spez.name] = _h_mod
        assert _h_spez.loader is not None
        _h_spez.loader.exec_module(_h_mod)
        print("Godot Debugging Uebersetzer (E016 Parse, E017 unbekannte Definition, E018 Warning/Hidden):")
        for muster, code, hinweis in _h_mod.DebugUebersetzer.MUSTER:
            print(f"  {code} | {muster.pattern[:70]:70} | {hinweis}")
    except Exception as hf:
        print(f"Hilfe nicht ladbar: {hf}")
    return 0


if __name__ == "__main__":
    sys.exit(hauptprogramm())
