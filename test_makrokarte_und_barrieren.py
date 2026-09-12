# -*- coding: utf-8 -*-
"""Test für die Makrokarte, die Barrieren und den Startvorrat.

Verifiziert am Code:
- Die Makrokarte hat eine eigene Definition und plant nur Regionen.
- Gebirge und Ozean sind Barrieren-Biome der Makroebene; die lokale Karte
  zieht sie nie.
- Der Netzwerk-Planer meidet Barrieren fuer Fraktionen, Startbereich und Wege.
- Das Lagerfeuer traegt einen Startvorrat aus gebaeude.json.
"""
import json
import pathlib

PROJEKT = pathlib.Path(__file__).resolve().parent


def _lies(rel: str) -> str:
    return (PROJEKT / rel).read_text(encoding="utf-8")


def _json(rel: str):
    return json.loads(_lies(rel))


def test_makrokarte_hat_eigene_definition():
    karte = _json("world/data/weltkarte_definition.json")
    assert karte["regionen"]["breite"] >= 8 and karte["regionen"]["hoehe"] >= 6
    assert karte["region_kante_kacheln"] >= 1
    assert karte["start_biom"] != ""


def test_makro_generator_plant_nur_regionen():
    code = _lies("world/logic/kategorie_welt/welt_makro_generator.gd")
    assert "class_name Welt_MakroGenerator" in code
    assert "res://world/data/weltkarte_definition.json" in code
    assert "region_ergaenzen" in code
    assert "Welt_Generator.new()" not in code, "Die Makrokarte ruft keinen lokalen Generator"


def test_gebirge_und_ozean_sind_barrieren():
    biome = {b["id"]: b for b in _json("world/data/biome.json")["biome"]}
    assert biome["gebirge"]["barriere"] is True
    assert biome["ozean"]["barriere"] is True
    assert biome["gemaaessigt"].get("barriere", False) is False
    basis = _lies("world/logic/kategorie_biom/biom_basis.gd")
    assert "var barriere: bool = false" in basis
    assert 'eintrag.get("barriere", false)' in basis


def test_ebenen_trennen_makro_und_lokal():
    """Gebirge und Ozean gehoeren der Makroebene, die lokale Karte zieht nur lokale Biome."""
    gewichte = _json("world/data/generator_gewichte.json")["biome"]
    assert gewichte["biom_gebirge"]["ebene"] == "makro"
    assert gewichte["biom_ozean"]["ebene"] == "makro"
    for lokal in ("biom_gemaaessigt", "biom_tundra", "biom_steppe"):
        assert gewichte[lokal]["ebene"] == "lokal"
    verteilung = _lies("world/logic/kategorie_generator/generator_verteilung.gd")
    assert "ebene: String = \"\"" in verteilung, "Der Ebenenfilter sitzt im Los"
    generator = _lies("world/logic/kategorie_generator/welt_generator.gd")
    assert '"lokal")' in generator, "Die lokale Karte zieht ausschliesslich lokale Biome"


def test_netzwerk_planer_meidet_barrieren():
    code = _lies("world/logic/kategorie_welt/welt_netzwerk_planer.gd")
    assert "func ist_barriere_region(" in code
    assert "func _linie_frei(" in code
    assert "func _start_region_waehlen(" in code
    assert "biome: Welt_BiomRegistry = null" in code, "Das Biom kommt von aussen, keine zweite Ladung"
    assert "or ist_barriere_region(model, reg_pos)" in code, "Keine Fraktion auf einer Barriere"
    assert "if not _linie_frei(model, aktive_spieler_region" in code, "Kein Weg quer durch die Barriere"


def test_weltkarte_nutzt_die_makroebene():
    code = _lies("world/scenes/welt_map.gd")
    assert "Welt_MakroGenerator.new()" in code
    assert "_makro.karte_planen(_model, _registry, seed_wert)" in code
    assert "Welt_Generator.new()" not in code, "Die Weltkarte faehrt keinen lokalen Generator mehr"
    assert "_barriere_zeichen" in code, "Gebirge und Ozean sind sichtbar markiert"


def test_lagerfeuer_traegt_startvorrat():
    gebaeude = {g["id"]: g for g in _json("world/data/gebaeude.json")}
    startbestand = gebaeude["lagerfeuer"]["startbestand"]
    assert startbestand["holz"] > 0 and startbestand["beeren"] > 0
    assert "startbestand" not in gebaeude["haus"], "Nur der Ankunftsort bringt Vorrat mit"
    definition = _lies("world/logic/kategorie_objekt/gebaeude_definition.gd")
    assert "var startbestand: Dictionary = {}" in definition
    manager = _lies("world/logic/kategorie_objekt/gebaeude_manager.gd")
    assert "func _startbestand_einbuchen(" in manager
    assert "_startbestand_einbuchen(definition, lager_index)" in manager


def test_phase_eins_bleibt_geschlossen():
    """Bau-Aktionen bleiben aus dem Kontextmenue, das Panel ist die einzige Bau-Wahl."""
    steuerung = _json("game/data/steuerung.json")
    aktionen = {a["id"]: a for a in steuerung["kontextmenue"]["aktionen"]}
    assert not any(a_id.startswith("bauen_") for a_id in aktionen)
    assert set(aktionen.keys()) == {"sammeln", "abbauen", "marschieren", "expansieren"}
