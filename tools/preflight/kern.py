# -*- coding: utf-8 -*-
"""Kern Fassade. Eigene Zuständigkeit: Rückwärtskompatibler Importweg.

Der Monolith ist zerlegt in echte Domänen:
  projekt_stamm, fehler_speicher, datei_sammlung, godot_aufloeser,
  lauf_log_bruecke, kategorien, determinismus_regeln, typ_regeln.
Diese Datei reexportiert nur — kein neuer Code darf hier wachsen.
"""

from .datei_sammlung import klassen_name_lesen, lies_dateien, zeile_bei, zeile_von
from .determinismus_regeln import (
    BUILTIN_HASH_MUSTER,
    ERLAUBTE_HASH_KLASSEN,
    ERLAUBTE_ZUFALLS_KLASSEN,
    ZEIT_SEED_MUSTER,
    ZUFALLS_MUSTER,
    ZWEITER_RNG_MUSTER,
)
from .typ_regeln import ARRAY_BASISTYPEN
from .fehler_speicher import Befund, FehlerSpeicher
from .godot_aufloeser import GODOT_EXTERN_FALLBACK, GODOT_FEHLER_MUSTER, GODOT_LOKAL_KANDIDATEN, aufloese_godot
from .kategorien import KATEGORIE_PRAEFIXE, KATEGORIEN_TRENNUNG
from .lauf_log_bruecke import lade_lauf_log
from .projekt_stamm import PROJEKT_STAMM

# Globale Instanz für Altaufrufe — neue Aufrufer nutzen FehlerSpeicher direkt.
_SPEICHER = FehlerSpeicher()
FEHLER: list[tuple[str, str, int, str]] = []  # type: ignore[var-annotated]


def fehler(code: str, datei, zeile: int, text: str) -> None:
    eintrag = (code, str(datei), zeile, text)
    if eintrag not in FEHLER:
        FEHLER.append(eintrag)
    _SPEICHER.melde(code, datei, zeile, text)


def _verzeichnis_ignoriert(pfad) -> bool:
    rel = pfad.relative_to(PROJEKT_STAMM)
    teile = rel.parts
    if not teile:
        return False
    return teile[0] in {"addons", "mcp_tools", ".godot", ".freebuff", "tools/godot"} or (
        len(teile) > 1 and "/".join(teile[:2]) == "tools/godot"
    )


def _lade_lauf_log():
    return lade_lauf_log()


__all__ = [
    "PROJEKT_STAMM",
    "KATEGORIE_PRAEFIXE",
    "KATEGORIEN_TRENNUNG",
    "ERLAUBTE_ZUFALLS_KLASSEN",
    "ZUFALLS_MUSTER",
    "ZEIT_SEED_MUSTER",
    "ZWEITER_RNG_MUSTER",
    "ERLAUBTE_HASH_KLASSEN",
    "BUILTIN_HASH_MUSTER",
    "ARRAY_BASISTYPEN",
    "GODOT_FEHLER_MUSTER",
    "GODOT_EXTERN_FALLBACK",
    "GODOT_LOKAL_KANDIDATEN",
    "FEHLER",
    "fehler",
    "zeile_von",
    "zeile_bei",
    "_verzeichnis_ignoriert",
    "lies_dateien",
    "klassen_name_lesen",
    "_lade_lauf_log",
    "aufloese_godot",
    "Befund",
    "FehlerSpeicher",
]
