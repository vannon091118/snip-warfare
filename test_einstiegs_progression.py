# -*- coding: utf-8 -*-
"""TDD RED-Test für Slice P1: Einstiegs-Progression.

Verlangt am Code: Die erste Spieleraktion ist das Platzieren des
Lagerfeuers; der Bau des ersten Gebäudes schaltet das Bau-HUD und die
Bau-Aktionen frei; das erste Ziel ist ein Haus, das neue Stickmen
hervorbringt. Die Stufenkette liegt als menschenlesbarer Datenpool in
game/data/progression.json; die Maschine arbeitet ohne eigene Zahlen.
"""
import json
import pathlib

PROJEKT = pathlib.Path(__file__).resolve().parent


def _lies(rel: str) -> str:
    return (PROJEKT / rel).read_text(encoding="utf-8")


def _json(rel: str):
    return json.loads(_lies(rel))


def test_progression_pool_traegt_die_stufenkette():
    """Einzige Wahrheit der Einstiegs-Kette ist der Datenpool."""
    pool = _json("game/data/progression.json")
    stufen = pool["stufen"]
    assert [s["id"] for s in stufen] == ["lagerfeuer_setzen", "erstes_haus", "einwanderung_laeuft", "siedlung_waechst"]
    # Stufe 0: Lagerfeuer setzen; es schaltet Bau-HUD und Haus frei.
    lagerfeuer = stufen[0]
    assert lagerfeuer["ziel_typ"] == "gebaeude_bauen"
    assert lagerfeuer["gebaeude_id"] == "lagerfeuer"
    assert lagerfeuer["menge"] == 1
    assert lagerfeuer["schaltet_frei"]["bau_hud"] is True
    assert lagerfeuer["schaltet_frei"]["gebaeude"] == ["haus"]
    # Stufe 1: Das Haus ist das erste echte Spielerziel und schaltet Werkstatt
    # sowie Raeucherei frei.
    assert stufen[1]["gebaeude_id"] == "haus"
    assert stufen[1]["schaltet_frei"]["gebaeude"] == ["werkstatt", "raeucherei"]
    # Stufe 2: Danach laeuft die Einwanderung und die Expansion wird frei.
    assert stufen[2]["ziel_typ"] == "einwanderung"
    assert stufen[2]["einwanderer_je_tag"] >= 1
    assert "expansieren" in stufen[2]["schaltet_frei"]["aktionen"]
    assert stufen[3]["ziel_typ"] == "einwanderung"


def test_gebaeude_pool_traegt_lagerfeuer_und_haus_mit_lager_typ():
    """Lagerfeuer ohne Produktionsrezept, Haus mit Lager-Vertrag."""
    gebaeude = {g["id"]: g for g in _json("world/data/gebaeude.json")}
    lagerfeuer = gebaeude["lagerfeuer"]
    assert lagerfeuer["produktion"]["inputs"] == [], "Lagerfeuer produziert nichts"
    assert lagerfeuer["lager_typ"] == "kleines_lager", "Lagerfeuer ist der Basis-Anker"
    assert lagerfeuer["einwanderer_lieferant"] is True
    haus = gebaeude["haus"]
    assert haus["lager_typ"] == "kleines_lager"
    assert haus["einwanderer_lieferant"] is True
    assert haus["baukosten"]["holz"] > 0, "Das Haus kostet echte Arbeit"


def test_gebaeude_tragen_die_einzige_gating_wahrheit():
    """Die Stufen-Sperre ist ein Attribut des Gebaeudes, nicht der Steuerung.

    Die Vorarbeit hat das Bauen aus dem Kontextmenue in das Bau-Panel
    verschoben. Damit gibt es genau eine Gating-Quelle: gesperrt_ab_stufe in
    world/data/gebaeude.json. Die Steuerung traegt keine Bau-Aktionen mehr.
    """
    gebaeude = {g["id"]: g for g in _json("world/data/gebaeude.json")}
    assert gebaeude["lagerfeuer"]["gesperrt_ab_stufe"] == 0, "Erste Aktion ist immer offen"
    assert gebaeude["haus"]["gesperrt_ab_stufe"] == 1
    assert gebaeude["werkstatt"]["gesperrt_ab_stufe"] == 2
    assert gebaeude["raeucherei"]["gesperrt_ab_stufe"] == 2
    steuerung = _json("game/data/steuerung.json")
    aktionen = {a["id"]: a for a in steuerung["kontextmenue"]["aktionen"]}
    assert not any(a_id.startswith("bauen_") for a_id in aktionen), \
        "Bauen gehoert ins Panel, nicht ins Kontextmenue"
    assert aktionen["expansieren"]["gesperrt_ab_stufe"] == 3


def test_fortschritts_maschine_ist_datengetrieben():
    """Eigene Maschine, keine fremde Logik, keine hartcodierten Stufen."""
    maschine = _lies("world/logic/kategorie_progression/welt_fortschritts_maschine.gd")
    assert "class_name Welt_FortschrittsMaschine" in maschine
    assert "stufe_frei(" in maschine, "Gating-Frage an die Maschine"
    assert "signal stufe_erreicht" in maschine, "Freischaltungen als sichtbares Ereignis"
    assert "signal ziel_erreicht" in maschine, "Zielabschluss als sichtbares Ereignis"


def test_registry_laedt_den_pool_ohne_eigene_zahlen():
    """Registry lädt nur game/data/progression.json."""
    registry = _lies("world/logic/kategorie_progression/welt_fortschritts_registry.gd")
    assert "res://game/data/progression.json" in registry


def test_gebaeude_manager_prueft_freigabe_und_meldet_abschluss():
    """Gating sitzt in der Bau-Verbindung, Abschluss meldet die Maschine."""
    manager = _lies("world/logic/kategorie_objekt/gebaeude_manager.gd")
    assert "fortschritt" in manager, "Manager hält die Progressions-Verbindung"
    assert "gebaeude_fertiggestellt" in manager, "Abschluss wird als Signal sichtbar"


def test_eingabe_steuerung_blockt_gesperrte_aktionen():
    """Der Eingabe-Übersetzer fragt die Maschine, bevor er baut."""
    eingabe = _lies("ui/logic/kategorie_ui/ui_eingabe_steuerung.gd")
    assert "stufe_frei" in eingabe, "Gesperrte Bau-Aktionen werden abgelehnt"


def test_bau_panel_liest_die_sperre_aus_der_definition():
    """Das Panel erfindet keine Stufen mehr, es liest gesperrt_ab_stufe."""
    panel = _lies("ui/logic/kategorie_ui/ui_bau_panel.gd")
    assert "def.gesperrt_ab_stufe" in panel, "Stufe kommt aus der Definition"
    assert 'def.id == "haus"' not in panel, "keine erfundene Stufen-Tabelle im UI"
    definition = _lies("world/logic/kategorie_objekt/gebaeude_definition.gd")
    assert "var gesperrt_ab_stufe: int = 0" in definition
    assert 'eintrag.get("gesperrt_ab_stufe", 0)' in definition


def test_lager_fabrik_ankert_am_lagerfeuer():
    """Ohne Haus sichert das Lagerfeuer den ersten Lagerpunkt."""
    fabrik = _lies("world/logic/kategorie_welt/welt_lager_fabrik.gd")
    assert "lagerfeuer" in fabrik


def test_welt_verdrahtet_die_progressionskette():
    """Die Welt-Szene verbindet nur: Maschine, Manager-Meldung, HUD-Ziel."""
    szene = _lies("world/scenes/welt.gd")
    assert "Welt_FortschrittsMaschine" in szene
    assert "fortschritt.ziel_zeile()" in szene, "Das HUD zeigt das aktuelle Ziel"


def test_laufbeweis_spielt_die_kette_durch():
    """Der Laufbeweis plaziert Lagerfeuer, baut das Haus und zählt Einwanderer."""
    lauf = _lies("tools/lauf_pruefung_welt.gd")
    assert "bauen_anfordern(\"lagerfeuer\"" in lauf
    assert "bauen_anfordern(\"haus\"" in lauf
    assert "einwanderer_je_tag" in lauf
