# -*- coding: utf-8 -*-
"""Test für die Reparatur der Daten- und Verantwortungsnähte.

Verifiziert am Code:
- Das Kontextmenü filtert über ziel_tags aus steuerung.json und
  element_katalog.json statt über harte Namensvergleiche.
- Der Terrain-Renderer nimmt die Kachelkante ausschließlich aus dem Modell.
- Das Debug-Overlay ist ein eigenes, standardmäßig unsichtbares Fenster.
- Die Produktionszeile kommt als Ereignis, nicht mehr als Frame-Abfrage.
- Ein Bauplatz wird je Kachel nur einmal belegt, die Regel steht in den Daten.
- Der Tier-Manager prüft freigegebene Darsteller, bevor er sie typisiert.
"""
import json
import pathlib

PROJEKT = pathlib.Path(__file__).resolve().parent


def _lies(rel: str) -> str:
    return (PROJEKT / rel).read_text(encoding="utf-8")


def _json(rel: str):
    return json.loads(_lies(rel))


def _katalog_eintrag(element_id: str) -> dict:
    for eintrag in _json("world/data/element_katalog.json"):
        if eintrag.get("id") == element_id:
            return eintrag
    raise AssertionError("Element fehlt im Katalog: %s" % element_id)


def test_kontext_aktionen_tragen_ziel_tags():
    """Jede Vor-Ort-Aktion nennt ihre Ziele als Daten, nicht im UI-Code."""
    steuerung = _json("game/data/steuerung.json")
    aktionen = {a["id"]: a for a in steuerung["kontextmenue"]["aktionen"]}
    assert "holz" in aktionen["sammeln"]["ziel_tags"]
    assert "tier" in aktionen["sammeln"]["ziel_tags"]
    assert aktionen["abbauen"]["ziel_tags"] == ["stein"]
    assert aktionen["marschieren"]["ziel_tags"] == ["boden"]
    assert "ziel_tags" not in aktionen["expansieren"], \
        "Globale Aktionen ohne Zielbindung gelten ueberall"


def test_elemente_tragen_ziel_tags():
    """Objekte beschreiben sich selbst; das Menue vergleicht keine Namen."""
    assert _katalog_eintrag("baum")["ziel_tags"] == ["holz", "baum"]
    assert _katalog_eintrag("stein")["ziel_tags"] == ["stein"]
    assert "beeren" in _katalog_eintrag("busch")["ziel_tags"]
    assert "tier" in _katalog_eintrag("baer")["ziel_tags"]


def test_kontext_menue_hat_keine_harten_namensvergleiche_mehr():
    code = _lies("ui/scenes/panels/kontext_menue.gd")
    assert "func eintraege_aufbauen_fuer_tags(" in code
    assert "func eintraege_aufbauen_fuer(ziel_filter: String)" in code, \
        "Der Vertrag der bestehenden Aufrufer bleibt erhalten"
    assert 'contains("baum")' not in code
    assert 'contains("stein")' not in code


def test_eingabe_uebersetzt_orte_in_ziel_tags():
    code = _lies("ui/logic/kategorie_ui/ui_eingabe_steuerung.gd")
    jobs = _lies("ui/logic/kategorie_ui/ui_job_vergabe_maschine.gd")
    assert "func _ziel_tags_fuer_ort(" in code
    assert "ziel_tags_fuer(" in code, "Die Tags kommen aus der Registry"
    assert "func marschieren_nach(" in jobs, "Der Marschbefehl wohnt in der Job-Vergabe-Maschine"
    assert 'logik == "marschieren"' in code


def test_renderer_nimmt_die_kachelkante_aus_dem_modell():
    code = _lies("world/logic/kategorie_welt/welt_renderer.gd")
    assert "Vector2(x, y) * kante" in code
    assert "float(_model.kachel_groesse)" in code
    assert "Welt_Model.KACHEL_GROESSE" not in code, \
        "Es gibt genau eine Quelle der Kachelgroesse"


def test_terrain_blatt_ist_deterministisch_und_datennah():
    code = _lies("world/logic/kategorie_welt/welt_terrain_blatt.gd")
    assert "class_name Welt_TerrainBlatt" in code
    assert "Kern_Zufall.abgeleitet_fuer(" in code, \
        "Die Variante kommt aus der gemeinsamen Zufallsquelle"
    assert "kachel_spiegelbar" in code
    assert "kachel_toenungen" in code


def test_debug_fenster_ist_eigenes_unsichtbares_panel():
    code = _lies("ui/scenes/hud/hud_debug_panel.gd")
    assert "class_name Ui_DebugPanelSzene" in code
    assert "func sichtbar_setzen(" in code
    welt = _lies("world/scenes/welt.gd")
    spitze = _lies("world/logic/kategorie_welt/welt_ui_aufbau.gd")
    assert "debug_panel_bauen" in spitze, "Der Debug-Aufbau wohnt in der UI-Spitze"
    assert "debug_panel.visible = false" in spitze
    assert "_auf_produktion_status(_gebaeude.status_zeilen())" not in welt, \
        "Kein Frame-Polling der Produktionszeile"
    assert "_rueckmeldung.produktion_anzeigen" in welt, \
        "Die Produktionszeile laeuft ueber die Rueckmelde-Spitze"
    assert "status_geaendert" in welt, "Die Zeile kommt als Ereignis"


def test_produktionszeile_wird_nur_bei_aenderung_gemeldet():
    code = _lies("world/logic/kategorie_objekt/gebaeude_manager.gd")
    assert "signal status_geaendert" in code
    assert "func _melde_status_wenn_neu(" in code
    assert "_letzte_statuszeilen" in code


def test_bauplatz_regel_steht_in_den_daten():
    for gebaeude in _json("world/data/gebaeude.json"):
        assert gebaeude.get("belegt_kachel") is True, gebaeude["id"]
    definition = _lies("world/logic/kategorie_objekt/gebaeude_definition.gd")
    assert "var belegt_kachel: bool = true" in definition
    assert 'eintrag.get("belegt_kachel", true)' in definition
    manager = _lies("world/logic/kategorie_objekt/gebaeude_manager.gd")
    assert "func _bauplatz_frei(" in manager
    assert "_bauplatz_frei(gebaeude_id, welt_position, definition)" in manager


def test_tier_manager_prueft_freigegebene_darsteller():
    code = _lies("world/logic/kategorie_tier/tier_manager.gd")
    assert code.count("is_instance_valid(darsteller_knoten)") >= 1
    assert "entfernte.reverse()" in code, \
        "Austragen von hinten, sonst rutschen die Indizes"


def test_tierliste_ist_gedeckelt():
    code = _lies("ui/logic/kategorie_ui/ui_tier_panel.gd")
    assert "ANZEIGE_MAX" in code
    assert "weitere" in code
