# -*- coding: utf-8 -*-
"""Shinon Banner Prüfer. Eigene Zuständigkeit: Tralal Banner Verbot."""

import re
from dataclasses import dataclass

BANNER_MUSTER = re.compile(r"([=\-#*~_])\1{10,}")
BANNER_WOERTER = ("tralal",)


@dataclass(frozen=True)
class ShinonBannerBefund:
    code: str
    zeile: int
    text: str


class ShinonBannerPruefer:
    """Erkennt Banner Zeilen mechanisch. Jede gefundene Zeile ist E030."""

    def pruefen(self, zeilen: list[str]) -> list[ShinonBannerBefund]:
        befunde: list[ShinonBannerBefund] = []
        for index, zeile in enumerate(zeilen, start=1):
            gestrippt = zeile.strip()
            if gestrippt == "":
                continue
            if BANNER_MUSTER.search(zeile):
                befunde.append(ShinonBannerBefund(
                    code="E030",
                    zeile=index,
                    text="Banner Verbot: Zeile enthaelt eine Kette aus mehr als zehn gleichen Sonderzeichen und wirkt wie ein dekorativer Rahmen.",
                ))
                continue
            niedrig = gestrippt.lower()
            for wort in BANNER_WOERTER:
                if wort in niedrig:
                    befunde.append(ShinonBannerBefund(
                        code="E030",
                        zeile=index,
                        text="Banner Verbot: Zeile enthaelt das Wort Tralal und zaehlt damit als Banner.",
                    ))
                    break
        return befunde
