from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent

def test_welt_szene_y_sort_konfiguration():
    inhalt = (ROOT / "world" / "scenes" / "welt.tscn").read_text(encoding="utf-8")
    assert 'y_sort_enabled = true' in inhalt
    assert '[node name="Welt" type="Node2D"]\ny_sort_enabled = true' in inhalt
    assert '[node name="Karte" type="Node2D" parent="."]\nunique_name_in_owner = true\ny_sort_enabled = true' in inhalt
    assert '[node name="Tiere" type="Node2D" parent="."]\nunique_name_in_owner = true\ny_sort_enabled = true' in inhalt

def test_welt_renderer_y_sort_und_fliesen_hintergrund():
    inhalt = (ROOT / "world" / "logic" / "kategorie_welt" / "welt_renderer.gd").read_text(encoding="utf-8")
    assert "y_sort_enabled = true" in inhalt
    assert "knoten.z_index = -1" in inhalt
    assert "_objekte_knoten.y_sort_enabled = true" in inhalt

def test_tier_darstellung_und_y_sort():
    manager_inhalt = (ROOT / "world" / "logic" / "kategorie_tier" / "tier_manager.gd").read_text(encoding="utf-8")
    assert "y_sort_enabled = true" in manager_inhalt
    assert "_darsteller_ebene.y_sort_enabled = true" in manager_inhalt

    darsteller_inhalt = (ROOT / "world" / "logic" / "kategorie_tier" / "tier_darsteller.gd").read_text(encoding="utf-8")
    assert "centered = true" in darsteller_inhalt
    assert "offset = Vector2(0.0, -groesse.y * 0.5)" in darsteller_inhalt

def test_einheit_darstellung_und_y_sort():
    manager_inhalt = (ROOT / "game" / "logic" / "kategorie_einheit" / "einheit_manager.gd").read_text(encoding="utf-8")
    assert "y_sort_enabled = true" in manager_inhalt

    darsteller_inhalt = (ROOT / "game" / "logic" / "kategorie_einheit" / "einheit_darsteller.gd").read_text(encoding="utf-8")
    assert "centered = true" in darsteller_inhalt
    assert "offset = Vector2(0.0, -standard_hoehe * 0.5)" in darsteller_inhalt

def test_welt_landeplatz_anzeige_klasse():
    pfad = ROOT / "world" / "logic" / "kategorie_welt" / "welt_landeplatz_anzeige.gd"
    assert pfad.exists(), "welt_landeplatz_anzeige.gd muss existieren"
    inhalt = pfad.read_text(encoding="utf-8")
    assert "class_name Welt_LandeplatzAnzeige" in inhalt
    assert "func einrichten(" in inhalt
    assert "func ausblenden(" in inhalt
    assert "func _process(" in inhalt
    assert "func _draw(" in inhalt

def test_welt_szene_landeplatz_integration():
    inhalt = (ROOT / "world" / "scenes" / "welt.gd").read_text(encoding="utf-8")
    assert "_LandeplatzAnzeigeSkript := preload" in inhalt
    assert "var _landeplatz: Node2D = null" in inhalt
    assert "_landeplatz = _LandeplatzAnzeigeSkript.new()" in inhalt
    assert "_landeplatz.einrichten(start_position" in inhalt
    assert "_landeplatz.ausblenden()" in inhalt
