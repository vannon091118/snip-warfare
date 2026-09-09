# -*- coding: utf-8 -*-
"""Shinon Gate. Eigene Zuständigkeit: Orchestrierung der Teilprüfer und Datei Gate."""

from dataclasses import dataclass
from pathlib import Path

import importlib.util as _ilu
import sys as _sys

PROJEKT_STAMM = Path(__file__).resolve().parent.parent
COMMIT_MSG_PFAD = PROJEKT_STAMM / "shinon" / "commit_msg.txt"


def _lade_pruefer(dateiname: str, klassenname: str):
    pfad = PROJEKT_STAMM / "shinon" / dateiname
    spez = _ilu.spec_from_file_location(f"_shinon_{klassenname.lower()}", str(pfad))
    modul = _ilu.module_from_spec(spez)
    _sys.modules[spez.name] = modul
    assert spez.loader is not None
    spez.loader.exec_module(modul)
    return getattr(modul, klassenname)


@dataclass(frozen=True)
class ShinonBefund:
    code: str
    datei: str
    zeile: int
    text: str


class ShinonGate:
    """Einzige Stelle die die vier Teilprüfer zusammenführt. Jeder Teil hat seine eigene Klasse."""

    def __init__(self) -> None:
        self._banner = _lade_pruefer("shinon_banner_pruefer.py", "ShinonBannerPruefer")()
        self._bullet = _lade_pruefer("shinon_bullet_pruefer.py", "ShinonBulletPruefer")()
        self._nummerierung = _lade_pruefer("shinon_nummerierung_pruefer.py", "ShinonNummerierungPruefer")()
        self._bildsprache = _lade_pruefer("shinon_bildsprache_pruefer.py", "ShinonBildsprachePruefer")()

    def pruefen(self, pfad: Path | None = None) -> list[ShinonBefund]:
        ziel = pfad or COMMIT_MSG_PFAD
        rel = str(ziel.relative_to(PROJEKT_STAMM)) if ziel.is_relative_to(PROJEKT_STAMM) else str(ziel)
        if not ziel.is_file():
            return [ShinonBefund(
                code="E034",
                datei=rel,
                zeile=1,
                text="Gate Pflicht: Die Datei shinon/commit_msg.txt fehlt, vor jedem Commit muss Shinon sie in ganzen nummerierten bildlichen Saetzen fuellen.",
            )]
        try:
            inhalt = ziel.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            return [ShinonBefund(
                code="E034",
                datei=rel,
                zeile=1,
                text="Gate Pflicht: Die Datei shinon/commit_msg.txt ist nicht als UTF-8 lesbar.",
            )]
        zeilen = inhalt.splitlines()
        # Leere Datei ist bereits über Nummerierung abgedeckt, aber hier explizit als E034 wenn wirklich leer.
        if not zeilen or all(z.strip() == "" for z in zeilen):
            return [ShinonBefund(
                code="E034",
                datei=rel,
                zeile=1,
                text="Gate Pflicht: Die Datei shinon/commit_msg.txt ist leer und enthaelt keinen nummerierten bildlichen Satz.",
            )]
        befunde: list[ShinonBefund] = []
        for b in self._banner.pruefen(zeilen):
            befunde.append(ShinonBefund(code=b.code, datei=rel, zeile=b.zeile, text=b.text))
        for b in self._bullet.pruefen(zeilen):
            befunde.append(ShinonBefund(code=b.code, datei=rel, zeile=b.zeile, text=b.text))
        for b in self._nummerierung.pruefen(zeilen):
            befunde.append(ShinonBefund(code=b.code, datei=rel, zeile=b.zeile, text=b.text))
        for b in self._bildsprache.pruefen(zeilen):
            befunde.append(ShinonBefund(code=b.code, datei=rel, zeile=b.zeile, text=b.text))
        return befunde

    def pruefe_text(self, text: str) -> list[ShinonBefund]:
        """Prüfung eines reinen Textes ohne Datei, für Preflight Selbsttest."""
        zeilen = text.splitlines()
        befunde: list[ShinonBefund] = []
        for b in self._banner.pruefen(zeilen):
            befunde.append(ShinonBefund(code=b.code, datei="shinon/commit_msg.txt", zeile=b.zeile, text=b.text))
        for b in self._bullet.pruefen(zeilen):
            befunde.append(ShinonBefund(code=b.code, datei="shinon/commit_msg.txt", zeile=b.zeile, text=b.text))
        for b in self._nummerierung.pruefen(zeilen):
            befunde.append(ShinonBefund(code=b.code, datei="shinon/commit_msg.txt", zeile=b.zeile, text=b.text))
        for b in self._bildsprache.pruefen(zeilen):
            befunde.append(ShinonBefund(code=b.code, datei="shinon/commit_msg.txt", zeile=b.zeile, text=b.text))
        return befunde
