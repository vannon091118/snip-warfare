# -*- coding: utf-8 -*-
"""Pruefkategorie version (E043): Die globale Projektversion als einzige Quelle.

Die Datei VERSION im Projektstamm traegt genau eine Zeile im Format V0.01.
Jedes Markdown-Dokument des Projekts traegt dieselbe Version in einer Zeile
"Version: V0.01". Die Dokumentenliste wird nicht gepflegt, sondern bei jedem
Lauf aus dem Baum gelesen: Jedes neue Dokument ist automatisch im Vertrag.
Weicht eines ab oder fehlt die Zeile, meldet der Preflight E043 mit Datei und
echter Zeile. Der mechanische Bump laeuft ueber tools/version_bump.py und zieht
jedes Dokument nach; der Agent kann die Version also nicht vergessen.

Zur Version gehoert derselbe Anspruch an die Statuszahlen: Wenn ein Dokument
eine Anzahl Klassen, GDScript-Dateien oder Szenen nennt, muss diese Zahl den
echten Stand zeigen. Auch das prueft E043 mit Datei und Zeile, damit die
Dokumentation nicht still eine alte Wahrheit erzaehlt.
"""

import re

from .kern import (PROJEKT_STAMM, fehler, klassen_name_lesen, lies_dateien)

VERSIONSDATEI = "VERSION"

# Pfade, die keine Projekt-Dokumente sind: Werkzeug-Caches und Fremd-Ordner.
IGNORIERTE_PRAEFIXE = (
    ".git/",
    ".godot/",
    ".agents/",
    ".kilo/",
    ".pytest_cache/",
    "__pycache__/",
    "node_modules/",
    "addons/",
)

# Vertragsdokumente, die immer dazugehoeren und nie fehlen duerfen.
VERSIONIERTE_DOKUMENTE = (
    "README.md",
    "ROADMAP.md",
    "INDEX.md",
    "Architektur.md",
    "AGENTS.md",
)

# Dokumente, die den Projektumfang in Zahlen nennen und deshalb mitwandern.
STATUSDOKUMENTE = ("README.md", "ROADMAP.md", "Architektur.md", "INDEX.md")


def dokumente_finden(stamm=None):
    """Alle Markdown-Dokumente des Projekts, sortiert und ohne Fremd-Ordner.

    Diese Liste ist die einzige Quelle fuer Pruefer und Bump-Werkzeug: Ein neu
    angelegtes Dokument ist damit ohne Zutun im Vertrag.
    """
    stamm = stamm if stamm is not None else PROJEKT_STAMM
    gefunden = []
    for pfad in sorted(stamm.rglob("*.md")):
        try:
            relativ = str(pfad.relative_to(stamm)).replace("\\", "/")
        except ValueError:
            continue
        if relativ.startswith(IGNORIERTE_PRAEFIXE):
            continue
        gefunden.append(relativ)
    return gefunden

VERSIONSMUSTER = re.compile(r"^[ \t]*Version[ \t]*:[ \t]*V(\d+)\.(\d{2})[ \t]*$", re.M)
KOPFMUSTER = re.compile(r"V(\d+)\.(\d{2})")

# Muster der Statuszahlen. Jedes Muster legt die Zahl in die Gruppe "zahl" und
# laesst das Substantiv in "rest" stehen. Ein Ersatz tauscht damit nur die Zahl:
# Wer das Substantiv mit in den Treffer nimmt, frisst beim Nachzug das Wort und
# hinterlaesst Saetze wie "mit 227, 11, funktionierender Wegplanung".
STATUSMUSTER = (
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> Klassen\b)"), "klassen"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> GDScript-Dateien\b)"), "dateien"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> Szenen\b)"), "szenen"),
    # Schreibweise der Roadmap: "11 aktive `.tscn`-Szenen".
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest>(?=\s+aktive\b))"), "szenen"),
)


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


def statuszahlen_lesen(dateien=None):
    """Liest den echten Projektumfang so, wie der Preflight ihn zaehlt."""
    if dateien is None:
        dateien = lies_dateien()
    klassen = {klassen_name_lesen(code) for _, code in dateien}
    klassen.discard(None)
    szenen = [pfad for pfad in PROJEKT_STAMM.rglob("*.tscn")
              if not _pfad_ignoriert(pfad)]
    return {"klassen": len(klassen), "dateien": len(dateien), "szenen": len(szenen)}


def _pfad_ignoriert(pfad):
    """Prueft einen Pfad gegen die ignorierten Praefixe."""
    relativ = str(pfad.relative_to(PROJEKT_STAMM)).replace("\\", "/")
    return relativ.startswith(IGNORIERTE_PRAEFIXE)


def statuszahl_ersetzen(text, muster, zahl):
    """Tauscht nur die Zahl eines Treffers und laesst das Substantiv stehen."""
    return muster.sub(lambda treffer: str(zahl) + treffer.group("rest"), text)


def statuszahlen_nachziehen(text, zahlen):
    """Zieht alle erkannten Statuszahlen eines Dokuments auf den echten Stand."""
    for muster, schluessel in STATUSMUSTER:
        text = statuszahl_ersetzen(text, muster, zahlen[schluessel])
    return text


def statuszahlen_verletzungen(text, zahlen):
    """Meldet jede abweichende Statuszahl als (zeile, schluessel, ist, soll)."""
    verletzungen = []
    for nummer, zeile in enumerate(text.splitlines(), start=1):
        for muster, schluessel in STATUSMUSTER:
            for treffer in muster.finditer(zeile):
                ist = int(treffer.group("zahl"))
                soll = zahlen[schluessel]
                if ist != soll:
                    verletzungen.append((nummer, schluessel, ist, soll))
    return verletzungen


def pruefe_version(dateien=None) -> None:
    """E043: VERSION ist die Quelle, jedes Projekt-Dokument traegt sie."""
    dateien = lies_dateien() if dateien is None else dateien
    global_version = version_lesen()
    if global_version is None:
        fehler("E043", VERSIONSDATEI, 1,
               "Globale Version fehlt oder ist unlesbar; erwartet wird eine Zeile im Format V0.01")
        return
    dokumente = dokumente_finden()
    for pflicht in VERSIONIERTE_DOKUMENTE:
        if pflicht not in dokumente:
            fehler("E043", pflicht, 1,
                   "Vertragsdokument fehlt; erwartet wird die Datei mit der Version %s" % global_version)
    for relativ in dokumente:
        pfad = PROJEKT_STAMM / relativ
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
    # Statuszahlen: Die Dokumentation nennt den echten Umfang des Projekts.
    zahlen = statuszahlen_lesen(dateien)
    for relativ in STATUSDOKUMENTE:
        pfad = PROJEKT_STAMM / relativ
        if not pfad.is_file():
            continue
        text = pfad.read_text(encoding="utf-8")
        for zeile, schluessel, ist, soll in statuszahlen_verletzungen(text, zahlen):
            fehler("E043", relativ, zeile,
                   "Statuszahl %d fuer %s weicht vom echten Stand %d ab; python tools/version_bump.py --nachziehen zieht sie nach" %
                   (ist, schluessel, soll))


def _zeile_der_versionszeile(text):
    """Echte Zeilennummer der ersten Versionszeile."""
    for nummer, zeile in enumerate(text.splitlines(), start=1):
        if VERSIONSMUSTER.match(zeile) is not None:
            return nummer
    return 1
