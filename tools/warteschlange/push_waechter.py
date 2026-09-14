# -*- coding: utf-8 -*-
"""Push Waechter. Eigene Zuständigkeit: Fern-Stand vor dem Push prüfen und bei fremden Commits rebasieren."""

import subprocess
import sys

PROJEKT_STAMM = None  # wird von lauf() genutzt; relativ zum Aufrufer


def lauf(args: list[str]) -> tuple[int, str, str]:
    ergebnis = subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120)
    return ergebnis.returncode, (ergebnis.stdout or ""), (ergebnis.stderr or "")


class PushWaechter:
    """Vergleicht vor jedem Push den Fern-Stand mit dem Lokalen.

    Findet er fremde Commits (die nicht von der eigenen Reihe stammen),
    so prüft er, ob die Arbeitskopie leer ist, und rebasiert die Reihe
    auf die Fern-Spitze. Schlägt der Rebase fehl, bricht er ab, statt
    einen veralteten Stand zu erzwingen.
    """

    def __init__(self, ausgeben=print):
        self.ausgeben = ausgeben

    def fern_spitze_holen(self) -> bool:
        code, _, fehler = lauf(["git", "fetch", "origin"])
        if code != 0:
            self.ausgeben(f"Push Wächter: fetch fehlgeschlagen: {fehler.strip()}")
            return False
        return True

    def fremde_commits(self) -> list[str]:
        code, aus, fehler = lauf(["git", "rev-list", "--right-only", "--count", "HEAD...origin/main"])
        if code != 0:
            self.ausgeben(f"Push Wächter: rev-list fehlgeschlagen: {fehler.strip()}")
            return []
        zahl = int((aus or "0").strip() or "0")
        if zahl == 0:
            return []
        code, aus, _ = lauf(["git", "rev-list", "--right-only", "--oneline", "HEAD...origin/main"])
        return [z for z in (aus or "").strip().splitlines() if z.strip()]

    def arbeitskopie_leer(self) -> bool:
        code, aus, _ = lauf(["git", "status", "--porcelain"])
        if code != 0:
            return False
        return (aus or "").strip() == ""

    def rebasieren(self) -> bool:
        if not self.arbeitskopie_leer():
            self.ausgeben("Push Wächter: Arbeitskopie schmutzig — Rebase abgelehnt")
            return False
        code, aus, fehler = lauf(["git", "rebase", "origin/main"])
        if code != 0:
            self.ausgeben(f"Push Wächter: Rebase fehlgeschlagen — Abbruch\n{aus}\n{fehler}")
            lauf(["git", "rebase", "--abort"])
            return False
        self.ausgeben("Push Wächter: auf origin/main gerebt")
        return True

    def pruefen(self) -> bool:
        """Liefert True, wenn der lokale Stand sicher gepusht werden darf."""
        if not self.fern_spitze_holen():
            return False
        fremde = self.fremde_commits()
        if not fremde:
            return True
        self.ausgeben(f"Push Wächter: {len(fremde)} fremde Commit(s) auf origin/main:")
        for zeile in fremde:
            self.ausgeben(f"  {zeile}")
        return self.rebasieren()


if __name__ == "__main__":
    waechter = PushWaechter()
    sys.exit(0 if waechter.pruefen() else 1)
