# -*- coding: utf-8 -*-
"""Vertragstest des Blackboards (Regel 9, statisch): Die Form hält."""

import json
import re
from pathlib import Path

STAMM = Path(__file__).parent
BRETT_ORDNER = STAMM / "core/logic/kategorie_blackboard"
REGISTER = STAMM / "core/data/engine_register.json"


def _lies(pfad: Path) -> str:
    return pfad.read_text(encoding="utf-8")


def test_view_unterscheidet_phasen():
    text = _lies(BRETT_ORDNER / "kern_blackboard_view.gd")
    assert "enum Phase" in text
    assert "LESEN" in text and "SCHREIBEN" in text and "KONSOLIDIEREN" in text
    # Die Schreib-Sperre ist ein assert, kein stiller Vertrag.
    assert re.search(r"assert\(_phase == Phase\.SCHREIBEN", text)
    assert re.search(r"assert\(_phase == Phase\.KONSOLIDIEREN", text)


def test_view_sektor_fest_eingebaut():
    text = _lies(BRETT_ORDNER / "kern_blackboard_view.gd")
    # Der Sektor wird beim Erzeugen gesetzt, nicht beim Ruf übergeben.
    assert "_eigener_sektor = sektor" in text
    assert not re.search(r"func lesen\(\w+\s*:\s*String,\s*\w+\s*:\s*String\)", text)


def test_brett_liefert_kopien():
    text = _lies(BRETT_ORDNER / "kern_blackboard.gd")
    assert "duplicate(true)" in text


def test_engine_vertrag_vollstaendig():
    text = _lies(BRETT_ORDNER / "kern_engine.gd")
    for methode in ("blackboard_lesen", "verarbeiten", "blackboard_schreiben"):
        assert "func %s" % methode in text
    assert "takt_teiler" in text


def test_koordinator_treibt_zyklus():
    text = _lies(BRETT_ORDNER / "kern_engine_koordinator.gd")
    assert "Kern_Blackboard.new()" in text
    # Taktteiler-Griffweise wie in der Einheiten-Maschine: nummer % teiler.
    assert re.search(r"nummer % \w+\.takt_teiler", text)
    # Der Registrier-Vertrag ist hart.
    assert "engine_register.json" in text and "assert" in text


def test_register_ist_gueltig_und_leer_gestartet():
    daten = json.loads(REGISTER.read_text(encoding="utf-8"))
    assert "engines" in daten and isinstance(daten["engines"], dict)


def test_kein_doppel_tick_durch_alte_anmeldung():
    """Der Konsolidator-Datei-Kern ist eine Mutation; der Koordinator ist
    der einzige Tick-Teilnehmer der neuen Kategorie."""
    koordinator = _lies(BRETT_ORDNER / "kern_engine_koordinator.gd")
    assert "weltuhr.tick.connect" in koordinator
