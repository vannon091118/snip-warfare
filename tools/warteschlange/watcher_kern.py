# -*- coding: utf-8 -*-
"""Warteschlange Watcher Kern. Fassade über echte Teil-Domänen."""

import json
import os
import time
from dataclasses import dataclass
from pathlib import Path

from .watcher_orphan import kill_orphans_fenster

from .ticket_werkzeuge import (
    RESSOURCE_DAUERN,
    WARTESCHLANGE_STAMM,
    agent_id,
    ressource_ordner,
    ticket_epoch,
)
from .watcher_position import raeume_stale as _raeume_stale, sortierte_tickets as _sortierte


@dataclass(frozen=True)
class TicketPosition:
    ressource: str
    position: int
    gesamt: int
    ist_aktiv: bool
    warte_sekunden: int
    aktiv_seit_sekunden: int | None
    aktiv_agent: str | None
    ticket_name: str


def raeume_stale(ressource: str) -> int:
    return _raeume_stale(ressource)


def _sortierte_tickets(ressource: str) -> list[Path]:
    return _sortierte(ressource)


def position_fuer(ressource: str, ticket_name: str) -> TicketPosition | None:
    raeume_stale(ressource)
    tickets = _sortierte_tickets(ressource)
    for idx, ticket in enumerate(tickets, start=1):
        if ticket.name == ticket_name:
            dauer = RESSOURCE_DAUERN.get(ressource, 60)
            warte = max(0, (idx - 1) * dauer)
            aktiv_ticket = tickets[0] if tickets else None
            aktiv_seit = None
            aktiv_agent = None
            if aktiv_ticket is not None and aktiv_ticket.is_file():
                try:
                    data = json.loads(aktiv_ticket.read_text(encoding="utf-8"))
                    aktiv_agent = str(data.get("agent", ""))
                    aktiv_seit = int(time.time() - ticket_epoch(aktiv_ticket))
                except Exception:
                    aktiv_seit = int(time.time() - ticket_epoch(aktiv_ticket))
                    aktiv_agent = aktiv_ticket.stem
            return TicketPosition(ressource, idx, len(tickets), idx == 1, warte, aktiv_seit, aktiv_agent, ticket_name)
    return None


def status_ohne_ticket(ressource: str) -> str:
    raeume_stale(ressource)
    tickets = _sortierte_tickets(ressource)
    if not tickets:
        return f"WARTESCHLANGE {ressource} frei"
    aktiv = tickets[0]
    try:
        data = json.loads(aktiv.read_text(encoding="utf-8"))
        agent = str(data.get("agent", aktiv.stem))
        seit = int(time.time() - float(data.get("epoch", ticket_epoch(aktiv))))
    except Exception:
        agent = aktiv.stem
        seit = int(time.time() - ticket_epoch(aktiv))
    return f"WARTESCHLANGE {ressource} Position 1/{len(tickets)} aktiv {agent} seit {seit}s"


def belege(ressource: str) -> tuple[Path, TicketPosition]:
    raeume_stale(ressource)
    pid = os.getpid()
    agent = agent_id()
    ordner = ressource_ordner(ressource)
    for _ in range(5):
        now = time.time()
        name = f"{int(now * 1000)}_{pid}_{agent}.json"
        pfad = ordner / name
        payload = {"ressource": ressource, "agent": agent, "pid": pid, "epoch": now}
        try:
            fd = os.open(str(pfad), os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump(payload, f, ensure_ascii=False, indent=2)
            pos = position_fuer(ressource, pfad.name)
            assert pos is not None
            return pfad, pos
        except FileExistsError:
            time.sleep(0.01)
            continue
    raise RuntimeError(f"Warteschlange {ressource}: Ticket nach 5 Versuchen fehlgeschlagen")


def freigeben(ticket_pfad: Path) -> None:
    try:
        ticket_pfad.unlink()
    except OSError:
        pass


def formatiere_position(pos: TicketPosition) -> str:
    if pos.ist_aktiv:
        return f"WARTESCHLANGE {pos.ressource} Position {pos.position}/{pos.gesamt} aktiv ~{pos.warte_sekunden}s"
    aktiv = f" aktiv {pos.aktiv_agent} seit {pos.aktiv_seit_sekunden}s" if pos.aktiv_agent else ""
    return f"WARTESCHLANGE {pos.ressource} Position {pos.position}/{pos.gesamt} ~{pos.warte_sekunden}s{aktiv}"
