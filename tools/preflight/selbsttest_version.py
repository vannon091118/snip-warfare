# -*- coding: utf-8 -*-
"""Selbsttest Version. Eigene Zuständigkeit: Der Versions-Anteil des E000."""


def pruefe(probleme: list[str]) -> None:
    try:
        from .pruef_version import badge_nachziehen, dokument_version, paarformen_aufloesen, statuszahlen_nachziehen, statuszahlen_verletzungen, version_erhoehen
        if version_erhoehen("V0.01") != "V0.02":
            probleme.append("Versionswaechter V0.01->V0.02 falsch")
        if version_erhoehen("V0.99") != "V1.00":
            probleme.append("Versionswaechter Uebertrag falsch")
        if dokument_version("Kopf\nVersion: V0.07\nRest\n") != "V0.07":
            probleme.append("Versionswaechter liest Versionszeile nicht")
        if dokument_version("ohne Zeile\n") is not None:
            probleme.append("Versionswaechter meldet fehlende Zeile faelschlich")
        probe_stand = "Fundament mit 227 Klassen, 11 Szenen, 251 GDScript-Dateien.\n"
        stand = {"klassen": 300, "dateien": 400, "szenen": 12, "tests": 97, "kategorien": 19}
        nachgezogen = statuszahlen_nachziehen(probe_stand, stand)
        if nachgezogen != "Fundament mit 300 Klassen, 12 Szenen, 400 GDScript-Dateien.\n":
            probleme.append(f"Statuszahl-Nachzug frisst Substantiv: {nachgezogen!r}")
        if not statuszahlen_verletzungen("Fundament mit 1 Klassen.\n", stand):
            probleme.append("Versionswaechter meldet falsche Statuszahl nicht")
        if statuszahlen_verletzungen("Fundament mit 300 Klassen.\n", stand):
            probleme.append("Versionswaechter meldet korrekte Zahl als Fehler")
        paar = paarformen_aufloesen("85/85 Pytest-Fälle grün.\n")
        if paar != "85 Pytest-Fälle grün.\n":
            probleme.append(f"Paarform falsch: {paar!r}")
        badge_probe = badge_nachziehen("pytest-85%2F85%20Passed\n", {"tests": 97})
        if badge_probe != "pytest-97%2F97%20Passed\n":
            probleme.append(f"Badge-Nachzug falsch: {badge_probe!r}")
        voll = {"klassen": 300, "dateien": 400, "szenen": 12, "tests": 97, "kategorien": 19}
        probe_neu = statuszahlen_nachziehen("alle 85 Unittests, 20 Prüfkategorien.\n", voll)
        if probe_neu != "alle 97 Unittests, 19 Prüfkategorien.\n":
            probleme.append(f"Statuszahl Tests/Kategorien falsch: {probe_neu!r}")
        if not statuszahlen_verletzungen("alle 85 Unittests.\n", voll):
            probleme.append("Versionswaechter meldet falsche Testanzahl nicht")
        if statuszahlen_verletzungen("alle 97 Unittests.\n", voll):
            probleme.append("Versionswaechter meldet korrekte Testanzahl als Fehler")
    except ImportError:
        probleme.append("Versionswaechter nicht importierbar")
