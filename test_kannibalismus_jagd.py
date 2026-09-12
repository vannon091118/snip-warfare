# -*- coding: utf-8 -*-
"""TDD RED-Test für Slice M2: autonome Kannibalismus-Jagd.

Verlangt am Code: Die Eskalationsketten sprechen nicht nur, ihr verhalten
Feld hat Verbraucher. Wenn kein jagbares Tier in Reichweite liegt und das
Lager leer ist, beginnt ein Stickman im Kannibalismus-Stadium der
Hunger-Kette, den schwächsten Nachbarn zu jagen, erlegt ihn schlagweise
und das Fleisch fällt in den Bestand. Alles über dieselben Maschinen wie
die Tierjagd, nur mit eigenem Ziel-Knoten OWN.
"""
import pathlib
import re

PROJEKT = pathlib.Path(__file__).resolve().parent


def _lies(rel: str) -> str:
    return (PROJEKT / rel).read_text(encoding="utf-8")


def test_job_basis_hat_einen_eigenen_ziel_knoten_fuer_einheiten():
    """ZielTyp kennt neben OBJEKT und TIER den Knoten OWN für Artgenossen."""
    basis = _lies("game/logic/kategorie_job/job_basis.gd")
    enum_block = re.search(r"enum ZielTyp \{(.*?)\}", basis, re.S).group(1)
    assert re.search(r"\bOWN\b", enum_block), "ZielTyp ohne OWN"


def test_der_manager_jagt_den_schwaechsten_nachbarn_beim_kannibalismus():
    """Beim Kannibalismus-Verhalten wählt die Verhaltens-Maschine das schwächste Ziel."""
    verhalten = _lies("game/logic/kategorie_einheit/einheit_verhaltens_maschine.gd")
    manager = _lies("game/logic/kategorie_einheit/einheit_manager.gd")
    takt = _lies("game/logic/kategorie_einheit/einheit_takt_maschine.gd")
    assert "kannibalis" in verhalten.lower(), "Verhaltens-Maschine kennt das Verhalten nicht"
    assert "schwäch" in verhalten.lower(), "Verhaltens-Maschine wählt nicht den Schwächsten"
    assert "func _jagd_nachbarn" in verhalten, "Verhaltens-Maschine hat keinen Nachbar-Zielsucher"
    assert "einheit_hp" in verhalten, "Verhaltens-Maschine liest die Lebenspunkte nicht"
    # Der Takt liegt seit dem Zerlegungs-Slice in der Takt-Maschine; der Manager
    # reicht ihn nur noch durch.
    assert "pruefe_verhalten" in takt, "Die Takt-Maschine erreicht die Verhaltens-Maschine nicht"
    assert "_takt.tick" in manager, "Der Manager reicht den Takt nicht an die Takt-Maschine durch"


def test_die_ernte_maschine_erlegt_artgenossen_wie_beute():
    """Der Arbeitsschritt am OWN-Ziel verletzt schlagweise und wirft Fleisch ab."""
    ernte = _lies("game/logic/kategorie_einheit/einheit_ernte_maschine.gd")
    assert "ZielTyp.OWN" in ernte, "Ernte-Maschine bearbeitet OWN-Ziele nicht"
    assert "beute_erlegt" in ernte, "Erlegte Artgenossen melden Beute nicht"


def test_die_blase_erzaehlt_die_tat_wie_jede_andere_stufe():
    """Die Verhaltens-Maschine meldet den Jagd-Auslöser an die Mood-Maschine der Einheit."""
    verhalten = _lies("game/logic/kategorie_einheit/einheit_verhaltens_maschine.gd")
    assert "bereich_hervorheben" in verhalten, "Blase erzählt die Jagd nicht"


def test_vitaler_tod_einer_artgenossin_laeuft_ueber_den_einzigen_pfad():
    """Schaden läuft über schaden_nehmen (Bus, Modifikatoren, Tod), nie daneben."""
    ernte = _lies("game/logic/kategorie_einheit/einheit_ernte_maschine.gd")
    assert "schaden_nehmen" in ernte, "Artgenossen-Schaden läuft am Vital-Pfad vorbei"
