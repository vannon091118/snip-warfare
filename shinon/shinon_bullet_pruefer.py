# -*- coding: utf-8 -*-
"""Shinon Bullet Prüfer. Eigene Zuständigkeit: Bullet Listen Verbot."""

import re
from dataclasses import dataclass

BULLET_MUSTER = re.compile(r"^\s*[-*•+]\s+")


@dataclass(frozen=True)
class ShinonBulletBefund:
    code: str
    zeile: int
    text: str


class ShinonBulletPruefer:
    """Erkennt Bullet Zeilen mechanisch. Jede Bullet Zeile ist E031."""

    def pruefen(self, zeilen: list[str]) -> list[ShinonBulletBefund]:
        befunde: list[ShinonBulletBefund] = []
        for index, zeile in enumerate(zeilen, start=1):
            if zeile.strip() == "":
                continue
            if BULLET_MUSTER.match(zeile):
                befunde.append(ShinonBulletBefund(
                    code="E031",
                    zeile=index,
                    text="Bullet Verbot: Zeile beginnt mit einem Bullet Zeichen und verstoesst damit gegen die Pflicht zu ganzen nummerierten Saetzen.",
                ))
        return befunde
