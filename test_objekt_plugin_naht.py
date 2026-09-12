# -*- coding: utf-8 -*-
"""TDD RED-Test für Slice A: Objekt-Plugin-Naht.

Verlangt: Objekt_RegistryBasis lädt die Datenklasse je Eintrag über das
script-Feld aus world/data/element_katalog.json. Ein neues Objekt soll
künftig nur mit Katalog-Eintrag plus SVG erscheinen, ohne dass Welt_Registry
angefasst wird. Die zentrale Zuordnung bleibt nur Fallback für Einträge
ohne script-Feld.
"""
import importlib.util
import pathlib
import sys

PROJEKT = pathlib.Path(__file__).resolve().parent

def _lade(name, rel):
    spez = importlib.util.spec_from_file_location(name, str(PROJEKT / rel))
    modul = importlib.util.module_from_spec(spez)
    sys.modules[name] = modul
    spez.loader.exec_module(modul)
    return modul

KATALOG_OBJEKTE_MIT_KLASSE = {
    "boden": "objekt_kachel.gd", "wiese": "objekt_kachel.gd",
    "baum": "objekt_baum.gd", "baum_stumpf": "objekt_baumstumpf.gd",
    "stein": "objekt_stein.gd", "steine_gruppe": "objekt_steingruppe.gd",
    "haus": "objekt_haus.gd", "haus_gross": "objekt_hausgross.gd",
    "kadaver": "objekt_kadaver.gd", "lagerfeuer": "objekt_lagerfeuer.gd",
}

def test_katalog_objekte_sind_ueber_script_ordenbar():
    """Jedes Registry-Objekt mit eigener Datenklasse braucht das script-Feld.

    Tier-Einträge (baer, hase, ...) laufen über Tier_Registry/tier_verhalten.json
    und gehören nicht in diese Naht; Einträge ohne eigene Klasse (busch,
    werkstatt, raeucherei) bleiben bewusst im Fallback Objekt_Basis.
    """
    import json
    katalog = json.loads((PROJEKT / "world/data/element_katalog.json").read_text(encoding="utf-8"))
    nach_id = {str(e.get("id")): e for e in katalog}
    for element_id, klasse in KATALOG_OBJEKTE_MIT_KLASSE.items():
        assert element_id in nach_id, f"Katalog-Eintrag '{element_id}' fehlt"
        skript = str(nach_id[element_id].get("script", ""))
        assert skript.endswith(klasse), (
            f"Eintrag '{element_id}' trägt nicht script -> {klasse}, sondern: '{skript}'")
        ziel = PROJEKT / skript.replace("res://", "")
        assert ziel.is_file(), f"script-Feld von '{element_id}' zeigt auf fehlende Datei: {skript}"

def test_welt_registry_enthaelt_script_naht():
    """Die Registry-Naht lädt zuerst das script-Feld, Fallback bleibt match."""
    quelle = (PROJEKT / "world/logic/kategorie_objekt/objekt_registry_basis.gd").read_text(encoding="utf-8")
    assert "script" in quelle and "ResourceLoader.exists" in quelle, (
        "Objekt_RegistryBasis muss das script-Feld laden (Muster aus Job_Registry)")

def test_welt_registry_match_ist_fallback_nicht_ersatz():
    """Die zentrale Zuordnung bleibt als Fallback bestehen (Abwärtskompatibilität)."""
    quelle = (PROJEKT / "world/logic/kategorie_welt/welt_registry.gd").read_text(encoding="utf-8")
    # Der Fallback lebt nach dem Registry-Umbau als _zentrale_klasse_fuer
    # mit seinem match weiter; das script-Feld der Basis bleibt erste Wahl.
    assert "_zentrale_klasse_fuer" in quelle and "match" in quelle

if __name__ == "__main__":
    for fn in [test_katalog_objekte_sind_ueber_script_ordenbar,
               test_welt_registry_enthaelt_script_naht,
               test_welt_registry_match_ist_fallback_nicht_ersatz]:
        try:
            fn()
            print(f"PASS {fn.__name__}")
        except AssertionError as e:
            print(f"FAIL {fn.__name__}: {e}")
