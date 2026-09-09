# -*- coding: utf-8 -*-
"""Lauf-Log. Eigene Zuständigkeit: Schreibt Lauf-Ausgaben und hält immer nur den letzten Lauf.

Jede Log-Datei wird pro Lauf vollständig überschrieben, nie angehängt. Der
Godot-Headless-Rohlauf landet in godot_letzter_lauf.log, jede Scope-Auswahl
(--kategorie) bekommt ihre eigene Datei. Referenzen aus einem Befund zeigen
immer genau auf den Inhalt des letzten Laufs: Es gibt keine alten Zeilen,
die einem neuen Lauf nicht mehr zugeordnet werden können.

Logs liegen unter tools/logs/ und sind per .gitignore vom Repo ausgeschlossen.
"""

import re
from datetime import datetime
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent
LOG_ORDNER = PROJEKT_STAMM / "tools" / "logs"

# Erlaubte Kern-Log-Stämme: Nur diese werden ohne scope_ Präfix geschrieben,
# damit kein Sammelbecken entsteht. Jeder andere Scope erhält sein eigenes
# scope_-Log.
ERLAUBTE_LOGS = (
    "godot_letzter_lauf",       # roher Headless-Ausgabe-Stream des letzten Laufs
    "preflight_letzter_lauf",   # Zusammenfassung des letzten Preflight-Laufs
)

RESUMEE_MUSTER = re.compile(
    r"^(?P<code>E\d{3})\s*\|\s*(?P<datei>[^|]+?):(?P<zeile>\d+)\s*\|\s*(?P<text>.*)$")


class LaufLog:
    """Überschreibt je Scope die Log-Datei: Immer nur der letzte Lauf gilt."""

    def __init__(self) -> None:
        LOG_ORDNER.mkdir(parents=True, exist_ok=True)

    def pfad_fuer(self, scope: str) -> Path:
        # Scopes, die bereits auf _letzter_lauf enden (godot_letzter_lauf,
        # preflight_letzter_lauf), gelten als erlaubte Kern-Logs. Andere
        # Scope-Namen erhalten den Präfix scope_ und denselben Anhang.
        name = scope if scope.endswith("_letzter_lauf") else f"{scope}_letzter_lauf"
        if name not in ERLAUBTE_LOGS:
            name = f"scope_{name}"
        return LOG_ORDNER / f"{name}.log"

    def schreibe(self, scope: str, kopf: str, zeilen: list[str]) -> Path:
        """Überschreibt das Scope-Log komplett mit dem neuen Lauf."""
        ziel = self.pfad_fuer(scope)
        kopf_zeilen = [
            f"Letzter Lauf: {datetime.now().isoformat(timespec='seconds')}",
            f"Scope: {scope}",
            f"Kopf: {kopf}",
            "",
        ]
        ziel.write_text("\n".join(kopf_zeilen + zeilen) + "\n", encoding="utf-8")
        return ziel

    def referenz(self, scope: str, zeile: int) -> str:
        """Liefert die Referenz-Zeichenkette, die ein Befund in sein Log zeigt."""
        return f"tools/logs/{self.pfad_fuer(scope).name}:{zeile}"

    def lese_alle(self, scope: str) -> list[str]:
        ziel = self.pfad_fuer(scope)
        if not ziel.is_file():
            return []
        return ziel.read_text(encoding="utf-8").splitlines()

    def lese_zeile(self, scope: str, zeile: int) -> str:
        ziel = self.pfad_fuer(scope)
        if not ziel.is_file():
            return ""
        inhalt = ziel.read_text(encoding="utf-8").splitlines()
        if 1 <= zeile <= len(inhalt):
            return inhalt[zeile - 1]
        return ""

    def summarisiere_godot_befunde(self, zeilen: list[str]) -> list[dict]:
        """Liest die Godot-Rohzeilen und liefert die translated Befunde als Wörterbuch."""
        befunde = []
        for index, roh in enumerate(zeilen, start=1):
            for muster in ("ERROR", "WARNING", "Parse Error", "SCRIPT ERROR"):
                if muster in roh:
                    befunde.append({"log_zeile": index, "roh": roh.strip()})
                    break
        return befunde
