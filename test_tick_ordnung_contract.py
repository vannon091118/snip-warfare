# -*- coding: utf-8 -*-
"""Vertragstest der Tick-Ordnung: Die Reihenfolge der Weltuhr bleibt erklaert.

Der Test laeuft gegen den echten Code, nicht gegen erfundene Daten. Er haelt
drei Zusagen fest, die vorher nur Gewohnheit waren: Jede Anmeldung am Tick ist
in der Ordnung erklaert, keine Anmeldung ist ungeschuetzt, und kein Skript
greift am Autoload vorbei auf den globalen Namen der Uhr zu.
"""

import sys
from pathlib import Path

WURZEL = Path(__file__).resolve().parent
sys.path.insert(0, str(WURZEL / "tools"))

from tick_ordnung.pruefer import (AUTOLOAD, UNGESCHUETZT, UNERKLAERT,   # noqa: E402
                                  gd_dateien, ordnung_lesen, pruefe_ordnung)

ORDNUNG_PFAD = WURZEL / "tools" / "tick_ordnung" / "ordnung.json"


def test_ordnung_ist_lesbar_und_traegt_gruende():
    ordnung = ordnung_lesen()
    assert ordnung is not None, "ordnung.json muss lesbar sein"
    teilnehmer = ordnung["teilnehmer"]
    assert len(teilnehmer) >= 10
    for eintrag in teilnehmer:
        assert eintrag.get("datei"), "Jeder Teilnehmer braucht eine Datei"
        assert eintrag.get("domaene"), "Jeder Teilnehmer braucht eine Domaene"
        assert eintrag.get("grund"), "Jeder Teilnehmer braucht einen Grund"


def test_ordnung_ist_dublettenfrei():
    dateien = [eintrag["datei"] for eintrag in ordnung_lesen()["teilnehmer"]]
    assert len(dateien) == len(set(dateien)), "Eine Datei darf nur einmal erklaert sein"


def test_ordnung_verweist_nur_auf_vorhandene_dateien():
    for eintrag in ordnung_lesen()["teilnehmer"]:
        assert (WURZEL / eintrag["datei"]).is_file(), \
            "%s ist erklaert, aber nicht vorhanden" % eintrag["datei"]


def test_jede_anmeldestelle_ist_erklaert():
    offen = [b for b in pruefe_ordnung() if b.art == UNERKLAERT]
    assert offen == [], "Unerklaerte Tick-Teilnehmer: %s" % \
        [b.zeile_text() for b in offen]


def test_keine_ungeschuetzte_anmeldung():
    offen = [b for b in pruefe_ordnung() if b.art == UNGESCHUETZT]
    assert offen == [], "Ungeschuetzte Anmeldungen: %s" % [b.zeile_text() for b in offen]


def test_kein_direkter_autoload_zugriff():
    offen = [b for b in pruefe_ordnung() if b.art == AUTOLOAD]
    assert offen == [], "Direkter Autoload-Zugriff: %s" % [b.zeile_text() for b in offen]


def test_pruefer_erkennt_fehlenden_eintrag():
    # Gegentest: Der Pruefer darf nicht immer gruen sein. Eine Ordnung ohne den
    # Tiermanager muss dessen Anmeldung als unerklaert melden.
    ordnung = ordnung_lesen()
    ordnung["teilnehmer"] = [eintrag for eintrag in ordnung["teilnehmer"]
                             if "tier_manager" not in eintrag["datei"]]
    befunde = pruefe_ordnung(ordnung=ordnung)
    assert any(b.art == UNERKLAERT and "tier_manager" in b.datei for b in befunde)


def test_pruefer_erkennt_ungeschuetzte_anmeldung():
    # Gegentest: Ein erfundener Teilnehmer ohne Wache muss auffallen.
    kuenstlich = [("test/erfunden.gd",
                   "func _enter_tree() -> void:\n\tweltuhr.tick.connect(_auf_tick)\n")]
    ordnung = ordnung_lesen()
    ordnung["teilnehmer"] = ordnung["teilnehmer"] + [
        {"datei": "test/erfunden.gd", "domaene": "test", "grund": "Gegentest"}]
    befunde = pruefe_ordnung(ordnung=ordnung, dateien=kuenstlich)
    assert any(b.art == UNGESCHUETZT for b in befunde)


def test_weltuhr_ist_die_einzige_tickquelle():
    # Regel 5: genau eine Weltzeit. Ein zweites tick-Signal waere ein zweiter
    # Taktgeber und wuerde die Ordnung unmoeglich machen.
    quellen = [relativ for relativ, text in gd_dateien()
               if "\nsignal tick(" in "\n" + text or text.startswith("signal tick(")]
    assert quellen == ["core/logic/clock/weltuhr.gd"], \
        "Es darf nur ein tick-Signal geben, gefunden: %s" % quellen


def test_ordnung_meldet_keine_befunde_im_gesamten_repo():
    befunde = pruefe_ordnung()
    assert [b.zeile_text() for b in befunde] == []
