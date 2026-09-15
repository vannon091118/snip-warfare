# -*- coding: utf-8 -*-
"""Version Werkzeuge. Eigene Zuständigkeit: Version lesen, erhöhen, finden."""

import re

from .kern import PROJEKT_STAMM

VERSIONSDATEI = "VERSION"

IGNORIERTE_PRAEFIXE = (
    ".git/",
    ".godot/",
    ".agents/",
    ".kilo/",
    ".pytest_cache/",
    "__pycache__/",
    "node_modules/",
    "addons/",
    ".freebuff/",
    ".venv/",
    ".local_dev/",
)

VERSIONIERTE_DOKUMENTE = (
    "README.md",
    "ROADMAP.md",
    "INDEX.md",
    "Architektur.md",
    "AGENTS.md",
)

VERSIONSMUSTER = re.compile(r"^[ \t]*Version[ \t]*:[ \t]*V(\d+)\.(\d{2})[ \t]*$", re.M)
KOPFMUSTER = re.compile(r"V(\d+)\.(\d{2})")


def dokumente_finden(stamm=None):
    """Alle Markdown-Dokumente sortiert ohne Fremd-Ordner."""
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


def version_lesen(stamm=None):
    """Liest globale Version als String V0.01 oder None."""
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
    """Erhoeht Version um 0.01 im Format V0.01."""
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
    """Version aus Dokuments Versionszeile oder None."""
    treffer = VERSIONSMUSTER.search(text)
    if treffer is None:
        return None
    return "V%s.%s" % (treffer.group(1), treffer.group(2))


def version_zeile(version):
    """Verbindliche Zeile fuer Dokumente."""
    return "Version: %s" % version


def _zeile_der_versionszeile(text):
    """Echte Zeilennummer der ersten Versionszeile."""
    for nummer, zeile in enumerate(text.splitlines(), start=1):
        if VERSIONSMUSTER.match(zeile) is not None:
            return nummer
    return 1
