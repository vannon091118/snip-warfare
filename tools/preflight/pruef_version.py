# -*- coding: utf-8 -*-
"""Pruefkategorie version (E043): Die globale Projektversion als einzige Quelle.

Die Datei VERSION im Projektstamm traegt genau eine Zeile im Format V0.01.
Jedes Dokument der Liste VERSIONIERTE_DOKUMENTE muss dieselbe Version in einer
Zeile "Version: V0.01" nennen. Weicht ein Dokument ab oder fehlt die Zeile,
meldet der Preflight E043 mit Datei und echter Zeile. Der mechanische Bump
laeuft ueber tools/version_bump.py und zieht jedes Dokument nach; der Agent
kann die Version also nicht vergessen, das Gate erzwingt sie.
"""

import re

from .kern import PROJEKT_STAMM, fehler

VERSIONSDATEI = "VERSION"

# Jedes Dokument traegt dieselbe Version in genau einer Zeile.
VERSIONIERTE_DOKUMENTE = (
    "README.md",
    "ROADMAP.md",
    "INDEX.md",
    "Architektur.md",
    "AGENTS.md",
)

VERSIONSMUSTER = re.compile(r"^[ \t]*Version[ \t]*:[ \t]*V(\d+)\.(\d{2})[ \t]*$", re.M)
KOPFMUSTER = re.compile(r"V(\d+)\.(\d{2})")


def version_lesen(stamm=None):
    """Liest die globale Version als String V0.01; None bei fehlender Datei."""
    stamm = stamm if stamm is not None else PROJEKT_STAMM
    pfad = stamm / VERSIONSDATEI
    if not pfad.is_file():
        return None
    for zeile in pfad.read_text(encoding="utf-8").splitlines():
        treffer = KOPFMUSTER.fullmatch(zeile.strip())
        if treffer is not None:
            return "V%s.%s" % (treffer.group(1), treffer.group(2))
    return None


def version_erhoehen(version):
    """Erhoeht die Version um genau 0.01 im Format V0.01 bis Vx.99."""
    treffer = KOPFMUSTER.fullmatch(version.strip())
    if treffer is None:
        return None
    haupt = int(treffer.group(1))
    neben = int(treffer.group(2)) + 1
    if neben > 99:
        haupt += 1
        neben = 0
    return "V%d.%02d" % (haupt, neben)


def dokument_version(text):
    """Liefert die Version aus der Versionszeile eines Dokuments oder None."""
    treffer = VERSIONSMUSTER.search(text)
    if treffer is None:
        return None
    return "V%s.%s" % (treffer.group(1), treffer.group(2))


def version_zeile(version):
    """Die verbindliche Zeile fuer Dokumente."""
    return "Version: %s" % version


def pruefe_version(dateien=None) -> None:
    """E043: VERSION ist die Quelle, jedes Dokument traegt dieselbe Version."""
    _ = dateien
    global_version = version_lesen()
    if global_version is None:
        fehler("E043", VERSIONSDATEI, 1,
               "Globale Version fehlt oder ist unlesbar; erwartet wird eine Zeile im Format V0.01")
        return
    for relativ in VERSIONIERTE_DOKUMENTE:
        pfad = PROJEKT_STAMM / relativ
        if not pfad.is_file():
            fehler("E043", relativ, 1,
                   "Dokument fehlt; die globalen Dokumente muessen die Version %s nennen" % global_version)
            continue
        text = pfad.read_text(encoding="utf-8")
        eigene = dokument_version(text)
        if eigene is None:
            fehler("E043", relativ, 1,
                   "Versionszeile fehlt; erwartet wird die Zeile '%s'" % version_zeile(global_version))
            continue
        if eigene != global_version:
            zeile = _zeile_der_versionszeile(text)
            fehler("E043", relativ, zeile,
                   "Version %s weicht von der globalen %s ab; python tools/version_bump.py zieht das Dokument nach" %
                   (eigene, global_version))


def _zeile_der_versionszeile(text):
    """Echte Zeilennummer der ersten Versionszeile."""
    for nummer, zeile in enumerate(text.splitlines(), start=1):
        if VERSIONSMUSTER.match(zeile) is not None:
            return nummer
    return 1
