# -*- coding: utf-8 -*-
"""Prüfkategorie engine_bruecken (E047-E051): Der View-Zwang der Engines.

Regel: Das Brett gehört dem Koordinator. Keine Engine erzeugt Kern_Blackboard,
keine Engine hält es als Feld. Cross-Engine-Brücken sind Callables über
Domänen-Grenzen und verboten; Event-Queues über den Konsolidator ersetzen sie.

Teilzuständigkeiten:
  pruef_engine_bruecken      E047 Brett-Erzeugung, E048 Brett-Feld, E049 Brücke
  engine_bruecken_werkzeuge  E050 Register-Vertrag, E051 Queue-Schema
"""

from pathlib import Path

from .engine_bruecken_werkzeuge import register_vertrag
from .kern import fehler

KOORDINATOR_DATEI = "core/logic/kategorie_blackboard/kern_engine_koordinator.gd"
ENGINE_ORDNER = ("game/", "world/", "core/", "economy/", "population/", "military/")
DOMAENEN_PRAEFIXE = ("Einheit_", "Soz_", "Lager_", "Pop_", "Welt_", "Tier_", "Kern_")


def pruefe_engine_bruecken(dateien) -> None:
    gd_dateien = [d for d in dateien if str(d).endswith(".gd")]
    _brett_ohne_besitzer(gd_dateien)
    _brett_als_feld(gd_dateien)
    _callable_bruecke(gd_dateien)
    register_vertrag(gd_dateien)


def _rel(pfad) -> str:
    return str(pfad).replace("\\", "/")


def _im_bereich(rel: str) -> bool:
    return rel.startswith(ENGINE_ORDNER)


def _brett_ohne_besitzer(dateien) -> None:
    """E047: Nur der Koordinator erzeugt Kern_Blackboard."""
    import re
    for pfad in dateien:
        rel = _rel(pfad)
        if not _im_bereich(rel) or rel == KOORDINATOR_DATEI:
            continue
        text = _lies(pfad)
        if text is None:
            continue
        if re.search(r"\bKern_Blackboard\.new\(\)", text):
            fehler("E047", rel, 1, "Nur der Koordinator erzeugt das Brett; Engine-Code fordert eine View beim Koordinator an")


def _brett_als_feld(dateien) -> None:
    """E048: Keine Engine hält das Brett als Feld."""
    import re
    for pfad in dateien:
        rel = _rel(pfad)
        if not _im_bereich(rel) or rel.startswith("core/logic/kategorie_blackboard/"):
            continue
        text = _lies(pfad)
        if text is None:
            continue
        if re.search(r"var\s+\w+\s*:\s*Kern_Blackboard\b", text):
            fehler("E048", rel, 1, "Das Brett ist kein Feld; der Koordinator besitzt es, Engines erhalten Views")


def _callable_bruecke(dateien) -> None:
    """E049: Keine Callable-Felder, die über Domänen-Präfixe hinweg zeigen."""
    import re
    for pfad in dateien:
        rel = _rel(pfad)
        if not _im_bereich(rel) or rel.startswith("core/logic/kategorie_blackboard/"):
            continue
        text = _lies(pfad)
        if text is None:
            continue
        quelle = _quelle_präfix(rel)
        for treffer in re.finditer(r"var\s+(\w+)\s*:\s*Callable", text):
            ziel = _ziel_domäne(treffer.group(1))
            if ziel and quelle and ziel != quelle:
                fehler("E049", rel, text[: treffer.start()].count("\n") + 1,
                       "Callable-Brücke über Domänen-Grenzen: %s verbindet %s mit %s; Event-Queue über den Konsolidator ersetzt sie" % (treffer.group(1), quelle, ziel))


def _ziel_domäne(feldname: str) -> str | None:
    for praefix in DOMAENEN_PRAEFIXE:
        if praefix.lower().rstrip("_") in feldname.lower():
            return praefix
    return None


def _quelle_präfix(rel: str) -> str | None:
    name = rel.rsplit("/", 1)[-1]
    for praefix in DOMAENEN_PRAEFIXE:
        if name.startswith(praefix):
            return praefix
    return None


def _lies(pfad) -> str | None:
    try:
        return Path(pfad).read_text(encoding="utf-8")
    except OSError:
        return None
