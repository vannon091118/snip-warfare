# -*- coding: utf-8 -*-
"""Shinon Git Helfer. Eigene Zuständigkeit: Git lokal und GitHub remote über gh sicher bedienen."""

import subprocess
import shutil
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent


class ShinonGitHelfer:
    """Führt nur Git und gh Befehle aus, nimmt niemals einen Zustand aus einem anderen lokalen Projekt."""

    def _lauf(self, befehl: list[str], cwd: Path | None = None) -> tuple[int, str, str]:
        ergebnis = subprocess.run(
            befehl, cwd=str(cwd or PROJEKT_STAMM),
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=60,
        )
        return ergebnis.returncode, ergebnis.stdout or "", ergebnis.stderr or ""

    def ist_git_repo(self) -> bool:
        code, out, _err = self._lauf(["git", "rev-parse", "--is-inside-work-tree"])
        return code == 0 and out.strip() == "true"

    def git_init(self) -> tuple[bool, str]:
        if self.ist_git_repo():
            return True, "Bereits ein Git Repository."
        code, out, err = self._lauf(["git", "init"])
        if code != 0:
            return False, f"git init schlug fehl: {err or out}"
        self._lauf(["git", "branch", "-M", "main"])
        return True, out.strip() or "Git Repository angelegt."

    def gh_verfuegbar(self) -> bool:
        return shutil.which("gh") is not None

    def gh_auth_ok(self) -> tuple[bool, str]:
        if not self.gh_verfuegbar():
            return False, "gh ist nicht installiert."
        code, out, err = self._lauf(["gh", "auth", "status"])
        kombiniert = (out + err).lower()
        if code == 0 and "logged in" in kombiniert:
            return True, (out or err).strip()
        return False, (err or out).strip() or "gh ist nicht eingeloggt."

    def github_repo_existiert(self, voll_name: str) -> bool:
        if not self.gh_verfuegbar():
            return False
        code, _out, _err = self._lauf(["gh", "repo", "view", voll_name])
        return code == 0

    def github_repo_erstellen(self, voll_name: str, beschreibung: str, privat: bool = False) -> tuple[bool, str]:
        if self.github_repo_existiert(voll_name):
            return True, f"Repository {voll_name} existiert bereits."
        sicht = "--private" if privat else "--public"
        code, out, err = self._lauf([
            "gh", "repo", "create", voll_name, sicht,
            "--description", beschreibung,
        ])
        if code != 0:
            return False, f"gh repo create schlug fehl: {err or out}"
        return True, out.strip() or f"Repository {voll_name} erstellt."

    def remote_setzen(self, voll_name: str) -> tuple[bool, str]:
        url = f"https://github.com/{voll_name}.git"
        # Bestehenden origin entfernen falls vorhanden, dann neu setzen.
        self._lauf(["git", "remote", "remove", "origin"])
        code, out, err = self._lauf(["git", "remote", "add", "origin", url])
        if code != 0:
            return False, f"git remote add schlug fehl: {err or out}"
        return True, f"Remote origin auf {url} gesetzt."

    def status_kurz(self) -> str:
        code, out, err = self._lauf(["git", "status", "--porcelain"])
        if code != 0:
            return err or out
        return out.strip() or "Arbeitsbereich sauber."

    def letzter_commit(self) -> str:
        code, out, _err = self._lauf(["git", "log", "--oneline", "-1"])
        if code != 0:
            return "Noch kein Commit vorhanden."
        return out.strip()
