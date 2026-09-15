# -*- coding: utf-8 -*-
"""CLI Argumente. Eigene Zuständigkeit: Argparse für den Preflight."""

import argparse


def baue_parser(kategorien: set[str]) -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Preflight des Projekts")
    parser.add_argument("--kategorie", action="append", default=[], help="zusaetzliche Pruefkategorie (%s)" % ", ".join(sorted(kategorien)))
    parser.add_argument("--ohne-godot", action="store_true", help="Godot-Lauf überspringen")
    parser.add_argument("--godot-befehl", default="godot", help="Befehl oder Pfad der Godot-Engine")
    parser.add_argument("--fix", action="store_true", help="Whitespace-Maengel (E042) nur mit --kategorie whitespace")
    parser.add_argument("--hilfe-fehler", action="store_true", help="Zeigt Zuordnung Godot Zeile zu E016/E017/E018")
    parser.add_argument("--sonden-schnelldurchlauf", action="store_true", help="Sonden: alle Szenarien hintereinander (E029)")
    parser.add_argument("--sonden-scope", default="", help="Sonden: nur deckt Pfade Komma-getrennt")
    parser.add_argument("--sonden-snap", action="store_true", help="Sonden: Baseline fuer E028")
    parser.add_argument("--wiederholungen", type=int, default=1, help="Retry fuer lauf und beweis (1-3, nur diese Phasen, mit Backoff)")
    return parser


def normalisiere_kategorien(argumente) -> None:
    argumente.kategorie = [n.strip() for e in argumente.kategorie for n in e.split(",") if n.strip()]


VERPFLICHTLICH = {"visual"}


def mit_pflicht(argumente) -> set[str]:
    """Die Pflichtkategorien sind in jedem Lauf dabei. Nur ausdrueckliche
    Pflicht-freie Läufe (--ohne-godot) lassen visual entfallen, weil sie
    ohnehin kein Fenster fotografieren können."""
    gewaehlt = {k.lower() for k in argumente.kategorie}
    if not gewaehlt:
        return set()
    pflicht = {p for p in VERPFLICHTLICH if not getattr(argumente, "ohne_godot", False)}
    return gewaehlt | pflicht
