# -*- coding: utf-8 -*-
"""Die eine Last-Datei: INDEX_LETZTE_AENDERUNG.md traegt den Delta der letzten Aenderung.

Eine Zuständigkeit: Dieses Modul vergleicht den neuen Index-Stand mit dem Stand,
den die letzte Datei selbst festgehalten hat, und schreibt genau das Delta des
letzten Laufs nieder. Es gibt genau eine solche Datei, nie eine je Domaene. Sie
ist zugleich Gedaechtnis und Bericht: Der maschinelle Stand im unteren Block
dient dem naechsten Vergleich, der Bericht darueber nennt die letzte Aenderung.
"""

from .kern import PROJEKT_STAMM, QUELLE, lies_version, schreibe_markdown

DATEI = "INDEX_LETZTE_AENDERUNG.md"
STAND_START = "<!-- STAND:START -->"
STAND_ENDE = "<!-- STAND:ENDE -->"

KENNZAHLEN = ("klassen", "dateien", "signale", "array_typen", "pools")


def stand_lesen(text):
    """Liest den maschinellen Stand eines vorhandenen Last-Berichts."""
    if STAND_START not in text or STAND_ENDE not in text:
        return {"kennzahlen": {}, "domaenen": {}}
    block = text[text.index(STAND_START):text.index(STAND_ENDE)]
    kennzahlen = {}
    domaenen = {}
    for zeile in block.splitlines():
        felder = [feld.strip().strip("`") for feld in zeile.strip().strip("|").split("|")]
        if len(felder) == 2 and felder[0] in KENNZAHLEN:
            kennzahlen[felder[0]] = _zahl(felder[1])
        elif len(felder) == 4 and felder[0] not in ("Domaene", "---"):
            domaenen[felder[0]] = {"klassen": _zahl(felder[1]),
                                   "dateien": _zahl(felder[2]),
                                   "fingerabdruck": felder[3]}
    return {"kennzahlen": kennzahlen, "domaenen": domaenen}


def _zahl(text):
    """Liest eine Zahl aus einer Tabellenzelle; ohne Zahl None."""
    ziffern = "".join(zeichen for zeichen in text if zeichen.isdigit())
    return int(ziffern) if ziffern else None


def delta_berechnen(alt, neu_kennzahlen, neu_domaenen):
    """Nennt die letzte Aenderung als nummerierte Saetze."""
    saetze = []
    for name in KENNZAHLEN:
        vorher = alt["kennzahlen"].get(name)
        nachher = neu_kennzahlen.get(name)
        if vorher is None or nachher is None or vorher == nachher:
            continue
        saetze.append("%s: %d -> %d." % (name.replace("_", " ").capitalize(),
                                         vorher, nachher))
    for schluessel in sorted(neu_domaenen):
        vorher = alt["domaenen"].get(schluessel)
        nachher = neu_domaenen[schluessel]
        if vorher is None:
            saetze.append("Domaene %s ist neu im Index mit %d Klassen."
                          % (schluessel, nachher["klassen"]))
            continue
        if vorher["klassen"] != nachher["klassen"]:
            saetze.append("Domaene %s: %d -> %d Klassen."
                          % (schluessel, vorher["klassen"], nachher["klassen"]))
        if vorher["dateien"] != nachher["dateien"]:
            saetze.append("Domaene %s: %d -> %d GDScript-Dateien."
                          % (schluessel, vorher["dateien"], nachher["dateien"]))
        if (vorher["klassen"] == nachher["klassen"]
                and vorher["dateien"] == nachher["dateien"]
                and vorher["fingerabdruck"] != nachher["fingerabdruck"]):
            saetze.append("Domaene %s: gleiche Anzahl, andere Klassen (Fingerabdruck %s -> %s)."
                          % (schluessel, vorher["fingerabdruck"],
                             nachher["fingerabdruck"]))
    if not saetze:
        saetze.append("Keine Aenderung seit dem letzten Lauf.")
    return saetze


def text(delta, kennzahlen, domaenen):
    """Der vollstaendige Inhalt der einen Last-Datei."""
    zeilen = ["# INDEX_LETZTE_AENDERUNG.md — Delta des letzten Index-Laufs", "",
              "_Quelle: %s — es gibt genau eine Datei dieser Art._" % QUELLE, "",
              "Stand: %s — der untere Block ist das Gedaechtnis des naechsten "
              "Vergleichs, der obere Block die letzte Aenderung." % lies_version(), "",
              "## 1. Letzte Aenderung", ""]
    for nummer, satz in enumerate(delta, start=1):
        zeilen.append("%d. %s" % (nummer, satz))
    zeilen += ["", "## 2. Stand (maschinell, Grundlage des naechsten Vergleichs)", "",
               STAND_START, "", "| Kennzahl | Wert |", "| --- | --- |"]
    for name in KENNZAHLEN:
        zeilen.append("| %s | %d |" % (name, kennzahlen.get(name, 0)))
    zeilen += ["", "| Domaene | Klassen | Dateien | Fingerabdruck |", "| --- | --- | --- | --- |"]
    for schluessel in sorted(domaenen):
        eintrag = domaenen[schluessel]
        zeilen.append("| %s | %d | %d | %s |"
                      % (schluessel, eintrag["klassen"], eintrag["dateien"],
                         eintrag["fingerabdruck"]))
    zeilen += ["", STAND_ENDE, "", "---", "", "Version: %s" % lies_version(), ""]
    return "\n".join(zeilen) + "\n"


def schreiben(kennzahlen, domaenen):
    """Vergleicht mit dem alten Stand und schreibt die eine Last-Datei."""
    pfad = PROJEKT_STAMM / DATEI
    alt = stand_lesen(pfad.read_text(encoding="utf-8")) if pfad.is_file() else \
        {"kennzahlen": {}, "domaenen": {}}
    delta = delta_berechnen(alt, kennzahlen, domaenen)
    geaendert = schreibe_markdown(pfad, text(delta, kennzahlen, domaenen))
    return geaendert, delta


def erwarteter_stand_text(kennzahlen, domaenen):
    """Der Soll-Standblock fuer den Waechter, ohne den Bericht zu bewerten."""
    inhalt = text(["Pruefung."], kennzahlen, domaenen)
    return inhalt[inhalt.index(STAND_START):inhalt.index(STAND_ENDE)]
