# -*- coding: utf-8 -*-
"""TDD RED-Test für Slice M1: Eskalationsketten der Mood-Modifikatoren.

Verlangt am Code: Jeder Eintrag in population/data/mood_modifikatoren.json
trägt eine Eskalationskette, in der eine Stufe in die nächste greift, die
Sprechblase Grund und Wirkung im Emoji-Stil erzählt, und die Maschine die
Stufe ausschließlich aus den Daten ableitet statt aus eigenen Zahlen.
Vorher kannte jeder Modifikator genau eine Zeile: eine Sprechblase, ein
Verhalten, kein Grund, keine Wirkung, keine Verzahnung.
"""
import json
import pathlib
import re

PROJEKT = pathlib.Path(__file__).resolve().parent

MODS = json.loads((PROJEKT / "population/data/mood_modifikatoren.json").read_text(encoding="utf-8"))
STUFEN_FELDER = ("stufe", "schwelle", "emoji", "grund", "wirkung", "verhalten")


def _lies(rel: str) -> str:
    return (PROJEKT / rel).read_text(encoding="utf-8")


def _mods():
    return {k: v for k, v in MODS.items() if not k.startswith("_")}


def test_jedes_mod_traegt_eine_eskalationskette():
    """Jeder Modifikator eskaliert in mehreren Stufen statt in einer Zeile."""
    for mod_id, eintrag in _mods().items():
        kette = eintrag.get("eskalation")
        assert isinstance(kette, list), "%s: keine Eskalationskette" % mod_id
        assert len(kette) >= 2, "%s: Kette braucht mindestens zwei Stufen" % mod_id
        for stufe in kette:
            fehlend = [feld for feld in STUFEN_FELDER if str(stufe.get(feld, "")).strip() == ""]
            assert not fehlend, "%s/Stufe %s: %s fehlen" % (mod_id, stufe.get("stufe"), fehlend)


def test_stufen_steigen_lueckenlos_und_schwellen_wachsen():
    """Die Stufen zählen 1..n, und jede höhere Stufe verlangt mehr Not."""
    for mod_id, eintrag in _mods().items():
        kette = eintrag["eskalation"]
        nummern = [int(stufe["stufe"]) for stufe in kette]
        assert nummern == list(range(1, len(kette) + 1)), "%s: Stufennummern %s" % (mod_id, nummern)
        schwellen = [float(stufe["schwelle"]) for stufe in kette]
        assert all(b > a for a, b in zip(schwellen, schwellen[1:])), \
            "%s: Schwellen steigen nicht (%s)" % (mod_id, schwellen)


def test_kette_verzahnt_sich_ueber_folge_mod():
    """Mindestens eine Kette greift in eine andere über, und die hat selbst Stufen."""
    verzahnungen = []
    for mod_id, eintrag in _mods().items():
        folge = str(eintrag["eskalation"][-1].get("folge_mod_id", ""))
        assert folge == "" or folge in MODS, "%s: unbekannte folge_mod_id '%s'" % (mod_id, folge)
        if folge:
            verzahnungen.append((mod_id, folge))
    assert verzahnungen, "keine Kette greift in eine andere über"
    for mod_id, folge in verzahnungen:
        assert MODS[folge].get("eskalation"), "%s -> %s hat keine eigene Kette" % (mod_id, folge)


def test_stufenklasse_existiert_und_wird_getypt_gelesen():
    """Jede Stufe ist eine eigene Datenklasse, die der Modifikator getypt liest."""
    klasse = _lies("population/logic/mood/pop_mood_eskalation_stufe.gd")
    assert "class_name Pop_MoodEskalationStufe" in klasse, "Stufenklasse fehlt"
    for feld in STUFEN_FELDER + ("folge_mod_id",):
        assert re.search(r"\bvar %s\b" % feld, klasse), "Stufenklasse ohne Feld %s" % feld
    modifikator = _lies("population/logic/mood/pop_mood_modifikator.gd")
    assert "Array[Pop_MoodEskalationStufe]" in modifikator, "Modifikator liest die Kette nicht getypt"
    assert "stufe_fuer" in modifikator, "Modifikator kann seine Stufe nicht wählen"


def test_die_blase_erzaehlt_grund_und_wirkung():
    """Die Mood trägt Grund und Wirkung, und die Denkblase erzählt beides."""
    mood = _lies("population/logic/mood/pop_mood.gd")
    for feld in ("grund", "wirkung", "verhalten", "stufe", "kette"):
        assert re.search(r"\bvar %s\b" % feld, mood), "Pop_Mood ohne Feld %s" % feld
    assert "erzaehlung" in mood, "Pop_Mood erzählt Grund und Wirkung nicht"
    blase = _lies("population/logic/mood/pop_denkblase.gd")
    assert "erzaehlung" in blase, "Denkblase nutzt die Erzählung nicht"


def test_maschine_liest_die_stufen_aus_den_daten():
    """Die Maschine wählt die Stufe über die Registry und kennt keine harte Schwelle."""
    maschine = _lies("population/logic/mood/pop_mood_maschine.gd")
    assert "stufe_fuer" in maschine, "Maschine wählt keine Eskalationsstufe"
    registry = _lies("population/logic/mood/pop_mood_modifikator_registry.gd")
    assert "mod_fuer_need" in registry, "Registry ordnet keinen Bedarf zu"
    schwellen = {float(stufe["schwelle"]) for eintrag in _mods().values() for stufe in eintrag["eskalation"]}
    literale = {float(x) for x in re.findall(r"(?<![\w.])(\d+\.\d+)(?![\w])", maschine)}
    treffer = sorted(schwellen & literale)
    assert not treffer, "harte Eskalationsschwellen im Code: %s" % treffer
