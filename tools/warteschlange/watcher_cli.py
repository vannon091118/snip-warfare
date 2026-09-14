# -*- coding: utf-8 -*-
"""Warteschlange Watcher CLI. Dünner Aufrufer — jede Aktion eine Methode im Kern."""

import argparse
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from tools.warteschlange.watcher_kern import (  # noqa: E402
    RESSOURCE_DAUERN,
    WARTESCHLANGE_STAMM,
    belege,
    formatiere_position,
    freigeben,
    position_fuer,
    status_ohne_ticket,
)


def hauptprogramm() -> int:
    p = argparse.ArgumentParser(description="Warteschlange Watcher")
    p.add_argument("--ressource", required=True, choices=sorted(RESSOURCE_DAUERN.keys()), help="Ressource sonden_fenster, godot_headless oder git_push")
    p.add_argument("--status", action="store_true", help="Nur Position und Wartezeit ausgeben ohne zu belegen")
    p.add_argument("--warte", action="store_true", help="Belegen und mit Heartbeat warten bis aktiv")
    p.add_argument("--freigeben", default="", help="Ticket-Pfad freigeben")
    args = p.parse_args()

    if args.freigeben:
        freigeben(Path(args.freigeben))
        print(f"WARTESCHLANGE {args.ressource} freigegeben {args.freigeben}")
        return 0

    if args.status:
        print(status_ohne_ticket(args.ressource))
        return 0

    pfad, pos = belege(args.ressource)
    print(formatiere_position(pos))
    print(f"TICKET {pfad}")

    if args.warte and not pos.ist_aktiv:
        while True:
            time.sleep(2)
            npos = position_fuer(args.ressource, pfad.name)
            if npos is None:
                print("WARTESCHLANGE Ticket verschwunden, beende")
                return 1
            print(formatiere_position(npos))
            if npos.ist_aktiv:
                break
    return 0


if __name__ == "__main__":
    sys.exit(hauptprogramm())
