# -*- coding: utf-8 -*-
"""Pruefkategorie version (E043): Dünner Aufrufer über echte Teil-Domänen."""

from .kern import PROJEKT_STAMM, fehler, lies_dateien
from .statuszahlen_werkzeuge import STATUSDOKUMENTE, statuszahlen_lesen, statuszahlen_verletzungen
from .version_werkzeuge import (
    VERSIONSDATEI,
    VERSIONIERTE_DOKUMENTE,
    dokument_version,
    dokumente_finden,
    version_erhoehen,
    version_lesen,
    version_zeile,
    _zeile_der_versionszeile,
)
from .statuszahlen_werkzeuge import (
    STATUSMUSTER,
    PAARFORM_MUSTER,
    BADGE_MUSTER,
    paarformen_aufloesen,
    badge_nachziehen,
    badge_verletzungen,
    statuszahl_ersetzen,
    statuszahlen_nachziehen,
    statuszahlen_verletzungen,
)


def pruefe_version(dateien=None) -> None:
    """E043: VERSION ist Quelle, jedes Dokument trägt sie, Statuszahlen stimmen."""
    dateien = lies_dateien() if dateien is None else dateien
    global_version = version_lesen()
    if global_version is None:
        fehler("E043", VERSIONSDATEI, 1, "Globale Version fehlt; erwartet V0.01")
        return
    dokumente = dokumente_finden()
    for pflicht in VERSIONIERTE_DOKUMENTE:
        if pflicht not in dokumente:
            fehler("E043", pflicht, 1, "Vertragsdokument fehlt; erwartet Version %s" % global_version)
    for relativ in dokumente:
        pfad = PROJEKT_STAMM / relativ
        text = pfad.read_text(encoding="utf-8")
        eigene = dokument_version(text)
        if eigene is None:
            fehler("E043", relativ, 1, "Versionszeile fehlt; erwartet '%s'" % version_zeile(global_version))
            continue
        if eigene != global_version:
            zeile = _zeile_der_versionszeile(text)
            fehler("E043", relativ, zeile, "Version %s weicht von %s ab; version_bump zieht nach" % (eigene, global_version))
    zahlen = statuszahlen_lesen(dateien)
    for relativ in STATUSDOKUMENTE:
        pfad = PROJEKT_STAMM / relativ
        if not pfad.is_file():
            continue
        text = pfad.read_text(encoding="utf-8")
        for zeile, schluessel, ist, soll in statuszahlen_verletzungen(text, zahlen):
            fehler("E043", relativ, zeile, "Statuszahl %d fuer %s weicht von %d ab; --nachziehen" % (ist, schluessel, soll))
