# -*- coding: utf-8 -*-
"""TDD RED test: WarnungsScan muss SHADOWED_VARIABLE für Node2D.position
und für Member-Variable welt_position erkennen.

Ohne diese Korrektur unterdrückte der Scanner position/text pauschal,
sodass Godots echte Warnungen SHADOWED_VARIABLE_BASE_CLASS und
SHADOWED_VARIABLE in den 5 gemeldeten Zeilen unentdeckt blieben.
"""
import pathlib
import sys

PROJEKT = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(PROJEKT))

from tools.warnungs_scan import WarnungsScan

def _befunde_fuer(code: str):
    scan = WarnungsScan(PROJEKT)
    # scanne erwartet (Path, code) Paare; nutze Dummy-Pfad
    dummy = PROJEKT / "world/logic/kategorie_welt/welt_objekt_darsteller.gd"
    return scan._datei_scannen(dummy.relative_to(PROJEKT), code)

def test_node2d_position_parameter_wird_als_schatten_gemeldet():
    code = (
        "extends Node2D\n"
        "class_name Welt_ObjektDarsteller\n"
        "func objekt_darstellen(objekt: Objekt_Basis, position: Vector2) -> void:\n"
        "\tpass\n"
    )
    befunde = _befunde_fuer(code)
    schatten = [b for b in befunde if b.klasse == "SHADOWED_VARIABLE" and "position" in b.meldung]
    assert len(schatten) >= 1, f"Erwartet SHADOWED_VARIABLE für position (Node2D Basis), bekam: {[(b.klasse, b.meldung) for b in befunde]}"

def test_refcounted_welt_position_parameter_wird_als_schatten_gemeldet():
    code = (
        "extends RefCounted\n"
        "class_name Einheit_Status\n"
        "var welt_position := Vector2.ZERO\n"
        "func _auf_eigenen_tod(welt_position: Vector2) -> void:\n"
        "\tpass\n"
    )
    dummy = PROJEKT / "game/logic/kategorie_einheit/einheit_status.gd"
    scan = WarnungsScan(PROJEKT)
    befunde = scan._datei_scannen(dummy.relative_to(PROJEKT), code)
    schatten = [b for b in befunde if b.klasse == "SHADOWED_VARIABLE" and "welt_position" in b.meldung]
    assert len(schatten) >= 1, f"Erwartet SHADOWED_VARIABLE für welt_position (Member-Variable), bekam: {[(b.klasse, b.meldung) for b in befunde]}"

def test_node2d_text_parameter_wird_als_schatten_gemeldet():
    code = (
        "extends Control\n"
        "func _uebergang_einlaeuten(ziel: String, text: String) -> void:\n"
        "\tpass\n"
    )
    dummy = PROJEKT / "ui/scenes/hauptmenue.gd"
    scan = WarnungsScan(PROJEKT)
    befunde = scan._datei_scannen(dummy.relative_to(PROJEKT), code)
    schatten = [b for b in befunde if b.klasse == "SHADOWED_VARIABLE" and "text" in b.meldung]
    assert len(schatten) >= 1, f"Erwartet SHADOWED_VARIABLE für text (Control Basis), bekam: {[(b.klasse, b.meldung) for b in befunde]}"

def test_refcounted_position_ohne_basis_wird_nicht_gemeldet():
    """RefCounted hat keine position-Eigenschaft — dort darf kein False-Positive entstehen."""
    code = (
        "extends RefCounted\n"
        "func foo(position: Vector2) -> void:\n"
        "\tprint(position)\n"
    )
    dummy = PROJEKT / "core/logic/kern_zufall.gd"
    # core/logic/kern_zufall.gd ist RefCounted-nah; entscheide über extends
    scan = WarnungsScan(PROJEKT)
    befunde = scan._datei_scannen(dummy.relative_to(PROJEKT), code)
    schatten = [b for b in befunde if b.klasse == "SHADOWED_VARIABLE" and "position" in b.meldung]
    assert len(schatten) == 0, f"RefCounted position sollte kein SHADOWED_VARIABLE sein, bekam: {[(b.klasse, b.meldung) for b in befunde]}"

if __name__ == "__main__":
    for fn in [test_node2d_position_parameter_wird_als_schatten_gemeldet,
               test_refcounted_welt_position_parameter_wird_als_schatten_gemeldet,
               test_node2d_text_parameter_wird_als_schatten_gemeldet,
               test_refcounted_position_ohne_basis_wird_nicht_gemeldet]:
        try:
            fn()
            print(f"PASS {fn.__name__}")
        except AssertionError as e:
            print(f"FAIL {fn.__name__}: {e}")
