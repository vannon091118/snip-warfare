# -*- coding: utf-8 -*-
"""Commit Reihe. Fassade über echte Teil-Domänen."""

import sys
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJEKT_STAMM))

from tools.warteschlange.watcher_kern import belege, freigeben  # noqa: E402
from .commit_gate import preflight_fuer_slice, shinon_gruen
from .git_dateien import geaenderte_dateien, lauf
from .slice_bauer import bilde_slices


def committe_slices(dry_run: bool = False) -> int:
    geaenderte = geaenderte_dateien()
    if not geaenderte:
        print("Commit Reihe: keine Änderungen")
        return 0
    slices = bilde_slices(geaenderte)
    print(f"Commit Reihe: {len(geaenderte)} in {len(slices)} Slices")
    for i, s in enumerate(slices, start=1):
        print(f"  Slice {i}: {', '.join(s[:6])}{' ...' if len(s) > 6 else ''} ({len(s)})")
    if dry_run:
        return 0
    if not shinon_gruen():
        print("Commit Reihe: Shinon rot — stoppe")
        return 1
    for idx, slice_dateien in enumerate(slices, start=1):
        print(f"Slice {idx}/{len(slices)}: pruefe ...")
        if not preflight_fuer_slice(slice_dateien):
            print(f"Slice {idx}: Preflight rot — stoppe")
            return 1
        ticket, pos = belege("git_push")
        try:
            if not pos.ist_aktiv:
                print(f"WARTESCHLANGE git_push Position {pos.position}/{pos.gesamt} ~{pos.warte_sekunden}s — warte")
                import time
                from tools.warteschlange.watcher_kern import position_fuer, formatiere_position
                while True:
                    time.sleep(2)
                    npos = position_fuer("git_push", ticket.name)
                    if npos is None:
                        print("Ticket verschwunden")
                        return 1
                    print(formatiere_position(npos))
                    if npos.ist_aktiv:
                        break
            code, out, err = lauf(["git", "add", "--"] + slice_dateien)
            if code != 0:
                print(f"git add fehlgeschlagen: {err or out}")
                return 1
            from shinon.shinon_commit_komponist import ShinonCommitKomponist
            ok, text = ShinonCommitKomponist().commit_ausfuehren()
            if not ok:
                print(f"Commit fehlgeschlagen: {text}")
                lauf(["git", "reset", "HEAD", "--"] + slice_dateien)
                return 1
            print(text)
            code, out, err = lauf(["git", "push"])
            if code != 0:
                print(f"git push fehlgeschlagen: {err or out}")
                return 1
            print(f"Slice {idx}: gepusht")
        finally:
            freigeben(ticket)
    return 0


if __name__ == "__main__":
    sys.exit(committe_slices(dry_run="--dry-run" in sys.argv))
