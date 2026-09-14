# -*- coding: utf-8 -*-
"""Lauf Beweis. Eigene Zuständigkeit: Godot und Sonden mit mechanischem Retry."""

from .kern import FEHLER
from .wiederholung import mit_wiederholung


def lauf_beweis_mit_retry(argumente, gewaehlt, phasen) -> None:
    godot_aktiv = "godot" in gewaehlt and not argumente.ohne_godot
    sonden_aktiv = "sonden" in gewaehlt and not argumente.sonden_snap
    wieder = max(1, min(int(getattr(argumente, "wiederholungen", 1)), 3))
    if godot_aktiv and "lauf" in phasen:
        _godot_mit_retry(wieder)
    if sonden_aktiv and "beweis" in phasen:
        _sonden_mit_retry(argumente, wieder)


def _godot_mit_retry(wieder: int) -> None:
    def godot_ok() -> bool:
        von = len([e for e in FEHLER if e[0] in {"E016", "E017", "E018", "E025"}])
        from .pruef_godot import godot_lauf
        godot_lauf("godot")
        nach = len([e for e in FEHLER if e[0] in {"E016", "E017", "E018", "E025"}])
        return nach == von
    if wieder > 1:
        print(f"Phase lauf: godot_headless mit Retry {wieder}x")
        mit_wiederholung("lauf", godot_ok, wieder, lambda m: print(m))
    else:
        print("Phase lauf: godot_headless via Warteschlange")
        from .pruef_godot import godot_lauf
        godot_lauf("godot")


def _sonden_mit_retry(argumente, wieder: int) -> None:
    def sonden_ok() -> bool:
        von = len([e for e in FEHLER if e[0] in {"E026", "E027", "E028", "E029"}])
        from .pruef_sonden import pruefe_sonden
        scope = [p.strip() for p in argumente.sonden_scope.split(",") if p.strip()] if argumente.sonden_scope else None
        pruefe_sonden(argumente.godot_befehl, schnelldurchlauf=bool(argumente.sonden_schnelldurchlauf), scope_dateien=scope)
        nach = len([e for e in FEHLER if e[0] in {"E026", "E027", "E028", "E029"}])
        return nach == von
    if wieder > 1:
        print(f"Phase beweis: sonden mit Retry {wieder}x")
        mit_wiederholung("beweis", sonden_ok, wieder, lambda m: print(m))
    else:
        print("Phase beweis: sonden via Warteschlange")
        from .pruef_sonden import pruefe_sonden
        scope = [p.strip() for p in argumente.sonden_scope.split(",") if p.strip()] if argumente.sonden_scope else None
        pruefe_sonden(argumente.godot_befehl, schnelldurchlauf=bool(argumente.sonden_schnelldurchlauf), scope_dateien=scope)
