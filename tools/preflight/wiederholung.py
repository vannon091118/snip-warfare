# -*- coding: utf-8 -*-
"""Wiederholung. Eigene Zuständigkeit: Mechanischer Retry nur für lauf und beweis.

Kein statik, kein gate wird je wiederholt — nur flackrige Ressourcen.
Backoff 2s, 5s. Jeder Versuch schreibt ins Lauf-Log, letzter gewinnt.
"""

import time
from collections.abc import Callable


WIEDERHOLBARE_PHASEN = {"lauf", "beweis"}
MAX_WIEDERHOLUNGEN = 3
BACKOFF_SEKUNDEN = [2, 5]


def soll_wiederholen(phase: str, versuch: int, max_versuche: int, hat_befund: bool) -> bool:
    if phase not in WIEDERHOLBARE_PHASEN:
        return False
    if max_versuche < 2 or max_versuche > MAX_WIEDERHOLUNGEN:
        return False
    if versuch >= max_versuche:
        return False
    return hat_befund


def warte_backoff(versuch: int) -> None:
    idx = min(versuch - 1, len(BACKOFF_SEKUNDEN) - 1)
    if idx >= 0:
        time.sleep(BACKOFF_SEKUNDEN[idx])


def mit_wiederholung(phase: str, fn: Callable[[], bool], max_versuche: int, log_fn: Callable[[str], None] | None = None) -> bool:
    """Führt fn aus, wiederholt bei Befund nur für lauf/beweis. Gibt letzten Erfolg."""
    max_versuche = max(1, min(max_versuche, MAX_WIEDERHOLUNGEN))
    for versuch in range(1, max_versuche + 1):
        ok = fn()
        if ok or not soll_wiederholen(phase, versuch, max_versuche, not ok):
            if log_fn and max_versuche > 1:
                log_fn(f"Wiederholung {phase} Versuch {versuch}/{max_versuche} {'OK' if ok else 'Befund — retry' if versuch < max_versuche else 'Befund — Ende'}")
            if ok or versuch >= max_versuche:
                return ok
        if log_fn:
            log_fn(f"Wiederholung {phase} Versuch {versuch}/{max_versuche} Befund — warte {BACKOFF_SEKUNDEN[min(versuch-1, len(BACKOFF_SEKUNDEN)-1)]}s")
        warte_backoff(versuch)
    return False
