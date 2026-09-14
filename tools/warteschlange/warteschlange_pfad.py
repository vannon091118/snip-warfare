# -*- coding: utf-8 -*-
"""Warteschlange Pfad. Eigene Zuständigkeit: Der eine Stamm der Warteschlange."""

from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent.parent
WARTESCHLANGE_STAMM = PROJEKT_STAMM / ".warteschlange"
