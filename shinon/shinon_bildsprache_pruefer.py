# -*- coding: utf-8 -*-
"""Shinon Bildsprache Prüfer. Eigene Zuständigkeit: nicht technische sondern bildliche Wiedergabe."""

import re
from dataclasses import dataclass

TECHNIK_MUSTER = re.compile(r"(res://|`{1,3}[^`]+`{1,3}|\b[A-Z][A-Za-z0-9_]*\.[a-z]{2,4}\b)")


@dataclass(frozen=True)
class ShinonBildspracheBefund:
    code: str
    zeile: int
    text: str


class ShinonBildsprachePruefer:
    """Rein technische Aufzaehlung ohne Bildsprache meldet E033."""

    def pruefen(self, zeilen: list[str]) -> list[ShinonBildspracheBefund]:
        befunde: list[ShinonBildspracheBefund] = []
        for index, zeile in enumerate(zeilen, start=1):
            gestrippt = zeile.strip()
            if gestrippt == "":
                continue
            # Nur Zeilen die dominant technisch wirken werden beanstandet.
            # Eine bildliche Zeile darf Pfade erwaehnen, aber nicht nur aus Pfaden bestehen.
            if TECHNIK_MUSTER.search(gestrippt):
                woerter = gestrippt.split()
                technik_treffer = len(TECHNIK_MUSTER.findall(gestrippt))
                # Wenn mehr als die Haelfte der Woerter technische Token sind, ist es keine bildliche Erzaehlung.
                if technik_treffer >= max(1, len(woerter) // 2):
                    befunde.append(ShinonBildspracheBefund(
                        code="E033",
                        zeile=index,
                        text="Bildsprachepflicht: Zeile erzaehlt nicht bildlich sondern reiht nur technische Pfade oder Code Token aneinander.",
                    ))
            woerter = gestrippt.split()
            if len(woerter) < 5:
                befunde.append(ShinonBildspracheBefund(
                    code="E033",
                    zeile=index,
                    text="Bildsprachepflicht: Zeile ist zu kurz um als ganzer bildlicher Satz zu gelten, mindestens fuenf Woerter sind verlangt.",
                ))
        return befunde
