# -*- coding: utf-8 -*-
"""Godot Warteschlange. Eigene Zuständigkeit: Ticket für godot_headless."""

from .kern import fehler


def belege_godot_ticket():
    try:
        from tools.warteschlange.watcher_kern import belege, formatiere_position, position_fuer, freigeben
        ticket, pos = belege("godot_headless")
        print(formatiere_position(pos))
        if not pos.ist_aktiv:
            import time
            while True:
                time.sleep(5)
                npos = position_fuer("godot_headless", ticket.name)
                if npos is None:
                    fehler("E018", "godot", 0, "Warteschlange Ticket verschwunden")
                    freigeben(ticket)
                    return None
                print(formatiere_position(npos))
                if npos.ist_aktiv:
                    break
        return ticket
    except Exception:
        return None


def freigeben_godot_ticket(ticket):
    if ticket is None:
        return
    try:
        from tools.warteschlange.watcher_kern import freigeben as _fg
        _fg(ticket)
    except Exception:
        pass
