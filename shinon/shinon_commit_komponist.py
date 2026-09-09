# -*- coding: utf-8 -*-
"""Shinon Commit Komponist. Eigene Zuständigkeit: Die Commit-Nachricht aus shinon/commit_msg.txt bauen."""

import subprocess
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent
COMMIT_MSG_PFAD = PROJEKT_STAMM / "shinon" / "commit_msg.txt"


class ShinonCommitKomponist:
    """Der einzige erlaubte Weg zum Commit-Nachrichtentext.

    shinon/commit_msg.txt ist die Vorlage: Ihr Inhalt wird 1:1 zur
    Commit-Nachricht. Kein Werkzeug haengt Footer an, keine Zeile wird
    maschinell erzeugt oder ergaenzt. Der Agent fuellt die Datei von Hand,
    das Gate prueft sie, der Komponist liest sie nur.
    """

    def nachricht_lesen(self, pfad: Path | None = None) -> str:
        ziel = pfad or COMMIT_MSG_PFAD
        return ziel.read_text(encoding="utf-8").strip() + "\n"

    def commit_ausfuehren(self, zusatz_args: list[str] | None = None, pfad: Path | None = None) -> tuple[bool, str]:
        """Fuehrt git commit mit dem exakten Inhalt der Vorlage aus, ohne jeden Zusatz."""
        if not self.ist_git_repo():
            return False, "Kein Git Repository; Commit abgelehnt."
        vorlage = self.nachricht_lesen(pfad)
        if vorlage.strip() == "":
            return False, "shinon/commit_msg.txt ist leer; Commit abgelehnt (E034)."
        args = ["git", "commit", "-F", "-"]
        if zusatz_args:
            args.extend(zusatz_args)
        try:
            ergebnis = subprocess.run(
                args, cwd=str(PROJEKT_STAMM), input=vorlage,
                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=60,
            )
        except (OSError, subprocess.TimeoutExpired) as lauf_fehler:
            return False, f"git commit schlug fehl: {lauf_fehler}"
        if ergebnis.returncode != 0:
            return False, (ergebnis.stderr or ergebnis.stdout or "git commit fehlgeschlagen.").strip()
        return True, (ergebnis.stdout or "Commit erstellt.").strip()

    def ist_git_repo(self) -> bool:
        try:
            ergebnis = subprocess.run(
                ["git", "rev-parse", "--is-inside-work-tree"], cwd=str(PROJEKT_STAMM),
                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=30,
            )
        except (OSError, subprocess.TimeoutExpired):
            return False
        return ergebnis.returncode == 0 and (ergebnis.stdout or "").strip() == "true"
