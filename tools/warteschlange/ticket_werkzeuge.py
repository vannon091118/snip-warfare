# -*- coding: utf-8 -*-
"""Ticket Werkzeuge. Eigene Zuständigkeit: Agent, Pfade, Leben, Epoch."""

import hashlib
import json
import os
import subprocess
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent.parent
WARTESCHLANGE_STAMM = PROJEKT_STAMM / ".warteschlange"

RESSOURCE_DAUERN = {
    "sonden_fenster": 90,
    "godot_headless": 120,
    "git_push": 15,
}
STALE_SEKUNDEN = 600


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


def ressource_ordner(ressource: str) -> Path:
    p = WARTESCHLANGE_STAMM / ressource
    p.mkdir(parents=True, exist_ok=True)
    return p


def ticket_pid(ticket: Path) -> int | None:
    stamm = ticket.stem
    try:
        a = stamm.split("_", 2)
        if len(a) >= 2:
            return int(a[1])
        return None
    except Exception:
        return None


def ticket_epoch(ticket: Path) -> float:
    try:
        teile = ticket.stem.split("_", 1)
        roher = float(teile[0])
        if roher > 1e12:
            return roher / 1000.0
        return roher
    except Exception:
        pass
    try:
        data = json.loads(ticket.read_text(encoding="utf-8"))
        ep = float(data.get("epoch", 0))
        if ep > 0:
            return ep
    except Exception:
        pass
    try:
        return ticket.stat().st_mtime
    except Exception:
        return 0.0


def pid_lebt(pid: int) -> bool:
    # Windows: os.kill(pid, 0) wirft WinError 87 fuer tote PID, nicht EPERM.
    # EINVAL (22) = PID existiert nicht, EPERM = PID lebt aber kein Recht.
    import errno
    try:
        os.kill(pid, 0)
        return True
    except OSError as e:
        if getattr(e, "winerror", None) == 87 or e.errno == errno.EINVAL:
            return False
        if e.errno == errno.EPERM:
            return True
        return False
