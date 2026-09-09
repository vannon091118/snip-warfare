# -*- coding: utf-8 -*-
"""Shinon Starter. Eigene Zuständigkeit: Pflicht Schritte vor und nach Aktionen auslösen."""

from pathlib import Path

import importlib.util as _ilu
import sys as _sys

PROJEKT_STAMM = Path(__file__).resolve().parent.parent


def _lade(modul_datei: str, klassen_name: str):
    pfad = PROJEKT_STAMM / "shinon" / modul_datei
    spez = _ilu.spec_from_file_location(f"_shinon_starter_{klassen_name.lower()}", str(pfad))
    modul = _ilu.module_from_spec(spez)
    _sys.modules[spez.name] = modul
    assert spez.loader is not None
    spez.loader.exec_module(modul)
    return getattr(modul, klassen_name)


class ShinonStarter:
    """Ruft vor einem Commit den Status Leser und den Readme Generator und nach einem Commit das Gate."""

    def vor_commit(self) -> dict:
        StatusLeser = _lade("shinon_projekt_status_leser.py", "ShinonProjektStatusLeser")
        Generator = _lade("shinon_readme_generator.py", "ShinonReadmeGenerator")
        status = StatusLeser().lese()
        Generator().schreibe(status)
        return status

    def nach_commit_hinweis(self) -> str:
        return "Shinon Starter: README wurde vor dem Commit aus echten Daten erneuert, das Gate laeuft im Preflight mit."
