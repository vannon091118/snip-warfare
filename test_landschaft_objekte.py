import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent

def test_neue_objekt_skripte_existieren():
    objekte = ['berg', 'felswand', 'erzader', 'ruine', 'steinkreis']
    for name in objekte:
        skript_pfad = ROOT / 'world' / 'logic' / 'kategorie_objekt' / f'objekt_{name}.gd'
        assert skript_pfad.exists(), f'Skript fehlt: {skript_pfad}'
        inhalt = skript_pfad.read_text(encoding='utf-8')
        assert f'class_name Objekt_{name.capitalize()}' in inhalt
        assert 'extends Objekt_Basis' in inhalt
        assert 'func aus_katalog_eintrag(' in inhalt

def test_neue_svg_assets_existieren():
    objekte = ['berg', 'felswand', 'erzader', 'ruine', 'steinkreis']
    for name in objekte:
        svg_pfad = ROOT / 'world' / 'assets' / 'terrain' / f'{name}.svg'
        assert svg_pfad.exists(), f'SVG fehlt: {svg_pfad}'
        assert svg_pfad.stat().st_size > 50

def test_element_katalog_enthaelt_neue_objekte():
    katalog_pfad = ROOT / 'world' / 'data' / 'element_katalog.json'
    with open(katalog_pfad, 'r', encoding='utf-8') as f:
        katalog = json.load(f)
    
    gefundene = {eintrag['id']: eintrag for eintrag in katalog if 'id' in eintrag}
    for name in ['berg', 'felswand', 'erzader', 'ruine', 'steinkreis']:
        assert name in gefundene, f'{name} nicht im Element-Katalog'
        eintrag = gefundene[name]
        assert eintrag['kategorie'] == 'Natur'
        assert eintrag['typ'] == 'objekt'
        assert eintrag['textur_pfad'] == f'res://world/assets/terrain/{name}.svg'
        assert eintrag['script'] == f'res://world/logic/kategorie_objekt/objekt_{name}.gd'

def test_welt_registry_fallbacks():
    """Die Klassen-Zuordnung der Landschaftsobjekte lebt seit dem
    Zerlegungs-Slice in der eigenen Tabelle welt_registry_klassen_zuordnung.gd;
    die Registry-Fassade laedt sie ueber den Plugin-Naht-Pfad."""
    zuordnung = (ROOT / 'world' / 'logic' / 'kategorie_welt' / 'welt_registry_klassen_zuordnung.gd').read_text(encoding='utf-8')
    for name in ['berg', 'felswand', 'erzader', 'ruine', 'steinkreis']:
        assert f'"{name}":' in zuordnung
        assert f'"Objekt_{name.capitalize()}"' in zuordnung
