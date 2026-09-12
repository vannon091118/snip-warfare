# -*- coding: utf-8 -*-
"""Daten-Index: INDEX_DATEN.md mit jedem JSON-Pool, Besitzer und Verbrauchern.

Eine Zuständigkeit: Die Datenpools des Projekts darstellen. Jeder Pool nennt
seinen Pfad, seine Domaene, seine obersten Schluessel, die Zahl seiner Eintraege
und die Klassen, die ihn namentlich lesen. Ein Pool ohne Verbraucher faellt
damit sofort auf, weil die Tabelle ihn als verwaist kennzeichnet.
"""

from .daten import zusammenfassung
from .kern import PROJEKT_STAMM, QUELLE, lies_version, schreibe_markdown

DATEI = "INDEX_DATEN.md"


def text(pools):
    """Der vollstaendige Inhalt des Daten-Index."""
    zahlen = zusammenfassung(pools)
    zeilen = ["# INDEX_DATEN.md — Daten-Index SnipWarfare", "",
              "_Quelle: %s — erzeugt aus dem Code, nie von Hand gepflegt._" % QUELLE, "",
              "Stand: %s — %d JSON-Pools, davon %d lesbar und %d ohne namentlichen "
              "Verbraucher." % (lies_version(), zahlen["pools"], zahlen["lesbar"],
                                zahlen["verwaist"]), "",
              "## 1. Pools in Besitz einer Domaene", "",
              "| Pool | Domaene | Eintraege | Oberste Schluessel | Verbraucher |",
              "| --- | --- | --- | --- | --- |"]
    for pool in pools:
        schluessel = ", ".join("`%s`" % name for name in pool["schluessel"][:6])
        if len(pool["schluessel"]) > 6:
            schluessel += " und %d weitere" % (len(pool["schluessel"]) - 6)
        verbraucher = ", ".join("`%s`" % name for name in pool["verbraucher"][:3])
        if len(pool["verbraucher"]) > 3:
            verbraucher += " und %d weitere" % (len(pool["verbraucher"]) - 3)
        zeilen.append("| [`%s`](%s) | `%s` | %d | %s | %s |"
                      % (pool["name"], pool["pfad"], pool["domaene"],
                         pool["eintraege"], schluessel or "-", verbraucher or "keiner"))
    zeilen += ["", "## 2. Pools ohne namentlichen Verbraucher", "",
               "Ein Pool ohne Verbraucher ist ein Vertrag ohne Gegenstand: Entweder "
               "fehlt die verdrahtete Klasse, oder der Pool darf gehen.", ""]
    verwaist = [pool for pool in pools if not pool["verbraucher"]]
    if verwaist:
        zeilen += ["| Pool | Domaene | Eintraege |", "| --- | --- | --- |"]
        for pool in verwaist:
            zeilen.append("| [`%s`](%s) | `%s` | %d |"
                          % (pool["name"], pool["pfad"], pool["domaene"],
                             pool["eintraege"]))
    else:
        zeilen.append("_keiner — jeder Pool hat mindestens einen namentlichen Leser._")
    zeilen += ["", "## 3. Verbraucher im Einzelnen", ""]
    for pool in pools:
        if not pool["verbraucher"]:
            continue
        zeilen.append("### %s" % pool["name"])
        zeilen.append("")
        zeilen.append("Pfad `%s`, Domaene `%s`, %d Eintraege."
                      % (pool["pfad"], pool["domaene"], pool["eintraege"]))
        zeilen.append("")
        for name in pool["verbraucher"]:
            zeilen.append("* `%s`" % name)
        zeilen.append("")
    zeilen += ["---", "", "Version: %s" % lies_version(), ""]
    return "\n".join(zeilen) + "\n"


def schreiben(pools):
    """Schreibt INDEX_DATEN.md und meldet, ob sich etwas aenderte."""
    pfad = PROJEKT_STAMM / DATEI
    return schreibe_markdown(pfad, text(pools))


def erwarteter_text(pools):
    """Der Soll-Inhalt fuer den Waechter, ohne zu schreiben."""
    return text(pools)
