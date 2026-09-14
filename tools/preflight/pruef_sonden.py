# -*- coding: utf-8 -*-
"""Pruefkategorie sonden (E026-E029): Dünner Aufrufer über echte Teil-Domänen."""

import json
from pathlib import Path

from .kern import PROJEKT_STAMM, fehler
from .sonden_scope import filtere_nach_scope, normiere_pfad
from tools.sonden.sonden_pfade import SIGNATUR_ORDNER, SNAP_ORDNER, SONDEN_STAMM, SZENARIEN_ORDNER, agent_id
from tools.sonden.sonden_selbstbeweis import pruefe_selbstbeweis
from tools.sonden.sonden_szenario_validierer import validiere_szenario
from tools.sonden.sonden_snap import sonden_snap as _sonden_snap_impl


def _pruefe_selbstbeweise(szenarien) -> bool:
    """E046: Ein Szenario darf nicht selbst herbeifuehren, was es behauptet."""
    verletzt = False

    def melde(rel: str, text: str):
        nonlocal verletzt
        verletzt = True
        fehler("E046", rel, 1, text)

    for pfad in szenarien:
        try:
            daten = json.loads(pfad.read_text(encoding="utf-8"))
        except Exception:
            continue
        pruefe_selbstbeweis(daten, str(pfad.relative_to(PROJEKT_STAMM)), melde)
    return verletzt


def _validiere_szenario(pfad: Path) -> list[str]:
    return validiere_szenario(pfad)


def sonden_snap():
    return _sonden_snap_impl()


def _normiere_pfad(pfad: str) -> set[str]:
    return normiere_pfad(pfad)


def pruefe_sonden(godot_befehl: str = "godot", *, schnelldurchlauf: bool = False, scope_dateien: list[str] | None = None):
    """Haupteinstieg. Fail-closed wie pruef_godot."""
    agent = agent_id()
    SONDEN_STAMM.mkdir(parents=True, exist_ok=True)
    SNAP_ORDNER.mkdir(parents=True, exist_ok=True)
    SIGNATUR_ORDNER.mkdir(parents=True, exist_ok=True)
    if not SZENARIEN_ORDNER.is_dir():
        return
    szenarien = sorted(SZENARIEN_ORDNER.glob("*.json"))
    if not szenarien:
        return
    zu_pruefen = szenarien if schnelldurchlauf else filtere_nach_scope(szenarien, scope_dateien)
    if schnelldurchlauf:
        zu_pruefen = szenarien
    for pfad in zu_pruefen:
        for msg in _validiere_szenario(pfad):
            fehler("E027", pfad.relative_to(PROJEKT_STAMM), 1, msg)
    if any(_validiere_szenario(p) for p in zu_pruefen):
        return
    if _pruefe_selbstbeweise(zu_pruefen):
        return
    from .lauf_log_bruecke import lade_lauf_log
    from tools.sonden.sonden_laeufer import laufe_szenario
    from tools.sonden.sonden_ocr_bruecke import ocr_fuer_bild
    gesammelt: list[str] = [f"Sonden-Lauf Agent={agent} Modus={'schnell' if schnelldurchlauf else 'scope' if scope_dateien else 'voll'} Szenarien={len(zu_pruefen)}"]
    for pfad in zu_pruefen:
        data = json.loads(pfad.read_text(encoding="utf-8"))
        sid = str(data["id"])
        ok, tail = laufe_szenario(pfad, godot_befehl, agent, schnelldurchlauf)
        gesammelt.append(f"--- {sid} ok={ok} ---")
        gesammelt.extend(tail)
        for z in tail:
            if "sonden_bilder" in z and z.strip().endswith(".png"):
                png = Path(z.strip().split()[-1]) if " " in z else None
                if png is None:
                    continue
                ocr_zeile = ocr_fuer_bild(png, sid)
                if ocr_zeile:
                    gesammelt.append(ocr_zeile)
        try:
            paar_a = [p for p in zu_pruefen if p.stem.endswith("_a")]
            for pa in paar_a:
                pb = pa.with_name(pa.stem[:-2] + "_b" + pa.suffix)
                if pb in zu_pruefen:
                    gesammelt.append(f"AB-Paar {pa.stem} <-> {pb.stem}: beide Lagen, Heizbild in sonden_bilder/{agent}/")
        except Exception:
            pass
    try:
        lade_lauf_log().schreibe("sonden_letzter_lauf", f"Sonden Agent={agent}", gesammelt)
    except Exception:
        pass
