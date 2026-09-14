# -*- coding: utf-8 -*-
"""TDD RED-Test für Slice P1: Einstiegs-Progression.

Verlangt am Code: Die erste Spieleraktion ist das Platzieren des
Lagerfeuers; der Bau des ersten Gebäudes schaltet das Bau-HUD und die
Bau-Aktionen frei; die Stufenkette liegt als menschenlesbarer Datenpool
in game/data/progression.json; die Maschine arbeitet ohne eigene Zahlen.
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
    stufen_ids = [s["id"] for s in stufen]
    # Die Kette: Lagerfeuer -> Holz sammeln -> Raum -> Lager -> Rathaus -> Haus -> Einwanderung -> Siedlung
    assert stufen_ids == [
        "lagerfeuer_setzen", "holz_sammeln", "erster_raum",
        "lager_bauen", "rathaus_bauen", "erstes_haus",
        "einwanderung_laeuft", "siedlung_waechst"
    ], f"Unerwartete Stufenkette: {stufen_ids}"
    # Stufe 0: Lagerfeuer setzen
    lagerfeuer = stufen[0]
    assert lagerfeuer["id"] == "lagerfeuer_setzen"
    assert lagerfeuer["ziel_typ"] == "gebaeude_bauen"
    assert lagerfeuer["gebaeude_id"] == "lagerfeuer"
    # Stufe 1: Erstes Holz sammeln und einlagern
    assert stufen[1]["id"] == "holz_sammeln"
    assert stufen[1]["ziel_typ"] == "ressource_einlagern"
    assert stufen[1]["ressource"] == "holz"


def test_gebaeude_pool_traegt_lagerfeuer_und_haus():
    """Lagerfeuer immer offen, Haus erst spaeter."""
    gebaeude = {g["id"]: g for g in _json("world/data/gebaeude.json")}
    lagerfeuer = gebaeude["lagerfeuer"]
    assert lagerfeuer["gesperrt_ab_stufe"] == 0, "Lagerfeuer immer offen"
    assert lagerfeuer.get("baukosten", []) == [] or lagerfeuer.get("baukosten") == {}, \
        "Lagerfeuer ist kostenlos"
    haus = gebaeude["haus"]
    assert haus["gesperrt_ab_stufe"] >= 5, "Haus erst nach vielen Stufen"


def test_gebaeude_tragen_die_einzige_gating_wahrheit():
    """Die Stufen-Sperre ist ein Attribut des Gebaeudes, nicht der Steuerung."""
    gebaeude = {g["id"]: g for g in _json("world/data/gebaeude.json")}
    assert gebaeude["lagerfeuer"]["gesperrt_ab_stufe"] == 0, "Erste Aktion immer offen"
    # Wand und Tür erst nach Stufe 1 (erstes Holz)
    assert gebaeude["wand_holz"]["gesperrt_ab_stufe"] == 1
    assert gebaeude["tuer"]["gesperrt_ab_stufe"] == 1
    # Bett/Stuhl/Tisch nach Stufe 2 (erster Raum)
    assert gebaeude["betten"]["gesperrt_ab_stufe"] == 2
    assert gebaeude["stuhl"]["gesperrt_ab_stufe"] == 2
    assert gebaeude["tisch"]["gesperrt_ab_stufe"] == 2
    # Rathaus nach Stufe 4 (Lagerzone)
    assert gebaeude["rathaus"]["gesperrt_ab_stufe"] == 4
    steuerung = _json("game/data/steuerung.json")
    aktionen = {a["id"]: a for a in steuerung["kontextmenue"]["aktionen"]}
    assert not any(a_id.startswith("bauen_") for a_id in aktionen), \
        "Bauen gehört ins Panel, nicht ins Kontextmenue"


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


def test_bau_panel_liest_aus_gebaeude_registry():
    """Das Panel liest sein Angebot aus der Gebaeude_DefinitionRegistry."""
    panel = _lies("ui/logic/kategorie_ui/ui_bau_panel.gd")
    assert "moebel.json" not in panel, "keine zweite Moebel-Quelle neben der Registry"
    assert "DefinitionRegistry" in panel or "gebaeude_definition" in panel, \
        "Angebot kommt aus der Gebaeude-Registry"
    definition = _lies("world/logic/kategorie_objekt/gebaeude_definition.gd")
    assert "var gesperrt_ab_stufe: int = 0" in definition


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
    """Der Laufbeweis platziert Lagerfeuer, baut das Haus und zählt Einwanderer."""
    lauf = _lies("tools/lauf_pruefung_welt.gd")
    assert "bauen_anfordern(\"lagerfeuer\"" in lauf
    assert "bauen_anfordern(\"haus\"" in lauf
    assert "einwanderer_je_tag" in lauf
