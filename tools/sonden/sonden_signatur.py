# -*- coding: utf-8 -*-
"""Sonden Signatur. Eigene Zuständigkeit: Letzte Signatur lesen und schreiben."""

import json
from pathlib import Path

from tools.sonden.sonden_pfade import signatur_pfad


def letzte_signatur_lesen(szenario_id: str, agent: str):
    p = signatur_pfad(szenario_id, agent)
    if not p.is_file():
        return None
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return None


def signatur_schreiben(szenario_id: str, agent: str, payload: dict) -> None:
    p = signatur_pfad(szenario_id, agent)
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp = p.with_suffix(".tmp")
    tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")
    tmp.replace(p)
