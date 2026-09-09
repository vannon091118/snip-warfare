# -*- coding: utf-8 -*-
"""Shinon Nennung Prüfer. Eigene Zuständigkeit: Jede geänderte Datei muss namentlich in der Commit-Erzählung vorkommen."""

import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent

@dataclass(frozen=True)
class ShinonNennungBefund:
    code: str
    zeile: int
    text: str


class ShinonNennungPruefer:
    """Verlangt, dass jede geänderte Datei namentlich in shinon/commit_msg.txt genannt wird.

    Die commit_msg.txt ist die Vorlage für den Commit-Beschreibungstext.
    Kein Satz darf sich auf "irgendwelche Dateien" beziehen: Jede Zeile die
    von Arbeit spricht, muss den konkreten Dateinamen tragen. Namen ohne
    Dateiendung gelten nicht als Nennung, damit Klassen nicht als Deckmantel
    durchgehen. Keine Zeilen-Erzeugung durch das Werkzeug: Das Werkzeug liest
    und prüft nur, es schreibt nie in die Datei.
    """

    # Ein Dateiname hat eine Endung mit 1-4 Buchstaben oder Ziffern (gd, py, json, tscn, md, svg ...).
    NENNUNG_MUSTER = re.compile(r"\b[\w\-.]+\.(gd|py|json|tscn|md|svg|png|txt|cfg|import|godot)\b", re.IGNORECASE)

    # Eigenordner des Gates: die Vorlage selbst und Gate-Skripte muessen sich
    # nicht selbst nennen, sonst blockiert das Gate die eigene Pflege.
    SELBST_AUSNAHMEN = ("commit_msg.txt", "shinon_gate.py", "shinon_footer_pruefer.py",
                        "shinon_nennung_pruefer.py", "preflight.py")

    def geaenderte_dateien(self) -> list[str]:
        """Liest die geänderten Dateien der Staging-Area, sonst des Arbeitsbereichs, aus Git."""
        namen: list[str] = []
        for args in (
            ["git", "diff", "--cached", "--name-only"],
            ["git", "diff", "--name-only"],
        ):
            try:
                ergebnis = subprocess.run(
                    args, cwd=str(PROJEKT_STAMM), capture_output=True, text=True,
                    encoding="utf-8", errors="replace", timeout=30,
                )
            except (OSError, subprocess.TimeoutExpired):
                continue
            if ergebnis.returncode != 0:
                continue
            for zeile in (ergebnis.stdout or "").splitlines():
                name = zeile.strip().replace("\\", "/")
                if name != "" and not name.endswith(".pyc") and "__pycache__" not in name:
                    namen.append(name)
            if namen:
                break
        return sorted(set(namen))

    def pruefen(self, zeilen: list[str]) -> list[ShinonNennungBefund]:
        befunde: list[ShinonNennungBefund] = []
        geaenderte = self.geaenderte_dateien()
        if not geaenderte:
            # Ohne Git-Befund (frisch geklont, oder alles committed) gilt nur die Lesepflicht.
            return befunde
        inhalt = "\n".join(zeilen)
        for name in geaenderte:
            basis = name.rsplit("/", 1)[-1]
            if basis in self.SELBST_AUSNAHMEN:
                continue
            if not self.NENNUNG_MUSTER.search(name):
                continue
            # Nennung als Dateiname mit Endung, egal ob mit oder ohne Ordnerpfad.
            if not re.search(re.escape(basis), inhalt):
                befunde.append(ShinonNennungBefund(
                    code="E038",
                    zeile=1,
                    text=f"Nennungspflicht: Die geaenderte Datei {basis} wird in shinon/commit_msg.txt nirgends namentlich genannt; die Vorlage muss jede Datei beim Namen rufen.",
                ))
        return befunde
