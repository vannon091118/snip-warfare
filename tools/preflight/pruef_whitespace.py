# -*- coding: utf-8 -*-
"""Prüfkategorie whitespace (E042): Einheitliche Leerzeichen-Disziplin.

Je Datei höchstens ein Befund, damit das Gate nicht flutet. Prüft roh auf
Byte-Ebene (BOM, CRLF) und textuell (trailing Leerzeichen/Tabs, fehlendes
finales Newline, Tabs in py/md/json). Fach-Ordner plus shinon und tools
gehören zum Vertrag, .godot/.freebuff/addons/godot-Cache werden ignoriert.
*.gd behält Tabs als Godot-Stil, nur py/md/json dürfen keine Tabs tragen.
"""

from pathlib import Path

try:
    from .kern import PROJEKT_STAMM, fehler
    _PROJEKT_STAMM = PROJEKT_STAMM
    _fehler = fehler
except ImportError:
    _PROJEKT_STAMM = None
    _fehler = None
    PROJEKT_STAMM = None
    fehler = None

GEPRUEFTE_PRAEFIXE = ("game/", "world/", "core/", "economy/", "population/", "military/", "ui/", "shinon/", "tools/")
IGNORIERTE_PRAEFIXE = (".godot/", ".freebuff/", "addons/", "tools/godot", ".git/", ".kilo/", ".pytest_cache/", "__pycache__/", "tools/logs/")
IGNORIERTE_ENDUNGEN = (".import", ".uid")
TABS_VERBOTEN_ENDUNGEN = (".py", ".md", ".json", ".yml", ".yaml", ".toml", ".cfg", ".ini")


def _ist_geprueft(relativ: str) -> bool:
    if relativ.startswith(tuple(p for p in IGNORIERTE_PRAEFIXE)):
        return False
    if relativ.endswith(IGNORIERTE_ENDUNGEN):
        return False
    # Fach-Ordner und Werkzeuge pruefen, alles andere ist Deko.
    return relativ.startswith(GEPRUEFTE_PRAEFIXE) or relativ in (".editorconfig", ".gitignore", ".gitattributes")


def _ursachen_fuer(pfad: Path, roh: bytes, text: str) -> list[str]:
    ursachen: list[str] = []
    if roh.startswith(b"\xef\xbb\xbf"):
        ursachen.append("BOM am Dateianfang")
    if b"\r\n" in roh or b"\r" in roh:
        ursachen.append("CRLF statt LF")
    zeilen = text.splitlines()
    # Trailing Leerzeichen/Tabs je Zeile (nur echte Laenge, nicht Leerzeilen).
    for nummer, zeile in enumerate(zeilen, start=1):
        if zeile != zeile.rstrip(" \t") and zeile.strip() != "":
            ursachen.append(f"trailing Leerzeichen in Zeile {nummer}")
            break
        if zeile.rstrip("\n\r") != zeile.rstrip(" \t\n\r") and zeile.strip() != "":
            # Fallback fuer Tabs am Ende ohne sichtbaren Space.
            if zeile.endswith(" ") or zeile.endswith("\t"):
                if f"trailing Leerzeichen in Zeile {nummer}" not in ursachen:
                    ursachen.append(f"trailing Leerzeichen in Zeile {nummer}")
                    break
    if text != "" and not text.endswith("\n"):
        ursachen.append("fehlendes finales Newline")
    if pfad.suffix.lower() in TABS_VERBOTEN_ENDUNGEN:
        if "\t" in text:
            ursachen.append("Tab in py/md/json (nur Spaces erlaubt)")
    return ursachen


def pruefe_whitespace(dateien=None) -> None:
    """E042: Whitespace-Disziplin je Datei, maximal ein Befund pro Datei."""
    _ = dateien
    stamm = _PROJEKT_STAMM if _PROJEKT_STAMM is not None else PROJEKT_STAMM
    melde = _fehler if _fehler is not None else fehler
    for pfad in sorted(stamm.rglob("*")):
        if pfad.is_dir():
            continue
        try:
            relativ = str(pfad.relative_to(stamm)).replace("\\", "/")
        except ValueError:
            continue
        if not _ist_geprueft(relativ):
            continue
        try:
            roh = pfad.read_bytes()
        except OSError:
            continue
        if b"\x00" in roh[:4096]:
            continue
        try:
            text = roh.decode("utf-8")
        except UnicodeDecodeError:
            continue
        if text == "":
            continue
        ursachen = _ursachen_fuer(pfad, roh, text)
        if ursachen:
            melde("E042", relativ, 1, "Whitespace-Maengel: %s" % ", ".join(ursachen))


def fix_dateien() -> int:
    """Repariert alle E042-Maengel idempotent. Gibt Anzahl reparierter Dateien zurueck."""
    stamm = _PROJEKT_STAMM if _PROJEKT_STAMM is not None else PROJEKT_STAMM
    repariert = 0
    for pfad in sorted(stamm.rglob("*")):
        if pfad.is_dir():
            continue
        try:
            relativ = str(pfad.relative_to(stamm)).replace("\\", "/")
        except ValueError:
            continue
        if not _ist_geprueft(relativ):
            continue
        try:
            roh = pfad.read_bytes()
        except OSError:
            continue
        if b"\x00" in roh[:4096]:
            continue
        try:
            text = roh.decode("utf-8")
        except UnicodeDecodeError:
            continue
        if text == "":
            continue
        original = roh
        # BOM entfernen.
        if roh.startswith(b"\xef\xbb\xbf"):
            roh = roh[3:]
            text = roh.decode("utf-8", errors="strict")
        # CRLF -> LF.
        if b"\r\n" in roh or b"\r" in roh:
            text = text.replace("\r\n", "\n").replace("\r", "\n")
        # Tabs -> 4 Spaces nur fuer py/md/json, nie fuer gd.
        if pfad.suffix.lower() in TABS_VERBOTEN_ENDUNGEN and "\t" in text:
            text = text.replace("\t", "    ")
        # Trailing Leerzeichen/Tabs je Zeile entfernen, Leerzeilen bleiben leer.
        zeilen = text.splitlines()
        bereinigt = [zeile.rstrip(" \t") for zeile in zeilen]
        text = "\n".join(bereinigt)
        if text != "" and not text.endswith("\n"):
            text += "\n"
        neu = text.encode("utf-8")
        if neu != original:
            pfad.write_bytes(neu)
            repariert += 1
    return repariert
