# -*- coding: utf-8 -*-
"""Whitespace Regeln. Eigene Zuständigkeit: Was geprüft wird."""

from pathlib import Path

GEPRUEFTE_PRAEFIXE = ("game/", "world/", "core/", "economy/", "population/", "military/", "ui/", "shinon/", "tools/")
GEPRUEFTE_DOKUMENTE = ("VERSION", "README.md", "ROADMAP.md", "INDEX.md", "Architektur.md", "AGENTS.md")
IGNORIERTE_PRAEFIXE = (".godot/", ".freebuff/", "addons/", "tools/godot", ".git/", ".kilo/", ".pytest_cache/", "__pycache__/", "tools/logs/")
IGNORIERTE_ENDUNGEN = (".import", ".uid")
TABS_VERBOTEN_ENDUNGEN = (".py", ".md", ".json", ".yml", ".yaml", ".toml", ".cfg", ".ini")


def ist_geprueft(relativ: str) -> bool:
    if relativ.startswith(tuple(p for p in IGNORIERTE_PRAEFIXE)):
        return False
    if relativ.endswith(IGNORIERTE_ENDUNGEN):
        return False
    return (relativ.startswith(GEPRUEFTE_PRAEFIXE)
            or relativ in GEPRUEFTE_DOKUMENTE
            or relativ in (".editorconfig", ".gitignore", ".gitattributes"))


def ursachen_fuer(pfad: Path, roh: bytes, text: str) -> tuple[list[str], int]:
    ursachen: list[str] = []
    erste_zeile = 1
    zeilen = text.splitlines()
    for nummer, zeile in enumerate(zeilen, start=1):
        if zeile != zeile.rstrip(" \t") and zeile.strip() != "":
            ursachen.append(f"trailing Leerzeichen in Zeile {nummer}")
            erste_zeile = nummer
            break
        if zeile.rstrip("\n\r") != zeile.rstrip(" \t\n\r") and zeile.strip() != "":
            if zeile.endswith(" ") or zeile.endswith("\t"):
                if f"trailing Leerzeichen in Zeile {nummer}" not in ursachen:
                    ursachen.append(f"trailing Leerzeichen in Zeile {nummer}")
                    erste_zeile = nummer
                    break
    if pfad.suffix.lower() in TABS_VERBOTEN_ENDUNGEN and "\t" in text:
        for nummer, zeile in enumerate(zeilen, start=1):
            if "\t" in zeile:
                ursachen.append("Tab in py/md/json (nur Spaces erlaubt)")
                if len(ursachen) == 1:
                    erste_zeile = nummer
                break
        else:
            if "Tab in py/md/json (nur Spaces erlaubt)" not in " ".join(ursachen):
                ursachen.append("Tab in py/md/json (nur Spaces erlaubt)")
    if roh.startswith(b"\xef\xbb\xbf"):
        ursachen.append("BOM am Dateianfang")
        if len(ursachen) == 1:
            erste_zeile = 1
    if b"\r\n" in roh or b"\r" in roh:
        ursachen.append("CRLF statt LF")
        if len(ursachen) == 1:
            erste_zeile = roh[: roh.find(b"\r")].count(b"\n") + 1 if b"\r" in roh else 1
    if text != "" and not text.endswith("\n"):
        ursachen.append("fehlendes finales Newline")
        if len(ursachen) == 1:
            erste_zeile = len(zeilen) if zeilen else 1
    return ursachen, erste_zeile
