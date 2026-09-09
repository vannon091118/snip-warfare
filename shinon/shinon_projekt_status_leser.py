# -*- coding: utf-8 -*-
"""Shinon Projekt Status Leser. Eigene Zuständigkeit: Lebendige Fakten des Projekts lesen."""

import json
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent


class ShinonProjektStatusLeser:
    """Liest den echten Zustand des Projekts direkt aus den Quellen. Keine Ratespiele."""

    def lese(self) -> dict:
        return {
            "engine": self._engine(),
            "weltuhr": "24 ticks pro sekunde ueber Kern_Weltuhr als einzigem globalen tick",
            "steuerung": self._steuerung(),
            "registries": self._registries(),
            "spielbare_inhalte": self._spielbare_inhalte(),
            "preflight": "python tools/preflight.py mit shinon gate E030 bis E036",
            "szenen": self._szenen(),
        }

    def _engine(self) -> str:
        pfad = PROJEKT_STAMM / "project.godot"
        try:
            inhalt = pfad.read_text(encoding="utf-8")
            for zeile in inhalt.splitlines():
                if "config/features" in zeile:
                    return zeile.strip()
        except Exception:
            pass
        return "Godot 4.7 Kompatibilitaet"

    def _steuerung(self) -> dict:
        pfad = PROJEKT_STAMM / "game" / "data" / "steuerung.json"
        if not pfad.is_file():
            return {"quelle": "game/data/steuerung.json fehlt noch", "hinweis": "wird beim init erzeugt"}
        try:
            daten = json.loads(pfad.read_text(encoding="utf-8"))
            return daten if isinstance(daten, dict) else {"fehler": "steuerung.json hat falsches format"}
        except Exception as fehler:
            return {"fehler": str(fehler)}

    def _registries(self) -> list[str]:
        gefunden = []
        for pfad in (PROJEKT_STAMM / "world").rglob("*registry*.gd"):
            gefunden.append(str(pfad.relative_to(PROJEKT_STAMM)))
        for pfad in (PROJEKT_STAMM / "core").rglob("*registry*.gd"):
            gefunden.append(str(pfad.relative_to(PROJEKT_STAMM)))
        for pfad in (PROJEKT_STAMM / "game").rglob("*registry*.gd"):
            gefunden.append(str(pfad.relative_to(PROJEKT_STAMM)))
        return sorted(set(gefunden))

    def _spielbare_inhalte(self) -> dict:
        katalog = {"elemente": 0, "tiere": 0}
        katalog_pfad = PROJEKT_STAMM / "world" / "data" / "element_katalog.json"
        tier_pfad = PROJEKT_STAMM / "world" / "data" / "tier_verhalten.json"
        try:
            if katalog_pfad.is_file():
                daten = json.loads(katalog_pfad.read_text(encoding="utf-8"))
                if isinstance(daten, list):
                    katalog["elemente"] = len(daten)
        except Exception:
            pass
        try:
            if tier_pfad.is_file():
                daten = json.loads(tier_pfad.read_text(encoding="utf-8"))
                if isinstance(daten, dict):
                    katalog["tiere"] = len(daten)
        except Exception:
            pass
        return katalog

    def _szenen(self) -> dict:
        welt = PROJEKT_STAMM / "world" / "scenes" / "welt.tscn"
        editor = PROJEKT_STAMM / "world" / "scenes" / "karten_editor.tscn"
        return {
            "welt": welt.is_file(),
            "karten_editor": editor.is_file(),
        }
