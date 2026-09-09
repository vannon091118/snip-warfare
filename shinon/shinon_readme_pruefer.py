# -*- coding: utf-8 -*-
"""Shinon Readme Prüfer. Eigene Zuständigkeit: Die Readme bleibt lebendig und aktuell."""

import re
from dataclasses import dataclass
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent
README_PFAD = PROJEKT_STAMM / "README.md"


@dataclass(frozen=True)
class ShinonReadmeBefund:
    code: str
    datei: str
    zeile: int
    text: str


class ShinonReadmePruefer:
    """Prüft ob die Readme aus Sicht von Shinon als lebendiger Pitch existiert und aktuell gehalten wird."""

    PFLICHT_STICHWORTE = (
        "shinon",
        "preflight",
        "weltuhr",
        "tick",
        "registry",
    )

    def pruefen(self, pfad: Path | None = None) -> list[ShinonReadmeBefund]:
        ziel = pfad or README_PFAD
        rel = str(ziel.relative_to(PROJEKT_STAMM)) if ziel.is_relative_to(PROJEKT_STAMM) else str(ziel)
        if not ziel.is_file():
            return [ShinonReadmeBefund(
                code="E035",
                datei=rel,
                zeile=1,
                text="Readme Pflicht: Die Datei README.md fehlt, Shinon verlangt einen lebendigen gamerorientierten Pitch der die Vision in universe erklaert und die vierte Wand bricht.",
            )]
        try:
            inhalt = ziel.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            return [ShinonReadmeBefund(
                code="E035",
                datei=rel,
                zeile=1,
                text="Readme Pflicht: Die Datei README.md ist nicht als UTF-8 lesbar.",
            )]
        zeilen = inhalt.splitlines()
        if not zeilen or all(z.strip() == "" for z in zeilen):
            return [ShinonReadmeBefund(
                code="E035",
                datei=rel,
                zeile=1,
                text="Readme Pflicht: Die Datei README.md ist leer und enthaelt keinen Pitch, Shinon verlangt einen zynisch humorvollen Text der fuer Spieler geschrieben ist.",
            )]
        befunde: list[ShinonReadmeBefund] = []
        niedrig = inhalt.lower()
        # Muss aus Sicht von Shinon sprechen und die vierte Wand brechen.
        if "shinon" not in niedrig:
            befunde.append(ShinonReadmeBefund(
                code="E035",
                datei=rel,
                zeile=1,
                text="Readme Pflicht: Der Name Shinon kommt in der Readme nicht vor, der Pitch muss aus Sicht von Shinon sprechen und die vierte Wand aktiv brechen.",
            ))
        # Mindestens ein Hauch In Universe Ton.
        vierte_wand_signale = ("du ", "ihr ", "wir ", "schau", "hier", "spiel")
        if not any(signal in niedrig for signal in vierte_wand_signale):
            befunde.append(ShinonReadmeBefund(
                code="E035",
                datei=rel,
                zeile=1,
                text="Readme Pflicht: Die Readme bricht die vierte Wand nicht, Shinon verlangt direkte Ansprache der Spieler und einen in universe Ton.",
            ))
        # Projektzustand und Vision muessen erkennbar sein.
        if "vision" not in niedrig and "zustand" not in niedrig and "stand" not in niedrig:
            befunde.append(ShinonReadmeBefund(
                code="E035",
                datei=rel,
                zeile=1,
                text="Readme Pflicht: Die Readme erklaert weder Zustand noch Vision, Shinon verlangt einen lebendigen gamerorientierten Ueberblick der aktuell gehalten wird.",
            ))
        # Technische Lebendigkeit: Preflight, Weltuhr oder Registry muss vorkommen.
        if not any(stichwort in niedrig for stichwort in self.PFLICHT_STICHWORTE):
            befunde.append(ShinonReadmeBefund(
                code="E035",
                datei=rel,
                zeile=1,
                text="Readme Pflicht: Die Readme erwaehnt weder Preflight noch Weltuhr noch Registry, damit wirkt sie nicht mehr aktuell zum Projekt.",
            ))
        # Mindestlaenge.
        woerter = re.findall(r"\w+", inhalt)
        if len(woerter) < 180:
            befunde.append(ShinonReadmeBefund(
                code="E035",
                datei=rel,
                zeile=1,
                text=f"Readme Pflicht: Die Readme ist mit nur {len(woerter)} Woertern zu kurz, Shinon verlangt mindestens 180 Woerter lebendigen Pitch.",
            ))
        return befunde
