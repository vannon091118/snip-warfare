# -*- coding: utf-8 -*-
"""Root-Index: Der Block, den INDEX.md aus dem Code erhaelt.

Eine Zuständigkeit: Der Wurzel-Index nennt die Index-Familie und das
Klasseninventar. Alles ausserhalb der Marker bleibt Handpflege; nur der Block
zwischen MARKER_START und MARKER_ENDE kommt aus dem Code.
"""

from .kern import (ALLE_DOMAENEN, MARKER_ENDE, MARKER_START, PROJEKT_STAMM,
                   QUELLE, REST_DOMAENE, block_zwischen, lies_version,
                   schreibe_markdown)

INDEX_PFAD = "INDEX.md"

FAMILIE = (
    ("Wurzel", "INDEX.md", "Index-Familie und Klasseninventar"),
    ("Domaenen", "INDEX_DOMAENEN.md", "Klassen, Signal- und Array-Matrix je Domaene"),
    ("Daten", "INDEX_DATEN.md", "JSON-Pools mit Besitzer und Verbrauchern"),
    ("Letzte Aenderung", "INDEX_LETZTE_AENDERUNG.md", "Delta des letzten Index-Laufs"),
)


def block_text(inventar, signale, arrays, zahlen):
    """Der auto-generierte Block mit Index-Familie und Klasseninventar."""
    gesamt_domaenen = sum(len(eintraege) for eintraege in inventar.values())
    rest = len(inventar.get(REST_DOMAENE[0], []))
    zeilen = [MARKER_START, "",
              "## 4. Index-Familie (auto-generiert)", "",
              "_Quelle: %s — die vier Indizes werden aus dem Code erzeugt._" % QUELLE, "",
              "| Index | Datei | Inhalt |", "| --- | --- | --- |"]
    for name, datei, inhalt in FAMILIE:
        zeilen.append("| %s | [`%s`](%s) | %s |" % (name, datei, datei, inhalt))
    zeilen.append("")
    zeilen.append("_Stand: %s — %d Klassen mit `class_name` im Projekt, davon %d in den "
                  "%d Domaenen-Ordnern und %d ohne Domaenen-Ordner, %d Signale, "
                  "%d Array-Elementtypen und %d JSON-Pools._"
                  % (lies_version(), zahlen["klassen"], gesamt_domaenen - rest,
                     len(inventar) - 1, rest, zahlen["signale"], zahlen["array_typen"],
                     zahlen["pools"]))
    zeilen += ["", "## 5. Klasseninventar (auto-generiert)", "",
               "_Quelle: %s — scannt `class_name` je Domaene._" % QUELLE, ""]
    for schluessel, _kuerzel, praefix, ordner in ALLE_DOMAENEN:
        eintraege = inventar.get(schluessel, [])
        zeilen.append("### %s — Prefix `%s` — `%s` (%d)" % (schluessel, praefix, ordner,
                                                            len(eintraege)))
        zeilen.append("")
        if not eintraege:
            zeilen.append("_keine `class_name`-Klassen_")
        else:
            zeilen.append("| Klasse | Datei |")
            zeilen.append("| --- | --- |")
            for name, pfad, _zeilen in sorted(eintraege):
                zeilen.append("| `%s` | `%s` |" % (name, pfad))
        zeilen.append("")
    zeilen.append(MARKER_ENDE)
    return "\n".join(zeilen) + "\n"


def schreiben(inventar, signale, arrays, zahlen):
    """Ersetzt den Marker-Block in INDEX.md und laesst die Handpflege stehen."""
    pfad = PROJEKT_STAMM / INDEX_PFAD
    block = block_text(inventar, signale, arrays, zahlen)
    vorhanden = pfad.read_text(encoding="utf-8") if pfad.is_file() else ""
    alt = block_zwischen(vorhanden, MARKER_START, MARKER_ENDE)
    if alt is None:
        neu = vorhanden.rstrip() + "\n\n" + block
    else:
        neu = vorhanden.replace(alt, block.rstrip())
    geaendert = schreibe_markdown(pfad, neu)
    return geaendert, block


def erwarteter_block(inventar, signale, arrays, zahlen):
    """Der Soll-Block fuer den Waechter, ohne etwas zu schreiben."""
    return block_text(inventar, signale, arrays, zahlen)
