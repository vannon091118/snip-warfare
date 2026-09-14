# -*- coding: utf-8 -*-
"""Prüfkategorie bau_kette (E045): Der Bau-Datenvertrag braucht einen Leser.

Regel: Jede im Datenmodell deklarierte Bau-Voraussetzung muss im Code
gelesen werden, jede Referenz muss auf ein existierendes Objekt zeigen und
jedes Asset muss liegen. Ein Vertrag ohne Leser ist ein toter Vertrag — der
Spieler kann Möbel setzen und trotzdem nie bauen, weil die Prüfung nie läuft.

Drei eigene Teilzuständigkeiten, jede mit klarer Verantwortung:
  _tags_mit_leser     benötigt_tags eines Gebäudes braucht Objekt-Tags
  _vertrag_hat_leser  der Vertrag braucht einen Reader, den das Gate befragt
  _voraussetzungen    Bau-Voraussetzung verweist auf existierendes Gebäude
Die Datenseite wohnt in bau_daten_werkzeuge.py.
"""

from .bau_daten_werkzeuge import (
    GEBAEUDE_DATEN,
    KATALOG_DATEN,
    katalog_tags,
    lade_json,
    lies,
    pruefe_assets,
)
from .kern import fehler

READER_DATEI = "world/logic/kategorie_objekt/gebaeude_moebel_bedarf.gd"
READER_KLASSE = "Gebaeude_MoebelBedarf"
# Das Bau-Gate muss den Reader benutzen: Nur die Einbindung macht den
# Vertrag lebendig, die blosse Existenz der Datei reicht nicht.
GATE_DATEIEN = (
    "world/logic/kategorie_objekt/gebaeude_bauplatz_pruefer.gd",
    "world/logic/kategorie_objekt/gebaeude_bau_auftrag.gd",
)
GATE_VERBINDUNG = ("moebelbedarf_erfuellt",)


def _tags_mit_leser(gebaeude, tags_nach_id: dict) -> None:
    """Jeder benötigt_tag braucht ein Objekt, das ihn trägt."""
    for geb in gebaeude or []:
        gid = str(geb.get("id", ""))
        for tag in geb.get("benötigt_tags", []) or []:
            if str(tag) not in tags_nach_id:
                fehler("E045", GEBAEUDE_DATEN, 1,
                       "Gebäude %s verlangt Tag '%s', den kein Katalog-Objekt trägt; "
                       "die Bau-Voraussetzung ist unerfüllbar" % (gid, tag))


def _code_liest_vertrag() -> bool:
    """Der Vertrag gilt nur als gelesen, wenn der eigene Reader existiert und
    das Bau-Gate ihn wirklich befragt. Ein Suchwort in irgendeiner Datei wäre
    kein Beweis für einen lebendigen Vertrag."""
    if not lies(READER_DATEI):
        return False
    for gate in GATE_DATEIEN:
        text = lies(gate)
        if not text:
            continue
        if READER_KLASSE in text and any(verb in text for verb in GATE_VERBINDUNG):
            return True
    return False


def _vertrag_hat_leser(gebaeude) -> None:
    """Ein deklarierter Vertrag ohne Code-Leser ist ein toter Vertrag."""
    if not gebaeude:
        return
    if not any((g.get("benötigt_tags") or []) for g in gebaeude):
        return
    if not _code_liest_vertrag():
        fehler("E045", GEBAEUDE_DATEN, 1,
               "benötigt_tags ist deklariert, aber %s wird nicht vom Bau-Gate "
               "befragt; Möbel lassen sich setzen, der Bau wird trotzdem nie "
               "freigegeben" % READER_KLASSE)


def _voraussetzungen(gebaeude) -> None:
    """Bau-Voraussetzung muss auf ein existierendes Gebäude zeigen."""
    ids = {str(g.get("id", "")) for g in gebaeude or []}
    for geb in gebaeude or []:
        for vor in geb.get("voraussetzungen", []) or []:
            if str(vor) not in ids:
                fehler("E045", GEBAEUDE_DATEN, 1,
                       "Gebäude %s setzt '%s' voraus, das es im Katalog nicht gibt" %
                       (str(geb.get("id", "")), vor))


def pruefe_bau_kette(dateien=None) -> None:
    """E045: Bau-Vertrag, Voraussetzungen und Assets in der logischen Reihe."""
    _ = dateien
    gebaeude = lade_json(GEBAEUDE_DATEN)
    katalog = lade_json(KATALOG_DATEN)
    if gebaeude is None or katalog is None:
        fehler("E045", GEBAEUDE_DATEN, 1, "Bau-Daten nicht lesbar")
        return
    _tags_mit_leser(gebaeude, katalog_tags(katalog))
    _vertrag_hat_leser(gebaeude)
    _voraussetzungen(gebaeude)
    pruefe_assets(katalog)
