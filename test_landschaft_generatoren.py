import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent

def test_generatoren_skripte_existieren():
    gewaesser_pfad = ROOT / 'world' / 'logic' / 'kategorie_generator' / 'generator_gewaesser.gd'
    assert gewaesser_pfad.exists()
    inhalt_g = gewaesser_pfad.read_text(encoding='utf-8')
    assert 'class_name Welt_GeneratorGewaesser' in inhalt_g
    assert 'func erzeugen(' in inhalt_g

    fels_pfad = ROOT / 'world' / 'logic' / 'kategorie_generator' / 'generator_felsmassive.gd'
    assert fels_pfad.exists()
    inhalt_f = fels_pfad.read_text(encoding='utf-8')
    assert 'class_name Welt_GeneratorFelsmassive' in inhalt_f
    assert 'func erzeugen(' in inhalt_f

def test_generator_gewichte_cluster_und_objekte():
    gewichte_pfad = ROOT / 'world' / 'data' / 'generator_gewichte.json'
    with open(gewichte_pfad, 'r', encoding='utf-8') as f:
        daten = json.load(f)

    objekte = daten.get('objekte', {})
    for o in ['berg', 'felswand', 'erzader', 'ruine', 'steinkreis']:
        assert o in objekte, f'Objekt {o} fehlt in generator_gewichte.json'

    cluster = daten.get('cluster', {})
    for c in ['felsmassiv', 'erzlager', 'ruinenfeld', 'steinkreis_fund']:
        assert c in cluster, f'Cluster {c} fehlt in generator_gewichte.json'

def test_welt_generator_integration():
    inhalt = (ROOT / 'world' / 'logic' / 'kategorie_generator' / 'welt_generator.gd').read_text(encoding='utf-8')
    assert '_GewaesserSkript := preload' in inhalt
    assert '_FelsmassiveSkript := preload' in inhalt
    assert 'gewaesser = _GewaesserSkript.new()' in inhalt
    assert 'felsmassive = _FelsmassiveSkript.new()' in inhalt
    assert 'gewaesser.erzeugen(model' in inhalt
    assert 'felsmassive.erzeugen(model' in inhalt
