# -*- coding: utf-8 -*-
"""Prüfkategorie godot (E016-E018): Fassade über echte Teil-Domänen."""

import shutil
import subprocess
from pathlib import Path

from .godot_aufloeser import GODOT_EXTERN_FALLBACK, GODOT_FEHLER_MUSTER, aufloese_godot
from .godot_uebersetzer import uebersetze_fundzeilen
from .godot_warteschlange import belege_godot_ticket, freigeben_godot_ticket
from .kern import PROJEKT_STAMM, fehler
from .lauf_log_bruecke import lade_lauf_log


def godot_lauf(godot_befehl: str) -> None:
    aufgeloest = aufloese_godot(godot_befehl)
    if aufgeloest is None:
        fehler("E018", "godot", 0, "Godot nicht gefunden (fail-closed); Fallback: %s" % GODOT_EXTERN_FALLBACK)
        return
    if aufgeloest != "godot" and not Path(aufgeloest).is_file() and shutil.which(aufgeloest) is None:
        fehler("E018", "godot", 0, "Godot '%s' nicht gefunden; --godot-befehl pruefen" % aufgeloest)
        return
    if shutil.which(aufgeloest) is None and not Path(aufgeloest).is_file():
        fehler("E018", "godot", 0, "Godot '%s' nicht gefunden; --godot-befehl verwenden" % aufgeloest)
        return
    ticket = belege_godot_ticket()
    befehl = [aufgeloest, "--headless", "--path", str(PROJEKT_STAMM), "--quit-after", "120"]
    try:
        ergebnis = subprocess.run(befehl, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=300)
    except subprocess.TimeoutExpired:
        try:
            from tools.warteschlange.watcher_kern import kill_orphans_fenster
            kill_orphans_fenster()
        except Exception:
            try:
                subprocess.run(["taskkill", "/F", "/IM", "godot_console.exe"], capture_output=True, timeout=5)
            except Exception:
                pass
        fehler("E018", "godot", 0, "Godot Timeout 300s (fail-closed, gekillt)")
        freigeben_godot_ticket(ticket)
        return
    finally:
        freigeben_godot_ticket(ticket)
    ausgabe = (ergebnis.stdout or "") + (ergebnis.stderr or "")
    roh_zeilen = ausgabe.splitlines()
    try:
        lauf_log = lade_lauf_log()
        lauf_log.schreibe("godot_letzter_lauf", "Godot Headless (%s)" % aufgeloest, roh_zeilen)
    except Exception as e:
        fehler("E018", "godot", 0, "Lauf-Log nicht schreibbar: %s" % e)
        return
    fundzeilen = []
    for zeile in roh_zeilen:
        z = zeile.strip()
        if any(m in z for m in GODOT_FEHLER_MUSTER):
            if z not in fundzeilen:
                fundzeilen.append(z)
    uebersetze_fundzeilen(fundzeilen, lauf_log)
