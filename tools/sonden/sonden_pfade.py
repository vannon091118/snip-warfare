# -*- coding: utf-8 -*-
"""Sonden Pfade. Eigene Zuständigkeit: Ablage, IDs, Lauf-Log.

Kein Läufer, kein Prüfer kennt Pfade direkt — nur diese Domäne.
"""

import hashlib
import subprocess
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent.parent
SONDEN_STAMM = PROJEKT_STAMM / ".sonden"
SNAP_ORDNER = SONDEN_STAMM / "snaps"
SIGNATUR_ORDNER = SONDEN_STAMM / "signaturen"
SZENARIEN_ORDNER = PROJEKT_STAMM / "tools" / "sonden" / "szenarien"


def agent_id() -> str:
    try:
        u = subprocess.run(["git", "config", "user.name"], capture_output=True, text=True, timeout=5)
        b = subprocess.run(["git", "rev-parse", "--abbrev-ref", "HEAD"], capture_output=True, text=True, timeout=5)
        name = (u.stdout or "agent").strip().replace(" ", "_") or "agent"
        branch = (b.stdout or "main").strip().replace("/", "_") or "main"
        roher = f"{name}@{branch}"
        return hashlib.sha1(roher.encode()).hexdigest()[:8] + f"_{name}"
    except Exception:
        return "unbekannt_agent"


def signatur_pfad(szenario_id: str, agent: str) -> Path:
    return SIGNATUR_ORDNER / agent / f"{szenario_id}.json"
