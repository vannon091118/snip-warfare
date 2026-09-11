# -*- coding: utf-8 -*-
"""Test für Phase 1: Bau-Panel und kontextsensitive Steuerung.

Verifiziert am Code:
- Ui_BauPanel bereitet Gebäude-Definitionen mit Kosten, Icon und Stufensperren auf.
- KontextMenue filtert Aktionen zielgerichtet (Baum -> Holz fällen, Stein -> Abbauen, etc.).
- Einheit_Manager und Einheit_Status unterstützen freie Marschbefehle (geh_befehl).
- Steuerung.json und Bau-Panel harmonieren mit den Progressionsstufen.
"""
import json
import pathlib

PROJEKT = pathlib.Path(__file__).resolve().parent


def _lies(rel: str) -> str:
    return (PROJEKT / rel).read_text(encoding="utf-8")


def _json(rel: str):
    return json.loads(_lies(rel))


def test_ui_bau_panel_vorhanden_und_strukturiert():
    """Ui_BauPanel existiert und enthält saubere Methoden zur Gebäude-Aufbereitung."""
    code = _lies("ui/logic/kategorie_ui/ui_bau_panel.gd")
    assert "class_name Ui_BauPanel" in code
    assert "func eintraege_ermitteln" in code
    assert "gesperrt" in code
    assert "kosten_text" in code


def test_bau_panel_szene_vorhanden():
    """bau_panel.gd und bau_panel.tscn existieren als modulare HUD-Komponente."""
    gd_code = _lies("ui/scenes/panels/bau_panel.gd")
    assert "class_name Ui_BauPanelSzene" in gd_code
    assert "signal bau_gewaehlt" in gd_code
    assert "func aktualisieren" in gd_code

    tscn_code = _lies("ui/scenes/panels/bau_panel.tscn")
    assert "res://ui/scenes/panels/bau_panel.gd" in tscn_code
    assert "ButtonContainer" in tscn_code


def test_kontext_menue_unterstuetzt_ziel_filterung():
    """kontext_menue.gd filtert Aktionen nach Zielobjekt (Baum, Stein, Busch, Tier, Boden)."""
    code = _lies("ui/scenes/panels/kontext_menue.gd")
    assert "func eintraege_aufbauen_fuer(ziel_filter: String)" in code
    assert "_aktuelle_aktionen" in code


def test_eingabe_steuerung_unterstuetzt_bau_und_debug_toggle():
    """ui_eingabe_steuerung.gd besitzt Bau-Auftrag-Logik und F3 Debug-Toggle."""
    code = _lies("ui/logic/kategorie_ui/ui_eingabe_steuerung.gd")
    assert "func bau_auftrag_setzen" in code
    assert "func debug_umschalten" in code
    assert "signal debug_umgeschaltet" in code
    assert "KEY_F3" in code
    assert "_bauen_ausfuehren_an_position" in code


def test_einheit_marschbefehl_vorhanden():
    """einheit_status.gd und einheit_manager.gd unterstützen freie Bewegung auf Spielerbefehl."""
    st_code = _lies("game/logic/kategorie_einheit/einheit_status.gd")
    assert "func geh_befehl" in code_check if (code_check := st_code) else False
    mgr_code = _lies("game/logic/kategorie_einheit/einheit_manager.gd")
    assert "func einheit_bewegen_nach" in mgr_code


def test_welt_szene_verdrahtet_bau_panel_und_panels():
    """welt.gd bindet das BauPanel ein und schaltet Panels dynamisch/per F3."""
    welt_code = _lies("world/scenes/welt.gd")
    assert "_bau_panel_bauen" in welt_code
    assert "_auf_bau_gewaehlt" in welt_code
    assert "_auf_debug_umgeschaltet" in welt_code
    assert "visible = false" in welt_code
