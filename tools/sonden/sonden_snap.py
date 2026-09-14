# -*- coding: utf-8 -*-
"""Sonden Snap. Eigene Zuständigkeit: Baseline pro Szenario speichern."""

import json
from datetime import datetime
from pathlib import Path

from tools.sonden.sonden_pfade import SNAP_ORDNER, SONDEN_STAMM, SZENARIEN_ORDNER, agent_id, SIGNATUR_ORDNER
from tools.sonden.sonden_signatur import letzte_signatur_lesen


def sonden_snap() -> None:
    agent = agent_id()
    SONDEN_STAMM.mkdir(parents=True, exist_ok=True)
    SNAP_ORDNER.mkdir(parents=True, exist_ok=True)
    SIGNATUR_ORDNER.mkdir(parents=True, exist_ok=True)
    if not SZENARIEN_ORDNER.is_dir():
        return
    now = datetime.now().isoformat(timespec="seconds")
    for pfad in sorted(SZENARIEN_ORDNER.glob("*.json")):
        try:
            data = json.loads(pfad.read_text(encoding="utf-8"))
            sid = str(data.get("id", pfad.stem))
        except Exception:
            continue
        sign = letzte_signatur_lesen(sid, agent)
        payload = {"szenario_id": sid, "agent": agent, "zeit": now, "quelle": "snap", "signatur": sign}
        snap_pfad = SNAP_ORDNER / agent / f"{sid}.json"
        snap_pfad.parent.mkdir(parents=True, exist_ok=True)
        snap_pfad.write_text(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")
