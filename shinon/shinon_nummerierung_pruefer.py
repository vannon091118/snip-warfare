# -*- coding: utf-8 -*-
"""Shinon Nummerierung Prüfer. Eigene Zuständigkeit: fortlaufende nummerierte Sätze."""

import re
from dataclasses import dataclass

NUMMER_MUSTER = re.compile(r"^\s*(\d+)\.\s+.+\.\s*$")


@dataclass(frozen=True)
class ShinonNummerierungBefund:
    code: str
    zeile: int
    text: str


class ShinonNummerierungPruefer:
    """Jede inhaltstragende Zeile muss 1. Satz. 2. Satz. sein. Lücken melden E032."""

    def pruefen(self, zeilen: list[str]) -> list[ShinonNummerierungBefund]:
        befunde: list[ShinonNummerierungBefund] = []
        erwartet = 1
        hat_inhalt = False
        for index, zeile in enumerate(zeilen, start=1):
            if zeile.strip() == "":
                continue
            hat_inhalt = True
            treffer = NUMMER_MUSTER.match(zeile)
            if treffer is None:
                befunde.append(ShinonNummerierungBefund(
                    code="E032",
                    zeile=index,
                    text="Nummerierungspflicht: Jede inhaltstragende Zeile muss mit fortlaufender Nummer Punkt Leerzeichen beginnen und mit einem Punkt enden.",
                ))
                continue
            nummer = int(treffer.group(1))
            if nummer != erwartet:
                befunde.append(ShinonNummerierungBefund(
                    code="E032",
                    zeile=index,
                    text=f"Nummerierungspflicht: Erwartet wurde Nummer {erwartet}, gefunden wurde {nummer}, die Abfolge muss lueckenlos bei 1 beginnen.",
                ))
                erwartet = nummer + 1
            else:
                erwartet += 1
        if not hat_inhalt:
            befunde.append(ShinonNummerierungBefund(
                code="E032",
                zeile=1,
                text="Nummerierungspflicht: Die Datei enthaelt keinen nummerierten Satz und ist damit leer im Sinne des Gates.",
            ))
        return befunde
