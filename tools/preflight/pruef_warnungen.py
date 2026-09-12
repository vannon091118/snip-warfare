# -*- coding: utf-8 -*-
"""Prüfkategorie warnungen (E025): statische Erkennung der Editor-Warnklassen
über den granularen Warnungs-Scan."""

import importlib.util
import sys

from .kern import PROJEKT_STAMM, fehler


def pruefe_warnungen(dateien):
    """Lädt den statischen Warnungs-Scan und meldet jede Editor-Warnklasse.

    Die GDScript-Warnungen (Integer-Division, Schatten, ungenutzte Parameter,
    ungenutzte Signale, statische Aufrufe) erscheinen nur im GUI-Editor-Reload,
    nicht im Headless-Lauf. Dieser Scan macht sie zur Pflichtprüfung.
    """
    try:
        _w_pfad = PROJEKT_STAMM / "tools" / "warnungs_scan.py"
        _w_spez = importlib.util.spec_from_file_location("_warnungs_scan_lauf", str(_w_pfad))
        _w_mod = importlib.util.module_from_spec(_w_spez)
        sys.modules[_w_spez.name] = _w_mod
        assert _w_spez.loader is not None
        _w_spez.loader.exec_module(_w_mod)
        scan = _w_mod.WarnungsScan(PROJEKT_STAMM)
        for befund in scan.scanne(dateien):
            fehler("E025", befund.datei, befund.zeile,
                   "%s | %s" % (befund.klasse, befund.meldung))
    except Exception as scan_fehler:
        # Fail-closed: Ein nicht ladbarer Warnungs-Scan ist selbst ein Befund.
        fehler("E025", "tools/warnungs_scan.py", 0,
               "Warnungs-Scan nicht ausführbar (fail-closed): %s" % scan_fehler)
