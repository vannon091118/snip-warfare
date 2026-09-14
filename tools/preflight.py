# -*- coding: utf-8 -*-
"""Preflight: Dünner Aufrufer über Pipeline und echte Domänen."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from preflight.cli_argumente import baue_parser, normalisiere_kategorien
from preflight.kategorie_register import PRUEFKATEGORIEN
from preflight.kern import FEHLER, klassen_name_lesen, lies_dateien
from preflight.lauf_beweis import lauf_beweis_mit_retry
from preflight.pipeline import phasen_fuer_gewaehlt
from preflight.preflight_helfer import hilfe_debug_uebersetzer
from preflight.preflight_protokoll import schreibe_scope_log
from preflight.pruef_daten import gib_dateninventar_aus
from preflight.pruef_shinon import pruefe_shinon
from preflight.selbsttest import selbsttest
from preflight.statik_laeufer import statik_laufen

ALLE_KLASSEN: set[str] = set()


def hauptprogramm() -> int:
    global ALLE_KLASSEN
    parser = baue_parser(set(PRUEFKATEGORIEN.keys()))
    argumente = parser.parse_args()
    normalisiere_kategorien(argumente)
    if argumente.fix and "whitespace" not in {k.lower() for k in argumente.kategorie}:
        print("E000: --fix nur mit --kategorie whitespace")
        return 2
    if argumente.fix:
        from preflight.pruef_whitespace import fix_dateien
        print(f"E042 --fix: {fix_dateien()} bereinigt")
    if argumente.hilfe_fehler:
        return hilfe_debug_uebersetzer()
    unbekannt = [k for k in argumente.kategorie if k.lower() not in PRUEFKATEGORIEN]
    if unbekannt:
        print("E000: unbekannt: %s; erlaubt: %s" % (", ".join(unbekannt), ", ".join(sorted(PRUEFKATEGORIEN))))
        return 2
    gewaehlt = {k.lower() for k in argumente.kategorie} or set(PRUEFKATEGORIEN)
    aktive = {c for k in gewaehlt for c in PRUEFKATEGORIEN[k]}
    phasen = phasen_fuer_gewaehlt(gewaehlt)
    print(f"Prüfkategorien: {', '.join(sorted(gewaehlt))} | Phasen: {' -> '.join(phasen)}")
    probleme = selbsttest()
    if probleme:
        print("E000: Selbsttest fehlgeschlagen:")
        for p in probleme:
            print(f"  - {p}")
        return 2
    print("E000: Selbsttest bestanden")
    dateien = lies_dateien()
    ALLE_KLASSEN = {klassen_name_lesen(c) for _, c in dateien}
    ALLE_KLASSEN.discard(None)
    import preflight.pruef_trennung as trennung_modul
    trennung_modul.ALLE_KLASSEN = ALLE_KLASSEN  # type: ignore
    if any(p in phasen for p in ("statik",)):
        statik_laufen(gewaehlt, dateien)
    if argumente.sonden_snap:
        try:
            from preflight.pruef_sonden import sonden_snap
            sonden_snap()
            print("Sonden-Snap: Baseline gespeichert")
        except Exception as e:
            from preflight.kern import fehler
            fehler("E028", ".sonden/snaps", 0, f"Snap fehlgeschlagen: {e}")
    lauf_beweis_mit_retry(argumente, gewaehlt, phasen)
    if "gate" in phasen and "shinon" in gewaehlt:
        pruefe_shinon()
    if "daten" in gewaehlt:
        gib_dateninventar_aus(dateien)
    gefiltert = [e for e in FEHLER if e[0] in aktive]
    print(f"Klassen gesamt: {len(ALLE_KLASSEN)}; GDScript-Dateien: {len(dateien)}")
    if "shinon" in gewaehlt and any(e[0].startswith("E03") for e in gefiltert):
        print("SHINON GATE: blockiert")
    gefiltert = schreibe_scope_log(gewaehlt, argumente, gefiltert, dateien, len(ALLE_KLASSEN))
    if gefiltert:
        print(f"BEFUNDE ({len(gefiltert)}):")
        for code, datei, zeile, text in sorted(gefiltert):
            print(f"  {code} | {datei}:{zeile} | {text}")
        return 1
    print("PREFLIGHT OK")
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(hauptprogramm())
