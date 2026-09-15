# -*- coding: utf-8 -*-
"""Pipeline. Eigene Zuständigkeit: Die logische Reihe.

Kein if-Teppich mehr. Die Reihe ist Vertrag:
  0 Selbsttest E000  immer fail-closed
  1 Statik           schnell ohne Lock
  2 Lauf             godot via watcher_godot
  3 Beweis           sonden via watcher_fenster
  4 Gate             shinon prüft commit_msg
  5 Publish          watcher_git nur wenn 0-4 grün

Jede Phase schreibt ihr scope_log, die nächste liest nur diese.
Kein Spielcode, kein Sonden-Code kennt die Reihe — nur dieser Kern.
"""

from dataclasses import dataclass

from .fehler_speicher import FehlerSpeicher
from .projekt_stamm import PROJEKT_STAMM

# Phasen in fester Reihenfolge — das ist der Vertrag.
PHASEN = [
    ("selbsttest", ("E000",)),
    (
        "statik",
        (
            "E001", "E002", "E003", "E004", "E005", "E006", "E007", "E008", "E009", "E010",
            "E011", "E012", "E013", "E014", "E015", "E019", "E020", "E021", "E022",
            "E023", "E024", "E025", "E040", "E041", "E042", "E043", "E044", "E045",
            "E047", "E048", "E049", "E050", "E051",
        ),
    ),
    ("lauf", ("E016", "E017", "E018", "E025", "E052", "E053", "E054")),
    ("beweis", ("E026", "E027", "E028", "E029")),
    ("gate", ("E030", "E031", "E032", "E033", "E034", "E035", "E036", "E037", "E038", "E039")),
]

KATEGORIE_ZU_PHASE = {
    "klassen": "statik",
    "trennung": "statik",
    "daten": "statik",
    "datenparitaet": "statik",
    "determinismus": "statik",
    "pfade": "statik",
    "registries": "statik",
    "pyramide": "statik",
    "biome": "statik",
    "einheitlich": "statik",
    "welt": "statik",
    "warnungen": "statik",
    "locregel": "statik",
    "bau_kette": "statik",
    "engine_bruecken": "statik",
    "whitespace": "statik",
    "version": "statik",
    "index": "statik",
    "assets": "statik",
    "godot": "lauf",
    "visual": "lauf",
    "sonden": "beweis",
    "shinon": "gate",
}

PHASE_ZU_KATEGORIEN = {
    "selbsttest": [],
    "statik": ["klassen", "trennung", "determinismus", "pfade", "registries", "warnungen", "pyramide", "daten", "datenparitaet", "locregel", "bau_kette", "engine_bruecken", "whitespace", "version", "index", "assets", "biome", "einheitlich", "welt"],
    "lauf": ["godot", "visual"],
    "beweis": ["sonden"],
    "gate": ["shinon"],
}


def _phase_fuer_kategorie(kategorie: str) -> str:
    return KATEGORIE_ZU_PHASE.get(kategorie.lower(), "statik")


def phasen_fuer_gewaehlt(gewaehlt: set[str]) -> list[str]:
    geordnet: list[str] = []
    for phase, _codes in PHASEN:
        if phase == "selbsttest":
            geordnet.append(phase)
            continue
        for kat in gewaehlt:
            if _phase_fuer_kategorie(kat) == phase:
                geordnet.append(phase)
                break
    # Deduplizieren in Reihenfolge.
    gesehen: set[str] = set()
    out: list[str] = []
    for p in geordnet:
        if p not in gesehen:
            out.append(p)
            gesehen.add(p)
    return out


@dataclass
class PipelineErgebnis:
    gewaehlt: set[str]
    phasen: list[str]
    befunde: list
