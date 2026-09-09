# -*- coding: utf-8 -*-
"""Shinon Stil Prüfer. Eigene Zuständigkeit: organische Nachrichten statt Endlos-Aufzählungen.
Verboten sind aufgeblähte Sätze (und dann und dann und dann), überlange Sätze und
Nachrichten, die mehr erzählen als nötig. Die Nummerierung bleibt Pflicht (E032),
dieser Prüfer begrenzt nur die Erzählung selbst."""

import re
from dataclasses import dataclass

MAX_ZEICHEN_PRO_SATZ = 400
MAX_ZEICHEN_GESAMT = 2600
KETTE_MUSTER = re.compile(r"und dann")
# Eine echte Endlos-Aufzaehlung beginnt bei drei Vorkommen von und dann;
# zwei Vorkommen sind noch ein organischer Dreischritt oder eine wörtliche
# Beschreibung der Regel selbst und bleiben erlaubt.

@dataclass(frozen=True)
class ShinonStilBefund:
    code: str
    zeile: int
    text: str


class ShinonStilPruefer:
    """Stil Constraints: jeder Satz bleibt organisch und kurz, keine Ketten-Aufzählung."""

    def pruefen(self, zeilen: list[str]) -> list[ShinonStilBefund]:
        befunde: list[ShinonStilBefund] = []
        gesamtzahl = 0
        for index, zeile in enumerate(zeilen, start=1):
            gestrippt = zeile.strip()
            if gestrippt == "":
                continue
            gesamtzahl += len(gestrippt)
            if len(gestrippt) > MAX_ZEICHEN_PRO_SATZ:
                befunde.append(ShinonStilBefund(
                    code="E039",
                    zeile=index,
                    text="Stilpflicht: Der Satz ist mit %d Zeichen länger als %d und reiht nur noch aneinander, kürze ihn auf das Nötigste." % (len(gestrippt), MAX_ZEICHEN_PRO_SATZ),
                ))
            ketten = len(KETTE_MUSTER.findall(gestrippt))
            if ketten >= 3:
                befunde.append(ShinonStilBefund(
                    code="E039",
                    zeile=index,
                    text="Stilpflicht: Der Satz wiederholt 'und dann' %d mal und wird zur Endlos-Aufzählung, erzähle organisch in einem Zug." % ketten,
                ))
        if gesamtzahl > MAX_ZEICHEN_GESAMT:
            befunde.append(ShinonStilBefund(
                code="E039",
                zeile=1,
                text="Stilpflicht: Die Nachricht umfasst %d Zeichen und ist damit aufgebläht über %d, halte sie organisch und schlank." % (gesamtzahl, MAX_ZEICHEN_GESAMT),
            ))
        return befunde