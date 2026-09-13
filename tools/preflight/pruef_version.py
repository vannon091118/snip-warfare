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
    # Anzahl der Pytest-Faelle: "97 bestandenen Pytest-Pruefungen" und
    # "97/97"-Paarform wird vorab in die Einzelform gebracht.
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> bestandenen Pytest-Prüfungen\b)"), "tests"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> Pytest-Fälle\b)"), "tests"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> Unittests\b)"), "tests"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> bestandenen Pytest-Pruefungen\b)"), "tests"),
    # Anzahl der Pruefkategorien: "alle 19 Prüfkategorien".
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> Prüfkategorien\b)"), "kategorien"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> Pruefkategorien\b)"), "kategorien"),
)

# Paarform wie "85/85" oder "85 / 85": Der Nachzug bringt sie zuerst in die
# Einzelform, damit die obigen Muster den zweiten Anteil tauschen koennen.
PAARFORM_MUSTER = re.compile(r"\b(\d+)\s*/\s*(\d+)\s*(Pytest-Fälle)\b")

# Badge-Form im README-Kopf: Die Zahl steckt URL-kodiert in einem Bild-Link
# (pytest-85%2F85%20Passed) und entzieht sich den Fliesstext-Mustern.
BADGE_MUSTER = re.compile(r"(?P<vorn>pytest-)(?P<zahl>\d+)(?P<mitte>%2F)(?P<zwei>\d+)(?P<hinten>%20Passed)")


def paarformen_aufloesen(text):
    """Bringt Paarformen wie 85/85 Pytest-Fälle in die Einzelform 97 Pytest-Fälle."""
    return PAARFORM_MUSTER.sub(lambda t: "%s %s" % (t.group(2), t.group(3)), text)


def badge_nachziehen(text, zahlen):
    """Zieht beide Anteile des Test-Badges auf die echte Testanzahl."""
    zahl = str(zahlen["tests"])
    return BADGE_MUSTER.sub(
        lambda t: "%s%s%s%s%s" % (t.group("vorn"), zahl, t.group("mitte"), zahl, t.group("hinten")),
        text)


def badge_verletzungen(text, zahlen):
    """Meldet Badge-Abweichungen als (zeile, schluessel, ist, soll)."""
    verletzungen = []
    for treffer in BADGE_MUSTER.finditer(text):
        zeile = text[:treffer.start()].count("\n") + 1
        ist = int(treffer.group("zahl"))
        soll = zahlen["tests"]
        if ist != soll or int(treffer.group("zwei")) != soll:
            verletzungen.append((zeile, "tests", ist, soll))
    return verletzungen


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
    return {"klassen": len(klassen), "dateien": len(dateien), "szenen": len(szenen),
            "tests": _testanzahl_lesen(), "kategorien": _kategorieanzahl_lesen()}


def _pfad_ignoriert(pfad):
    """Prueft einen Pfad gegen die ignorierten Praefixe."""
    relativ = str(pfad.relative_to(PROJEKT_STAMM)).replace("\\", "/")
    return relativ.startswith(IGNORIERTE_PRAEFIXE)


def _testanzahl_lesen():
    """Zaehlt alle Testfunktionen in test_*.py des Projektstamms.

    Das ist dieselbe Wahrheit, die pytest sammelt: def test_* auf oberster
    Ebene je Wurzel-Testdatei. Paarformen wie "97/97" ergeben denselben
    Betrag, weil beide Anteile dieselbe Zahl nennen.
    """
    import re
    anzahl = 0
    for pfad in sorted(PROJEKT_STAMM.glob("test_*.py")):
        try:
            text = pfad.read_text(encoding="utf-8")
        except OSError:
            continue
        anzahl += len(re.findall(r"^\s*def test_", text, re.M))
    return anzahl


def _kategorieanzahl_lesen():
    """Zaehlt die Pruefkategorien mechanisch aus tools/preflight.py.

    Per AST, ohne den Preflight zu importieren: Der Import wuerde den
    globalen Klassenstand des Preflights selbst veraendern und Zirkel
    erzeugen. Nur die Zuweisung PRUEFKATEGORIEN zaehlt.
    """
    import ast
    preflight_pfad = PROJEKT_STAMM / "tools" / "preflight.py"
    if not preflight_pfad.is_file():
        return 0
    try:
        baum = ast.parse(preflight_pfad.read_text(encoding="utf-8"))
    except SyntaxError:
        return 0
    for knoten in ast.walk(baum):
        if isinstance(knoten, ast.Assign):
            for ziel in knoten.targets:
                if isinstance(ziel, ast.Name) and ziel.id == "PRUEFKATEGORIEN":
                    if isinstance(knoten.value, ast.Dict):
                        return len(knoten.value.keys)
    return 0

def statuszahl_ersetzen(text, muster, zahl):
    """Tauscht nur die Zahl eines Treffers und laesst das Substantiv stehen."""
    return muster.sub(lambda treffer: str(zahl) + treffer.group("rest"), text)


def statuszahlen_nachziehen(text, zahlen):
    """Zieht alle erkannten Statuszahlen eines Dokuments auf den echten Stand."""
    text = paarformen_aufloesen(text)
    text = badge_nachziehen(text, zahlen)
    for muster, schluessel in STATUSMUSTER:
        text = statuszahl_ersetzen(text, muster, zahlen[schluessel])
    return text


def statuszahlen_verletzungen(text, zahlen):
    """Meldet jede abweichende Statuszahl als (zeile, schluessel, ist, soll)."""
    verletzungen = []
    text = paarformen_aufloesen(text)
    verletzungen.extend(badge_verletzungen(text, zahlen))
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
