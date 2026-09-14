# -*- coding: utf-8 -*-
"""Sonden Läufer. Eigene Zuständigkeit: Ein Szenario ausführen und bewerten.

Kennt Fenster nur über die Warteschlange, kennt Godot nur über den Aufloeser.
Schreibt Scope-Log und Signatur, meldet E026-E029 über den Fehler-Funnel.
"""

import subprocess
from pathlib import Path
import json

from tools.sonden.sonden_nutzerumgebung import umgebung_fuer

from tools.preflight.godot_aufloeser import aufloese_godot
from tools.preflight.kern import fehler
from tools.preflight.lauf_log_bruecke import lade_lauf_log

from tools.sonden.sonden_pfade import PROJEKT_STAMM, signatur_pfad
from tools.sonden.sonden_vertrag import SONDE_FUND_MUSTER


def _validiere_szenario(pfad: Path) -> list[str]:
    from tools.sonden.sonden_szenario_validierer import validiere_szenario
    return validiere_szenario(pfad)


def laufe_szenario(pfad: Path, godot_befehl: str, agent: str, schnell: bool) -> tuple[bool, list[str]]:
    # Pfad robust gegen Lauf aus beliebigem CWD — immer relativ zum Projekt-Stamm
    if not pfad.is_absolute():
        pfad = (PROJEKT_STAMM / pfad).resolve() if not (PROJEKT_STAMM / pfad).exists() else PROJEKT_STAMM / pfad
    data = json.loads(pfad.read_text(encoding="utf-8"))
    sid = str(data["id"])
    modus = str(data.get("modus", "headless"))
    gd = PROJEKT_STAMM / "tools" / "sonden" / ("lauf_sonde_headless.gd" if modus == "headless" else "lauf_sonde_fenster.gd")
    if not gd.is_file():
        fehler("E026", pfad.relative_to(PROJEKT_STAMM) if pfad.is_relative_to(PROJEKT_STAMM) else pfad, 1, f"Laeufer fehlt: {gd.relative_to(PROJEKT_STAMM)}")
        return False, [f"E026 {sid}: Laeufer fehlt"]
    godot_bin = aufloese_godot(godot_befehl)
    if godot_bin is None:
        fehler("E026", pfad.relative_to(PROJEKT_STAMM) if pfad.is_relative_to(PROJEKT_STAMM) else pfad, 1, "Godot nicht gefunden (fail-closed)")
        return False, [f"E026 {sid}: Godot nicht gefunden"]
    fenster_ticket = None
    if modus == "fenster":
        try:
            from tools.warteschlange.watcher_kern import belege, formatiere_position, position_fuer
            fenster_ticket, pos = belege("sonden_fenster")
            print(formatiere_position(pos))
            if not pos.ist_aktiv:
                import time
                while True:
                    time.sleep(5)
                    npos = position_fuer("sonden_fenster", fenster_ticket.name)
                    if npos is None:
                        fehler("E026", pfad.relative_to(PROJEKT_STAMM) if pfad.is_relative_to(PROJEKT_STAMM) else pfad, 1, "Warteschlange Ticket verschwunden")
                        break
                    print(formatiere_position(npos))
                    if npos.ist_aktiv:
                        break
        except Exception as e:
            print(f"WARTESCHLANGE sonden_fenster nicht verfuegbar: {e}")
            fenster_ticket = None
    headless_flag = ["--headless"] if modus == "headless" else []
    prev_png = PROJEKT_STAMM / "tools" / "logs" / "sonden_bilder" / agent / f"{sid}.png"
    ab_heiz = f"--ab-heiz={prev_png}" if modus == "fenster" and prev_png.is_file() else ""
    befehl = [str(godot_bin), "--path", str(PROJEKT_STAMM)] + headless_flag + [
        "--script", str(gd.relative_to(PROJEKT_STAMM)), "--", f"--szenario={pfad.relative_to(PROJEKT_STAMM) if pfad.is_relative_to(PROJEKT_STAMM) else pfad}", f"--agent={agent}", f"--signatur={signatur_pfad(sid, agent)}",
    ]
    if ab_heiz:
        befehl.append(ab_heiz)
    if schnell:
        befehl.append("--schnell")
    try:
        erg = subprocess.run(befehl, capture_output=True, text=True, encoding="utf-8",
                             errors="replace", timeout=120,
                             env=umgebung_fuer(PROJEKT_STAMM, agent, sid))
    except subprocess.TimeoutExpired:
        try:
            from tools.warteschlange.watcher_kern import kill_orphans_fenster
            kill_orphans_fenster()
        except Exception:
            pass
        fehler("E026", pfad.relative_to(PROJEKT_STAMM) if pfad.is_relative_to(PROJEKT_STAMM) else pfad, 1, "Sonden-Lauf Timeout 120s (fail-closed)")
        if fenster_ticket is not None:
            try:
                from tools.warteschlange.watcher_kern import freigeben
                freigeben(fenster_ticket)
            except Exception:
                pass
        return False, [f"E026 {sid}: Timeout"]
    finally:
        if fenster_ticket is not None:
            try:
                from tools.warteschlange.watcher_kern import freigeben
                freigeben(fenster_ticket)
            except Exception:
                pass
    ausgabe = (erg.stdout or "") + (erg.stderr or "")
    zeilen = ausgabe.splitlines()
    try:
        log = lade_lauf_log()
        log.schreibe(f"sonden_{sid}_{agent}", f"Sonde {sid} Agent={agent} Modus={modus}", zeilen)
    except Exception:
        pass
    if erg.returncode != 0:
        fund = [z for z in zeilen if SONDE_FUND_MUSTER.search(z)]
        if not fund:
            fehler("E026", pfad.relative_to(PROJEKT_STAMM) if pfad.is_relative_to(PROJEKT_STAMM) else pfad, 1, f"Laeufer exit {erg.returncode} ohne Vertragszeile")
        else:
            for z in fund:
                fehler("E026", pfad.relative_to(PROJEKT_STAMM) if pfad.is_relative_to(PROJEKT_STAMM) else pfad, 1, z.strip())
        return False, zeilen[-80:]
    for z in zeilen:
        if "SONDE-FEHLER" in z or "SONDE-WIDERSPRUCH" in z:
            fehler("E026", pfad.relative_to(PROJEKT_STAMM) if pfad.is_relative_to(PROJEKT_STAMM) else pfad, 1, z.strip())
        elif "SONDE-ABWEICHUNG" in z:
            fehler("E028", pfad.relative_to(PROJEKT_STAMM) if pfad.is_relative_to(PROJEKT_STAMM) else pfad, 1, z.strip())
        elif "SONDE-FEHLT" in z:
            fehler("E027", pfad.relative_to(PROJEKT_STAMM) if pfad.is_relative_to(PROJEKT_STAMM) else pfad, 1, z.strip())
    return True, zeilen[-80:]
