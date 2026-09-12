import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent

def test_baustellen_dateien_und_klassen():
    bedarf_pfad = ROOT / "world" / "logic" / "kategorie_welt" / "welt_baustellen_bedarf.gd"
    assert bedarf_pfad.exists()
    assert "class_name Welt_BaustellenBedarf" in bedarf_pfad.read_text(encoding="utf-8")

    transport_pfad = ROOT / "game" / "logic" / "kategorie_einheit" / "einheit_transport_maschine.gd"
    assert transport_pfad.exists()
    assert "class_name Einheit_TransportMaschine" in transport_pfad.read_text(encoding="utf-8")

    job_pfad = ROOT / "game" / "logic" / "kategorie_job" / "job_baustelle_beliefern.gd"
    assert job_pfad.exists()
    assert "class_name Job_BaustelleBeliefern" in job_pfad.read_text(encoding="utf-8")

    geist_pfad = ROOT / "world" / "logic" / "kategorie_welt" / "welt_bau_geist.gd"
    assert geist_pfad.exists()
    assert "class_name Welt_BauGeist" in geist_pfad.read_text(encoding="utf-8")

def test_job_config_baustelle_beliefern():
    config_pfad = ROOT / "game" / "data" / "job_config.json"
    with open(config_pfad, "r", encoding="utf-8") as f:
        config = json.load(f)
    assert "baustelle_beliefern" in config
    eintrag = config["baustelle_beliefern"]
    assert eintrag["script"] == "res://game/logic/kategorie_job/job_baustelle_beliefern.gd"
    assert eintrag["ressource"] == "baumaterial"

def test_bau_maschine_phase_bauplan():
    bau_maschine_pfad = ROOT / "world" / "logic" / "kategorie_objekt" / "gebaeude_bau_maschine.gd"
    inhalt = bau_maschine_pfad.read_text(encoding="utf-8")
    assert "BAUPLAN" in inhalt
    assert 'Phase.BAUPLAN: "Bauplan"' in inhalt
    assert "func bauplan_anlegen(" in inhalt

def test_gebaeude_manager_bauplan():
    manager_pfad = ROOT / "world" / "logic" / "kategorie_objekt" / "gebaeude_manager.gd"
    inhalt = manager_pfad.read_text(encoding="utf-8")
    assert "func bauplan_anfordern(" in inhalt
    laufzeit_pfad = ROOT / "world" / "logic" / "kategorie_objekt" / "gebaeude_laufzeit.gd"
    laufzeit = laufzeit_pfad.read_text(encoding="utf-8")
    assert "_ist_material_vollstaendig(" in laufzeit, "Die Material-Pruefung wohnt in der Laufzeit"
    assert "_laufzeit.gebaeude_ticken(" in inhalt, "Der Manager leitet den Tick an die Laufzeit weiter"

def test_ui_rechtsklick_priorisierung():
    maschine_pfad = ROOT / "ui" / "logic" / "kategorie_ui" / "ui_job_vergabe_maschine.gd"
    inhalt = maschine_pfad.read_text(encoding="utf-8")
    assert "func baustelle_priorisieren(" in inhalt, "Die Priorisierung wohnt in der Job-Vergabe-Maschine"
