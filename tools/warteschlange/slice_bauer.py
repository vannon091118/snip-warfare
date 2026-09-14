# -*- coding: utf-8 -*-
"""Slice Bauer. Eigene Zuständigkeit: Dateien in 10-15er Slices schneiden."""

DOMAENEN_PRAEFIXE = ["core/", "game/", "world/", "ui/", "economy/", "population/", "military/", "tools/sonden/", "tools/preflight/", "tools/warteschlange/", "shinon/"]
MAX_SLICE = 15
MIN_SLICE = 10


def praefix_von(pfad: str) -> str:
    for pref in DOMAENEN_PRAEFIXE:
        if pfad.startswith(pref):
            return pref
    return pfad.split("/")[0] + "/" if "/" in pfad else pfad


def bilde_slices(dateien: list[str]) -> list[list[str]]:
    if not dateien:
        return []
    slices: list[list[str]] = []
    cur: list[str] = []
    cur_praefix: str | None = None
    for datei in dateien:
        pref = praefix_von(datei)
        if cur_praefix is None:
            cur_praefix = pref
        if (pref != cur_praefix and len(cur) >= MIN_SLICE) or len(cur) >= MAX_SLICE:
            slices.append(cur)
            cur = []
            cur_praefix = pref
        cur.append(datei)
    if cur:
        if slices and len(cur) < MIN_SLICE and len(slices[-1]) + len(cur) <= MAX_SLICE:
            slices[-1].extend(cur)
        else:
            slices.append(cur)
    return slices
