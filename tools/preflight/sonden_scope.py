# -*- coding: utf-8 -*-
"""Sonden Scope. Eigene Zuständigkeit: Scope-Filter für Szenarien."""

import json
from pathlib import Path


def normiere_pfad(pfad: str) -> set[str]:
    s = pfad.strip()
    return {s, s[len("res://"):] if s.startswith("res://") else "res://" + s}


def filtere_nach_scope(szenarien: list[Path], scope_dateien: list[str] | None) -> list[Path]:
    scope_set = set(s.strip() for s in (scope_dateien or []) if s.strip())
    if not scope_set:
        return szenarien
    norm_scope: set[str] = set()
    for sc in scope_set:
        norm_scope.update(normiere_pfad(sc))
    gefiltert: list[Path] = []
    for pfad in szenarien:
        try:
            data = json.loads(pfad.read_text(encoding="utf-8"))
        except Exception:
            gefiltert.append(pfad)
            continue
        deckt_norm: set[str] = set()
        for e in data.get("deckt", []):
            deckt_norm.update(normiere_pfad(str(e)))
        if deckt_norm.isdisjoint(norm_scope):
            continue
        gefiltert.append(pfad)
    return gefiltert
