# -*- coding: utf-8 -*-
"""Vertragstest der Sozial-Domäne (Soz_): Taten -> Glaube -> Gerüchte -> Beziehungen.

Verlangt am Code: Die Domäne lauscht am Kern-SignalBus, hält alle Schwellen
in sozial_regeln.json, trägt Traits als Bevölkerungs-Festwerte mit eigener
Wirkung, erzählt Gerüchte mit Farbe und Eskalationsstufe nur an Nachbarn
weiter und mischt langfristige Beziehungen in einer eigenen Engine.
"""
import json
import pathlib
import re

PROJEKT = pathlib.Path(__file__).resolve().parent


def _lies(rel: str) -> str:
    return (PROJEKT / rel).read_text(encoding="utf-8")


def _regeln() -> dict:
    return json.loads(_lies("population/logic/sozial/data/sozial_regeln.json"))


def test_der_praefix_soz_ist_in_der_preflight_tabelle():
    """Ohne Tabellen-Eintrag wirft E001 beim ersten Soz_-File."""
    kern = _lies("tools/preflight/kern.py")
    assert '"Soz_": "population/logic/sozial"' in kern


def test_die_tat_quelle_meldet_am_bus_ohne_fremdlogik():
    """Die Ernte-Maschine meldet Kannibalismus am Bus; der Bus ist die Brücke."""
    ernte = _lies("game/logic/kategorie_einheit/einheit_ernte_maschine.gd")
    assert "_emit_kannibalismus" in ernte
    assert "Kern_SignalBus.bus()" in ernte


def test_der_manager_lauscht_nur_am_bus():
    """Die Soz-Fassade besitzt keine eigene Zeit und schreibt in keine Domäne."""
    manager = _lies("population/logic/sozial/logic/soz_manager.gd")
    assert "Time.get_" not in manager and "OS.get_" not in manager
    assert "bus.gestorben.connect" in manager


def test_alle_schwellen_wohnen_im_json():
    """Gewichte, Radius, Takt, Dämpfung, Verfall und Traits sind Daten, kein Code."""
    regeln = _regeln()
    for gruppe in ("zeugen", "taten", "geruechte", "traits", "beziehungen"):
        assert gruppe in regeln, "Regel-Gruppe fehlt: %s" % gruppe
    geruechte = regeln["geruechte"]
    for art, daten in geruechte["art"].items():
        assert "farbe" in daten and "eskalation" in daten, "Art unvollständig: %s" % art
    assert len(regeln["traits"]) >= 3, "Zu wenige Traits für Unterschiede"


def test_traits_machen_einen_unterschied():
    """Tratscht-gerne und Hasst-Gerüchte wirken je anders auf Gerede und Glaube."""
    traits = _regeln()["traits"]
    tratsch, hass = traits["tratscht_gerne"], traits["hasst_geruechte"]
    assert tratsch["gerede_bonus"] > hass["gerede_bonus"]
    assert hass["glaubens_bonus"] > tratsch["glaubens_bonus"]


def test_geruechte_eskalieren_nur_ueber_stufen_der_art():
    """Stufe 0 bleibt beim Zeugen, die Wanderung fällt je Stufe ab."""
    maschine = _lies("population/logic/sozial/logic/soz_geruecht_maschine.gd")
    assert "eskalation() >= 1" in maschine
    assert "konfidenz_verlust_je_stufe" in maschine
    geruecht = _lies("population/logic/sozial/logic/soz_geruecht.gd")
    assert "farbe" in geruecht and "eskalation" in geruecht


def test_die_beziehungs_engine_ist_eigen_und_verfaellt():
    """Langfristige Beziehungen mischen Glaube, Ethik und Trait-Farbe mit Verfall."""
    engine = _lies("population/logic/sozial/logic/soz_beziehungs_engine.gd")
    assert "verfall_je_tick" in engine
    assert "bild_gewicht" in engine and "ethik_gewicht" in engine
    assert "stufe_von" in engine


def test_die_blase_ist_eigene_spitze_ohne_mood_eingriff():
    """Die farbige Blase liest geruechte_von, die Mood-Kette bleibt unberührt."""
    blase = _lies("population/logic/sozial/logic/soz_denkblase.gd")
    assert "Soz_Manager" not in blase
    assert "farbe()" in blase and "erzaehlung()" in blase
    mood_blase = _lies("population/logic/mood/pop_denkblase.gd")
    assert "Soz_" not in mood_blase


def test_die_verkabelung_haengt_blase_und_anmeldung_an():
    """Einwanderung hängt die Blase an, die Welt-Szene meldet die Einheit."""
    einwanderung = _lies("game/logic/kategorie_einheit/einheit_einwanderungs_maschine.gd")
    assert "Soz_Denkblase.new()" in einwanderung
    welt = _lies("world/scenes/welt.gd")
    assert "_sozial.einheit_anmelden" in welt
    assert "Soz_Manager.new()" in welt
