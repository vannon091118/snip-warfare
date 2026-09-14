# -*- coding: utf-8 -*-
"""Whitespace Fix. Eigene Zuständigkeit: Alle E042-Maengel reparieren."""

from pathlib import Path

from .whitespace_regeln import GEPRUEFTE_DOKUMENTE, GEPRUEFTE_PRAEFIXE, IGNORIERTE_ENDUNGEN, IGNORIERTE_PRAEFIXE, TABS_VERBOTEN_ENDUNGEN, ist_geprueft

try:
    from .kern import PROJEKT_STAMM as _STAMM
except ImportError:
    _STAMM = None


def fix_dateien() -> int:
    stamm = _STAMM
    if stamm is None:
        from .kern import PROJEKT_STAMM as _S2
        stamm = _S2
    repariert = 0
    for pfad in sorted(stamm.rglob("*")):
        if pfad.is_dir():
            continue
        try:
            relativ = str(pfad.relative_to(stamm)).replace("\\", "/")
        except ValueError:
            continue
        if not ist_geprueft(relativ):
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
        if roh.startswith(b"\xef\xbb\xbf"):
            roh = roh[3:]
            text = roh.decode("utf-8", errors="strict")
        if b"\r\n" in roh or b"\r" in roh:
            text = text.replace("\r\n", "\n").replace("\r", "\n")
        if pfad.suffix.lower() in TABS_VERBOTEN_ENDUNGEN and "\t" in text:
            text = text.replace("\t", "    ")
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
