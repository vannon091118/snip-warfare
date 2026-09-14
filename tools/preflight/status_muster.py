# -*- coding: utf-8 -*-
"""Status Muster. Eigene Zuständigkeit: Die Erkennungsmuster für Doku-Zahlen."""

import re

STATUSMUSTER = (
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> Klassen\b)"), "klassen"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> GDScript-Dateien\b)"), "dateien"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> Szenen\b)"), "szenen"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest>(?=\s+aktive\b))"), "szenen"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> bestandenen Pytest-Prüfungen\b)"), "tests"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> Pytest-Fälle\b)"), "tests"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> Unittests\b)"), "tests"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> bestandenen Pytest-Pruefungen\b)"), "tests"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> Prüfkategorien\b)"), "kategorien"),
    (re.compile(r"(?P<zahl>\b\d+)(?P<rest> Pruefkategorien\b)"), "kategorien"),
)

PAARFORM_MUSTER = re.compile(r"\b(\d+)\s*/\s*(\d+)\s*(Pytest-Fälle)\b")
BADGE_MUSTER = re.compile(r"(?P<vorn>pytest-)(?P<zahl>\d+)(?P<mitte>%2F)(?P<zwei>\d+)(?P<hinten>%20Passed)")
