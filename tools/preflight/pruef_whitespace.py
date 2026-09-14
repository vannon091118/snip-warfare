# -*- coding: utf-8 -*-
"""Prüfkategorie whitespace (E042): Fassade über echte Teil-Domänen."""

try:
    from .kern import PROJEKT_STAMM as _STAMM, fehler as _fehler
except ImportError:
    _STAMM = None
    _fehler = None
    PROJEKT_STAMM = None
    fehler = None

from .whitespace_regeln import ist_geprueft as _ist_geprueft, ursachen_fuer as _ursachen_fuer
from .whitespace_fix import fix_dateien


def pruefe_whitespace(dateien=None) -> None:
    _ = dateien
    stamm = _STAMM if _STAMM is not None else PROJEKT_STAMM
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
        ursachen, fund_zeile = _ursachen_fuer(pfad, roh, text)
        if ursachen:
            melde("E042", relativ, fund_zeile, "Whitespace-Maengel: %s" % ", ".join(ursachen))
