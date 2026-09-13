# -*- coding: utf-8 -*-
"""Beweis-Test des Roadmap-Abgleichs: Der Mechanismus darf nicht schmeicheln.

Der Test fuehrt den Mechanismus nicht gegen die echte Roadmap aus, sondern
gegen erfundene Belegstaende. Nur so lassen sich die harten Faelle pruefen:
ein gruener Beweis darf abhaken, ein roter nie, ein ungepruefter nie, und eine
blosse Klassendeckung schon gar nicht.
"""

import sys
from pathlib import Path

WURZEL = Path(__file__).resolve().parent
sys.path.insert(0, str(WURZEL / "tools"))

from roadmap.abhaken import abhaken, beurteilen          # noqa: E402
from roadmap.befund import (ABHAK_BEREIT, FEHLENDE_KLASSE, FALSCH,   # noqa: E402
                            KLASSEN_SCHON_DA, ROTER_BEWEIS, UNGEPRUEFT,
                            UNBELEGT, befunde_sammeln, bericht)
from roadmap.beweis import GRUEN, ROT, UNGEPRUEFT as UNGEPRUEFT_BELEG, Beleg  # noqa: E402
from roadmap.checkpoint import checkpoints_lesen, doppelte_nummern  # noqa: E402

KOPF = "# Testroadmap\n\n### Slice X: Erfundener Slice\n"


class StummerBeweisstand:
    """Ein Beweisstand, der die vorbereiteten Belege zurueckgibt.

    Die Belege duerfen als Liste fuer alle Eintraege gelten oder als Dictionary
    je CP-Nummer. Ohne diese Unterscheidung bekaeme jeder Eintrag dasselbe
    Urteil, und der Test wuerde eine Eigenschaft des Stubs pruefen statt eine
    des Mechanismus.
    """

    def __init__(self, beweis=None, klassen=None):
        self._beweis = beweis if beweis is not None else []
        self._klassen = klassen if klassen is not None else []

    @staticmethod
    def _waehlen(quelle, checkpoint):
        if isinstance(quelle, dict):
            return quelle.get(checkpoint.nummer, [])
        return quelle

    def beweis_belege(self, checkpoint):
        return self._waehlen(self._beweis, checkpoint)

    def klassen_belege(self, checkpoint):
        return self._waehlen(self._klassen, checkpoint)


def _urfassung(zeilen):
    return KOPF + "\n".join(zeilen) + "\n"


def test_parser_liest_status_nummer_und_kapitel():
    text = _urfassung(["- [x] **CP-1.1 (Gating):** Fertig. Beweis: `test_a.py`.",
                       "- [ ] **CP-1.2:** Offen.",
                       "- [~] **CP-1.3 (Halb):** Halb."])
    eintraege = checkpoints_lesen(text)
    assert [e.nummer for e in eintraege] == ["CP-1.1", "CP-1.2", "CP-1.3"]
    assert [e.titel for e in eintraege] == ["Gating", "", "Halb"]
    assert eintraege[0].ist_fertig and not eintraege[0].ist_offen
    assert eintraege[1].ist_offen and not eintraege[1].ist_fertig
    assert eintraege[2].ist_teilweise
    assert eintraege[0].kapitel == "Slice X: Erfundener Slice"


def test_parser_trennt_beweise_von_gegenstaenden():
    text = _urfassung([
        "- [ ] **CP-2.1:** `Welt_Model` liegt in `world/data/gebaeude.json`. "
        "Beweis: `test_einstiegs_progression.py` und `tools/lauf_pruefung_hud.gd`."])
    eintrag = checkpoints_lesen(text)[0]
    assert eintrag.beweis_pfade() == ["test_einstiegs_progression.py",
                                      "tools/lauf_pruefung_hud.gd"]
    assert eintrag.klassen() == ["Welt_Model"]
    assert eintrag.hat_beweis()


def test_eintrag_ohne_beweis_hat_keinen_beweis():
    eintrag = checkpoints_lesen(_urfassung(["- [ ] **CP-3.1:** Nur Prosa."]))[0]
    assert eintrag.beweis_pfade() == []
    assert not eintrag.hat_beweis()


def test_doppelte_nummern_werden_erkannt():
    text = _urfassung(["- [x] **CP-0.15 (A):** Eins.",
                       "- [ ] **CP-0.15 (B):** Zwei.",
                       "- [x] **CP-0.16:** Drei."])
    doppelte = doppelte_nummern(checkpoints_lesen(text))
    assert list(doppelte) == ["CP-0.15"]
    assert doppelte["CP-0.15"] == [4, 5]


def test_abgehakte_zeile_bleibt_abgehakt():
    text = _urfassung(["- [x] **CP-4.1:** Schon fertig. Beweis: `test_a.py`."])
    neuer_text, abgehakt = abhaken(text, [])
    assert neuer_text == text
    assert abgehakt == []


def test_gruener_beweis_hakt_ab():
    text = _urfassung(["- [ ] **CP-5.1:** Reif. Beweis: `test_a.py`."])
    stand = StummerBeweisstand(beweis=[Beleg(GRUEN, "gruen")])
    neuer_text, abgehakt = abhaken(text, beurteilen(checkpoints_lesen(text), stand))
    assert "- [x] **CP-5.1:**" in neuer_text
    assert abgehakt == ["CP-5.1"]


def test_roter_beweis_hakt_nicht_ab():
    text = _urfassung(["- [ ] **CP-5.2:** Nicht reif. Beweis: `test_a.py`."])
    stand = StummerBeweisstand(beweis=[Beleg(ROT, "rot")])
    neuer_text, abgehakt = abhaken(text, beurteilen(checkpoints_lesen(text), stand))
    assert neuer_text == text
    assert abgehakt == []


def test_ungepruefter_beweis_hakt_nicht_ab():
    text = _urfassung(["- [ ] **CP-5.3:** Ungemessen. Beweis: `tools/lauf_pruefung_hud.gd`."])
    stand = StummerBeweisstand(beweis=[Beleg(UNGEPRUEFT_BELEG, "nicht gelaufen")])
    neuer_text, abgehakt = abhaken(text, beurteilen(checkpoints_lesen(text), stand))
    assert neuer_text == text
    assert abgehakt == []


def test_blosse_klassendeckung_hakt_nicht_ab():
    # Der wichtigste Fall: Die genannte Klasse existiert und ist verdrahtet,
    # aber niemand nennt eine ausfuehrbare Pruefung. Das Haekchen bleibt offen.
    text = _urfassung(["- [ ] **CP-6.1:** `Welt_Model` ist da."])
    stand = StummerBeweisstand(klassen=[Beleg(GRUEN, "verdrahtet")])
    neuer_text, abgehakt = abhaken(text, beurteilen(checkpoints_lesen(text), stand))
    assert neuer_text == text
    assert abgehakt == []


def test_reifer_eintrag_wird_als_abhak_bereit_gemeldet():
    text = _urfassung(["- [ ] **CP-6.5:** Reif. Beweis: `test_a.py`."])
    stand = StummerBeweisstand(beweis=[Beleg(GRUEN, "gruen")])
    gruppen, _ = befunde_sammeln(beurteilen(checkpoints_lesen(text), stand), {})
    assert [u.checkpoint.nummer for u in gruppen[ABHAK_BEREIT]] == ["CP-6.5"]


def test_befund_trennt_rot_von_ungeprueft():
    text = _urfassung(["- [x] **CP-7.1:** Fertig. Beweis: `test_a.py`.",
                       "- [x] **CP-7.2:** Fertig. Beweis: `test_b.py`."])
    stand = StummerBeweisstand(beweis={
        "CP-7.1": [Beleg(ROT, "rot")],
        "CP-7.2": [Beleg(UNGEPRUEFT_BELEG, "nicht gelaufen")],
    })
    gruppen, _ = befunde_sammeln(beurteilen(checkpoints_lesen(text), stand), {})
    assert [u.checkpoint.nummer for u in gruppen[FALSCH]] == ["CP-7.1"]
    assert [u.checkpoint.nummer for u in gruppen[UNGEPRUEFT]] == ["CP-7.2"]


def test_befund_meldet_fehlende_klasse_und_reife_klasse():
    text = _urfassung(["- [ ] **CP-8.1:** `Pop_Trait` fehlt noch.",
                       "- [ ] **CP-8.2:** `Welt_Model` ist da."])
    stand = StummerBeweisstand(klassen={
        "CP-8.1": [Beleg(ROT, "Klasse Pop_Trait existiert nirgends")],
        "CP-8.2": [Beleg(GRUEN, "verdrahtet")],
    })
    gruppen, _ = befunde_sammeln(beurteilen(checkpoints_lesen(text), stand), {})
    assert [u.checkpoint.nummer for u in gruppen[FEHLENDE_KLASSE]] == ["CP-8.1"]
    assert [u.checkpoint.nummer for u in gruppen[KLASSEN_SCHON_DA]] == ["CP-8.2"]


def test_befund_meldet_roten_beweis_bei_offenem_eintrag():
    text = _urfassung(["- [ ] **CP-9.1:** Beweis: `tools/lauf_pruefung_fraktionen.gd`."])
    stand = StummerBeweisstand(beweis=[Beleg(ROT, "Laufpruefung fehlt")])
    gruppen, _ = befunde_sammeln(beurteilen(checkpoints_lesen(text), stand), {})
    assert [u.checkpoint.nummer for u in gruppen[ROTER_BEWEIS]] == ["CP-9.1"]


def test_befund_ist_nummeriert_und_endet_mit_punkt():
    text = _urfassung(["- [ ] **CP-A.1:** `Welt_Model` ist da."])
    stand = StummerBeweisstand(klassen=[Beleg(GRUEN, "verdrahtet")])
    gruppen, doppelte = befunde_sammeln(beurteilen(checkpoints_lesen(text), stand), {})
    zeilen = bericht(gruppen, doppelte)
    saetze = [zeile for zeile in zeilen if zeile[:1].isdigit()]
    assert saetze, "Der Bericht muss mindestens einen nummerierten Satz tragen"
    assert all(satz.endswith(".") for satz in saetze)
    assert [int(satz.split(".", 1)[0]) for satz in saetze] == list(range(1, len(saetze) + 1))


def test_unbelegtes_haekchen_wird_als_solches_gemeldet():
    text = _urfassung(["- [x] **CP-B.1:** Fertig, aber ohne Pruefung."])
    gruppen, _ = befunde_sammeln(beurteilen(checkpoints_lesen(text),
                                            StummerBeweisstand()), {})
    assert [u.checkpoint.nummer for u in gruppen[UNBELEGT]] == ["CP-B.1"]


def test_echte_roadmap_wird_vollstaendig_gelesen():
    # Ein Parser, der still nichts liest, waere die gefaehrlichste Form des
    # Abhakens. Deshalb prueft der Test die echte Roadmap auf Substanz.
    text = (WURZEL / "ROADMAP.md").read_text(encoding="utf-8")
    eintraege = checkpoints_lesen(text)
    assert len(eintraege) >= 90
    assert sum(1 for e in eintraege if e.ist_fertig) >= 30
    assert sum(1 for e in eintraege if e.ist_offen) >= 20
    mit_beweis = sum(1 for e in eintraege if e.hat_beweis())
    assert mit_beweis >= 10
