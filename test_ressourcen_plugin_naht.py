# -*- coding: utf-8 -*-
"""TDD RED-Test für Slice B: Ressourcen-Plugin-Naht.

Verlangt: Einheit_Ressourcen lädt die Datenklasse je Eintrag über das
script-Feld aus game/data/ressourcen.json. Raeuchelfleisch (Asset und
Icon existieren, aber keine Klasse und kein Zuordnungszweig) bekommt
seine eigene Klasse, und die Zuordnung bleibt nur Fallback.
"""
import pathlib

PROJEKT = pathlib.Path(__file__).resolve().parent

def test_ressourcen_eintraege_tragen_script_feld():
    """Jeder Pool-Eintrag braucht ein script-Feld auf eine existierende .gd."""
    import json
    pool = json.loads((PROJEKT / "game/data/ressourcen.json").read_text(encoding="utf-8"))
    assert "raeuchelfleisch" in pool, "Raeuchelfleisch muss im Pool stehen"
    for ressourcen_id, eintrag in pool.items():
        skript = str(eintrag.get("script", ""))
        assert skript != "", f"Ressource '{ressourcen_id}' trägt kein script-Feld"
        ziel = PROJEKT / skript.replace("res://", "")
        assert ziel.is_file(), f"script-Feld von '{ressourcen_id}' zeigt auf fehlende Datei: {skript}"

def test_raeuchelfleisch_hat_eigene_klasse():
    """Die Klasse des Raeuchelfleischs existiert und erbt Ressource_Basis."""
    klassen_pfad = PROJEKT / "game/logic/kategorie_ressourcen/ressource_raeuchelfleisch.gd"
    assert klassen_pfad.is_file(), "ressource_raeuchelfleisch.gd fehlt"
    text = klassen_pfad.read_text(encoding="utf-8")
    assert "extends Ressource_Basis" in text, "Klasse muss Ressource_Basis erweitern"
    assert "class_name Ressource_Raeuchelfleisch" in text

def test_einheit_ressourcen_besitzt_script_naht():
    """Die Zuordnung lädt zuerst das script-Feld, Fallback bleibt match."""
    quelle = (PROJEKT / "game/logic/kategorie_einheit/einheit_ressourcen.gd").read_text(encoding="utf-8")
    assert "ResourceLoader.exists" in quelle, (
        "Einheit_Ressourcen._ressourcen_klasse_fuer muss das script-Feld laden (Muster aus Job_Registry)")
    assert "match ressourcen_id" in quelle, "Zentrale Zuordnung bleibt als Fallback"

if __name__ == "__main__":
    for fn in [test_ressourcen_eintraege_tragen_script_feld,
               test_raeuchelfleisch_hat_eigene_klasse,
               test_einheit_ressourcen_besitzt_script_naht]:
        try:
            fn()
            print(f"PASS {fn.__name__}")
        except AssertionError as e:
            print(f"FAIL {fn.__name__}: {e}")
