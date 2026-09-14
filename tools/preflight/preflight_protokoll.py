# -*- coding: utf-8 -*-
"""Preflight Protokoll. Eigene Zuständigkeit: Scope-Log schreiben."""

from .kern import PROJEKT_STAMM, FEHLER, fehler


def schreibe_scope_log(gewaehlt, argumente, gefiltert, dateien, klassen_zahl: int):
    try:
        from .kern import _lade_lauf_log
        lauf_log = _lade_lauf_log()
        scope_name = "+" + "+".join(sorted(gewaehlt)) if argumente.kategorie else "voll"
        zeilen = [f"Pruefkategorien: {', '.join(sorted(gewaehlt))}", f"Klassen gesamt: {klassen_zahl}; GDScript-Dateien: {len(dateien)}", f"Befunde: {len(gefiltert)}"]
        for code, datei, zeile, text in sorted(gefiltert):
            zeilen.append(f"{code} | {datei}:{zeile} | {text}")
        log_pfad = lauf_log.schreibe("preflight_letzter_lauf", f"Scope {scope_name}", zeilen)
        print(f"Lauf-Log: {log_pfad.relative_to(PROJEKT_STAMM)}")
    except Exception as log_fehler:
        fehler("E018", "tools/logs", 0, f"Scope-Log nicht schreibbar: {log_fehler}")
        from .preflight_helfer import aktive_codes_gewaehlt as _acg
        gefiltert = [e for e in FEHLER if e[0] in _acg(gewaehlt)]
    return gefiltert
