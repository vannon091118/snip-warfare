# -*- coding: utf-8 -*-
"""Lauf Log Brücke. Eigene Zuständigkeit: Ein einziger Importweg zum Log."""

import importlib.util
import sys

from .projekt_stamm import PROJEKT_STAMM


def lade_lauf_log():
    pfad = PROJEKT_STAMM / "tools" / "lauf_log.py"
    spez = importlib.util.spec_from_file_location("_lauf_log_bruecke", str(pfad))
    modul = importlib.util.module_from_spec(spez)
    sys.modules[spez.name] = modul
    assert spez.loader is not None
    spez.loader.exec_module(modul)
    return modul.LaufLog()
