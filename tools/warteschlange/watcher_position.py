# -*- coding: utf-8 -*-
"""Watcher Position. Eigene Zuständigkeit: Sortierung, Position, Status."""

import json
import time
from pathlib import Path

from .ticket_werkzeuge import RESSOURCE_DAUERN, STALE_SEKUNDEN, pid_lebt, ressource_ordner, ticket_epoch, ticket_pid


def raeume_stale(ressource: str) -> int:
    ordner = ressource_ordner(ressource)
    geraeumt = 0
    jetzt = time.time()
    for ticket in ordner.glob("*.json"):
        epoch = ticket_epoch(ticket)
        alter = jetzt - epoch
        pid = ticket_pid(ticket)
        tot = pid is not None and not pid_lebt(pid)
        if (alter > STALE_SEKUNDEN and alter < 1e9) or tot:
            try:
                ticket.unlink()
                geraeumt += 1
            except OSError:
                pass
    return geraeumt


def sortierte_tickets(ressource: str) -> list[Path]:
    ordner = ressource_ordner(ressource)
    def sort_key(p: Path) -> tuple[float, str]:
        return (ticket_epoch(p), p.name)
    return sorted(ordner.glob("*.json"), key=sort_key)
