# -*- coding: utf-8 -*-
"""Fehler Speicher. Eigene Zuständigkeit: Sammlung aller Preflight Befunde.

Kein Modul hält mehr eine globale Liste. Der Speicher wird pro Pipeline-Lauf
erzeugt und per Konstruktor weitergegeben.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class Befund:
    code: str
    datei: str
    zeile: int
    text: str


class FehlerSpeicher:
    def __init__(self) -> None:
        self._fehler: list[Befund] = []

    def melde(self, code: str, datei, zeile: int, text: str) -> None:
        eintrag = Befund(code, str(datei), zeile, text)
        if eintrag not in self._fehler:
            self._fehler.append(eintrag)

    def alle(self) -> list[Befund]:
        return list(self._fehler)

    def gefiltert(self, codes: set[str]) -> list[Befund]:
        return [b for b in self._fehler if b.code in codes]

    def anzahl(self) -> int:
        return len(self._fehler)
