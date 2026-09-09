# -*- coding: utf-8 -*-
"""Shinon Footer Prüfer. Eigene Zuständigkeit: Fremd-Footer und Signatur-Zeilen sind verboten."""

import re
from dataclasses import dataclass

# Erkennt Agent-Footer und Signaturzeilen, die Shinon niemals duldet:
# der Codebuff Fuss, Co-Authored-By Ketten, Claude/GPT/Copilot Signaturen
# und Generated-with Zeilen jeder Herkunft.
FOOTER_MUSTER = re.compile(
    r"("
    r"generated\s+with"
    r"|co-authored-by\s*:"
    r"|signed-off-by\s*:"
    r"|\bcodebuff\b"
    r"|\bclaude\b"
    r"|\bcodex\b"
    r"|\bcopilot\b"
    r"|\bopenai\b"
    r"|\banthropic\b"
    r"|🤖"
    r")",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class ShinonFooterBefund:
    code: str
    zeile: int
    text: str


class ShinonFooterPruefer:
    """Jede Footer- oder Signaturzeile in shinon/commit_msg.txt meldet E037.

    Die Commit-Nachricht gehört Shinon allein: Kein Agent haengt seinen
    eigenen Fuss an, keine werkzeugseitige Signatur wird durchgereicht.
    """

    def pruefen(self, zeilen: list[str]) -> list[ShinonFooterBefund]:
        befunde: list[ShinonFooterBefund] = []
        for index, zeile in enumerate(zeilen, start=1):
            if zeile.strip() == "":
                continue
            treffer = FOOTER_MUSTER.search(zeile)
            if treffer is not None:
                befunde.append(ShinonFooterBefund(
                    code="E037",
                    zeile=index,
                    text="Footer Verbot: Zeile traegt einen fremden Agent-Footer oder eine Werkzeug-Signatur; die Commit-Nachricht gehoert Shinon allein.",
                ))
        return befunde
