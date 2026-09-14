# -*- coding: utf-8 -*-
"""Statik Laeufer. Eigene Zuständigkeit: Alle statik-Kategorien in Reihe."""

from .pruef_bau_kette import pruefe_bau_kette
from .pruef_daten import gib_dateninventar_aus
from .pruef_datenparitaet import pruefe_datenparitaet
from .pruef_determinismus import pruefe_determinismus
from .pruef_index import pruefe_index
from .pruef_klassen import pruefe_klassen
from .pruef_locregel import pruefe_locregel
from .pruef_pfade import pruefe_pfade
from .pruef_pyramide import pruefe_pyramide
from .pruef_registries import pruefe_registries
from .pruef_version import pruefe_version
from .pruef_warnungen import pruefe_warnungen
from .pruef_whitespace import pruefe_whitespace


def statik_laufen(gewaehlt: set[str], dateien) -> None:
    if "klassen" in gewaehlt:
        pruefe_klassen(dateien)
    if "trennung" in gewaehlt:
        pruefe_trennung_safe(gewaehlt, dateien)
    if "determinismus" in gewaehlt:
        pruefe_determinismus(dateien)
    if "pfade" in gewaehlt:
        pruefe_pfade(dateien)
    if "registries" in gewaehlt:
        pruefe_registries(dateien)
    if "warnungen" in gewaehlt or "godot" in gewaehlt:
        pruefe_warnungen(dateien)
    if "pyramide" in gewaehlt or "biome" in gewaehlt or "einheitlich" in gewaehlt:
        pruefe_pyramide(dateien)
    if "daten" in gewaehlt or "datenparitaet" in gewaehlt:
        pruefe_datenparitaet(dateien)
    if "bau_kette" in gewaehlt:
        pruefe_bau_kette(dateien)
    if "locregel" in gewaehlt:
        pruefe_locregel(dateien)
    if "whitespace" in gewaehlt:
        pruefe_whitespace(dateien)
    if "version" in gewaehlt:
        pruefe_version(dateien)
    if "index" in gewaehlt:
        pruefe_index(dateien)


def pruefe_trennung_safe(gewaehlt, dateien):
    from .pruef_trennung import pruefe_trennung
    pruefe_trennung(dateien)
