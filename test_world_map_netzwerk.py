# -*- coding: utf-8 -*-
"""TDD-Testsuite für Priorität 2: World Map, Fraktionen und Netzwerk (ODO-12 bis ODO-15).

Verlangt:
1. generator_gewichte.json definiert mindestens 3 Fraktionen mit Biom-Vorlieben.
2. Welt_Fraktion existiert als eigene Datenklasse.
3. Welt_NetzwerkPlaner platziert Fraktionen deterministisch und berechnet Wege.
4. Der Startbereich besitzt mindestens zwei direkte Nachbarn im Fraktionsnetzwerk.
5. Ui_WeltSitzung führt Startbereich und Netzwerk-Daten für die lokale Generierung.
"""
import json
import pathlib
import re

PROJEKT = pathlib.Path(__file__).resolve().parent


def _lies(rel: str) -> str:
    return (PROJEKT / rel).read_text(encoding="utf-8")


def _json(rel: str):
    return json.loads(_lies(rel))


def test_generator_gewichte_traegt_fraktionen():
    """generator_gewichte.json enthält konfigurierte Fraktionen mit Biom-Vorlieben."""
    gewichte = _json("world/data/generator_gewichte.json")
    fraktionen = gewichte.get("fraktionen", {})
    assert len(fraktionen) >= 3, "Mindestens 3 Fraktionen müssen in generator_gewichte.json definiert sein"
    for f_id, f_daten in fraktionen.items():
        assert f_daten.get("kategorie") == "fraktionen", f"{f_id}: kategorie muss 'fraktionen' sein"
        assert "name" in f_daten, f"{f_id}: Name fehlt"
        assert "biome" in f_daten and len(f_daten["biome"]) > 0, f"{f_id}: Biom-Vorliebe fehlt"
        assert "farbe" in f_daten, f"{f_id}: Farbe fehlt"


def test_welt_fraktion_klasse_existiert():
    """Welt_Fraktion ist eine eigene getypte Datenklasse mit Pflichtfeldern."""
    skript = _lies("world/logic/kategorie_welt/welt_fraktion.gd")
    assert "class_name Welt_Fraktion" in skript
    assert "## Kategorie daten" in skript
    assert "## Kategorie logik" in skript
    for feld in ("fraktion_id", "angezeigter_name", "bevorzugte_biome", "farbe", "position_kachel"):
        assert re.search(r"\bvar %s\b" % feld, skript), f"Feld {feld} fehlt in Welt_Fraktion"


def test_welt_netzwerk_planer_existiert():
    """Welt_NetzwerkPlaner berechnet Fraktionen, Nachbarn und Pfade."""
    skript = _lies("world/logic/kategorie_welt/welt_netzwerk_planer.gd")
    assert "class_name Welt_NetzwerkPlaner" in skript
    assert "## Kategorie daten" in skript
    assert "## Kategorie logik" in skript
    assert "netzwerk_planen" in skript
    assert "nachbarn_fuer" in skript
    assert "wege" in skript


def test_sitzung_traegt_startbereich_und_netzwerk():
    """Ui_WeltSitzung hält die Startkontext-Felder für die lokale Kartengenerierung."""
    skript = _lies("ui/logic/kategorie_ui/ui_welt_sitzung.gd")
    for feld in ("start_region_x", "start_region_y", "start_biom_id", "fraktionen_netzwerk"):
        assert re.search(r"\bvar %s\b" % feld, skript), f"Feld {feld} fehlt in Ui_WeltSitzung"
