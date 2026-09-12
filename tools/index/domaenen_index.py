# -*- coding: utf-8 -*-
"""Domaenen-Index: INDEX_DOMAENEN.md mit Signal- und Array-Matrix.

Eine Zuständigkeit: Die Domaenen samt ihren Klassen, Signalen und Arrays
darstellen. Die Signal-Matrix traegt eine Spalte je Domaene und zeigt in jeder
Zelle, ob die Domaene das Signal deklariert (D), sendet (S) oder verbindet (V).
Die Array-Matrix zeigt dieselben Spalten und zaehlt die `Array[Typ]` je Domaene.
Beide Matrizen werden vollstaendig aus dem Code erzeugt.
"""

from .kern import (ALLE_DOMAENEN, PROJEKT_STAMM, QUELLE, REST_DOMAENE,
                   lies_version, schreibe_markdown)
from .matrix import (array_matrix_text, signal_matrix_kopf,
                     signal_matrix_zeilen, zusammenfassung)

DATEI = "INDEX_DOMAENEN.md"


def text(inventar, signale, offen, arrays, dateien):
    """Der vollstaendige Inhalt des Domaenen-Index."""
    zahlen = zusammenfassung(signale, arrays)
    rest = len(inventar.get(REST_DOMAENE[0], []))
    zeilen = ["# INDEX_DOMAENEN.md — Domaenen-Index SnipWarfare", "",
              "_Quelle: %s — erzeugt aus dem Code, nie von Hand gepflegt._" % QUELLE, "",
              "Stand: %s — %d Domaenen plus Auffangkorb, %d Klassen, %d Dateien, "
              "%d Signale, %d Array-Elementtypen; %d Klassen liegen ausserhalb der "
              "Domaenen-Ordner." % (lies_version(), len(ALLE_DOMAENEN) - 1,
                                    sum(len(v) for v in inventar.values()),
                                    sum(dateien.values()), zahlen["signale"],
                                    zahlen["array_typen"], rest), "",
              "## 1. Domaenen-Uebersicht", "",
              "| Domaene | Kuerzel | Prefix | Ordner | Klassen | Dateien |",
              "| --- | --- | --- | --- | --- | --- |"]
    for schluessel, kuerzel, praefix, ordner in ALLE_DOMAENEN:
        zeilen.append("| `%s` | `%s` | `%s` | `%s` | %d | %d |"
                      % (schluessel, kuerzel, praefix, ordner,
                         len(inventar.get(schluessel, [])), dateien.get(schluessel, 0)))
    zeilen += ["", "## 2. Signal-Matrix (D Deklaration, S Senden, V Verbinden)", ""]
    zeilen += signal_matrix_kopf()
    zeilen += signal_matrix_zeilen(signale)
    zeilen += ["", "_Zusaetzlich gesendete oder verbundene Namen ohne eigene Deklaration "
               "im Projekt: %d._" % len(offen)]
    if offen:
        for name in sorted(offen):
            zeilen.append("* `%s` wird in %s gerufen, aber im Projekt nicht deklariert."
                          % (name, ", ".join(sorted(offen[name]))))
    zeilen += ["", "## 3. Array-Matrix (`Array[Typ]` je Domaene)", ""]
    zeilen += array_matrix_text(arrays)
    zeilen += ["", "## 4. Domaenen im Einzelnen", ""]
    zeilen += _domaenen_abschnitte(inventar, signale, arrays)
    zeilen += ["---", "", "Version: %s" % lies_version(), ""]
    return "\n".join(zeilen) + "\n"


def _domaenen_abschnitte(inventar, signale, arrays):
    """Je Domaene eine Sektion mit Klassen, Signalen und Arrays."""
    zeilen = []
    for schluessel, kuerzel, praefix, ordner in ALLE_DOMAENEN:
        eintraege = inventar.get(schluessel, [])
        zeilen += ["### %s — Kuerzel `%s` — `%s`" % (schluessel, kuerzel, ordner), "",
                   "Prefix `%s`, %d Klassen." % (praefix, len(eintraege)), ""]
        if eintraege:
            zeilen += ["| Klasse | Datei | Zeilen |", "| --- | --- | --- |"]
            for name, pfad, laenge in sorted(eintraege):
                zeilen.append("| `%s` | `%s` | %d |" % (name, pfad, laenge))
            zeilen.append("")
        eigene = _eigene_signale(signale, kuerzel)
        zeilen += ["#### Signale (Rolle in dieser Domaene)", ""]
        if eigene:
            zeilen += ["| Signal | Rolle | mitwirkende Domaenen |", "| --- | --- | --- |"]
            for name, rolle, partner in eigene:
                zeilen.append("| `%s` | %s | %s |" % (name, rolle, partner))
        else:
            zeilen.append("_keine Signal-Deklaration in dieser Domaene_")
        zeilen += ["", "#### Arrays (`Array[Typ]`)", ""]
        eigene_arrays = _eigene_arrays(arrays, kuerzel)
        if eigene_arrays:
            zeilen += ["| Array-Elementtyp | Vorkommen |", "| --- | --- |"]
            for typ, anzahl in eigene_arrays:
                zeilen.append("| `%s` | %d |" % (typ, anzahl))
        else:
            zeilen.append("_keine typisierten Arrays in dieser Domaene_")
        zeilen.append("")
    return zeilen


def _eigene_signale(signale, kuerzel):
    """Alle Signale, an denen eine Domaene beteiligt ist, mit Rolle und Partnern."""
    eigene = []
    for name, eintrag in sorted(signale.items(),
                                key=lambda eintrag: (eintrag[1]["klasse"], eintrag[0])):
        rollen = eintrag["rollen"].get(kuerzel)
        if not rollen:
            continue
        rolle = "".join(buchstabe for buchstabe in ("D", "S", "V") if buchstabe in rollen)
        partner = ", ".join(sorted(eintrag["rollen"]))
        eigene.append((name, rolle, partner))
    return eigene


def _eigene_arrays(arrays, kuerzel):
    """Array-Typen, die eine Domaene traegt, mit ihrem Vorkommen."""
    eigene = []
    for typ, traeger in arrays.items():
        if kuerzel in traeger:
            eigene.append((typ, len(traeger[kuerzel])))
    return sorted(eigene, key=lambda eintrag: (-eintrag[1], eintrag[0]))


def schreiben(inventar, signale, offen, arrays, dateien):
    """Schreibt INDEX_DOMAENEN.md und meldet, ob sich etwas aenderte."""
    pfad = PROJEKT_STAMM / DATEI
    return schreibe_markdown(pfad, text(inventar, signale, offen, arrays, dateien))


def erwarteter_text(inventar, signale, offen, arrays, dateien):
    """Der Soll-Inhalt fuer den Waechter, ohne zu schreiben."""
    return text(inventar, signale, offen, arrays, dateien)
