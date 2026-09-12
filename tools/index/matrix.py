# -*- coding: utf-8 -*-
"""Signal- und Array-Matrix je Domaene.

Eine Zuständigkeit: Signale und typisierte Arrays mit ihrer Domaene verbinden.
Signale kennen drei Rollen, naemlich Deklaration (D), Senden (S) und Verbinden
(V). Arrays kennen einen Traeger, naemlich die Domaene, die `Array[Typ]`
schreibt. Beide werden als Matrix ueber dieselben Domaenen ausgegeben, die auch
die Domaenenliste des Index kennt.
"""

from .kern import (ALLE_DOMAENEN, ARRAY_MUSTER, DOMAENEN, SENDEN_MUSTER,
                   SIGNAL_MUSTER, VERBINDEN_MUSTER, gd_dateien, klassen_name_holen,
                   kuerzel_von)

ROLLEN = ("D", "S", "V")


def _domaene(relativ):
    for schluessel, _kuerzel, _praefix, ordner in DOMAENEN:
        if relativ.startswith(ordner):
            return schluessel
    return None


def _kuerzel(domaene):
    """Uebersetzt einen Domaeneschluessel in das Matrix-Kuerzel."""
    return kuerzel_von(domaene)


def signal_sammeln(dateien=None):
    """Sammelt je Signal die Domaene der Deklaration und alle Rollen danach.

    Der Schluessel ist Klasse und Signalname, denn zwei Klassen duerfen ein
    gleichnamiges Signal tragen; nur der Name wuerde beide zu einer Zeile
    verschmelzen und die Matrix still verfaelschen.
    """
    dateien = gd_dateien() if dateien is None else dateien
    signale = {}
    offen = {}
    # Erster Durchgang: Nur Deklarationen sammeln. Ein emit darf auf ein Signal
    # zeigen, das eine spaeter gelesene Datei deklariert; deshalb erst sammeln.
    for relativ, code in dateien:
        domaene = _kuerzel(_domaene(relativ))
        klasse = klassen_name_holen(code) or relativ.rsplit("/", 1)[-1].replace(".gd", "")
        for zeilennummer, zeile in enumerate(code.splitlines(), start=1):
            treffer = SIGNAL_MUSTER.match(zeile)
            if treffer is None:
                continue
            name = treffer.group(1)
            signale.setdefault("%s.%s" % (klasse, name),
                               {"klasse": klasse, "name": name, "datei": relativ,
                                "zeile": zeilennummer, "deo": domaene, "rollen": {}})
            signale["%s.%s" % (klasse, name)]["rollen"].setdefault(domaene, set()).add("D")
    # Zweiter Durchgang: Senden und Verbinden den Traegern des Namens zuordnen.
    for relativ, code in dateien:
        domaene = _kuerzel(_domaene(relativ))
        for muster, rolle in ((SENDEN_MUSTER, "S"), (VERBINDEN_MUSTER, "V")):
            for name in muster.findall(code):
                ziele = [schluessel for schluessel, eintrag in signale.items()
                         if eintrag["name"] == name]
                if not ziele:
                    offen.setdefault(name, {}).setdefault(domaene, set()).add(rolle)
                    continue
                for schluessel in ziele:
                    signale[schluessel]["rollen"].setdefault(domaene, set()).add(rolle)
    return signale, offen


def zellen_text(rollen, kuerzel):
    """Zellinhalt der Signal-Matrix: Rollenbuchstaben einer Domaene."""
    return "".join(rolle for rolle in ROLLEN if rolle in rollen.get(kuerzel, set()))


def signal_matrix_kopf():
    """Kopfzeile der Signal-Matrix mit einer Spalte je Domaene."""
    kopf = "| Signal |" + "".join(" %s |" % kuerzel
                                 for _s, kuerzel, _p, _o in ALLE_DOMAENEN)
    trenner = "| --- |" + " --- |" * len(ALLE_DOMAENEN)
    return [kopf, trenner]


def signal_matrix_zeilen(signale):
    """Alle Signal-Zeilen der Gesamtmatrix, nach Domaene und Klasse sortiert."""
    zeilen = []
    for schluessel, eintrag in sorted(
            signale.items(),
            key=lambda eintrag: (str(eintrag[1]["deo"]), eintrag[1]["klasse"],
                                 eintrag[1]["name"])):
        zellen = "".join(" %s |" % (zellen_text(eintrag["rollen"], kuerzel) or "-")
                         for _s, kuerzel, _p, _o in ALLE_DOMAENEN)
        zeilen.append("| `%s` |%s" % (schluessel, zellen))
    return zeilen


def array_sammeln(dateien=None):
    """Sammelt je Array-Elementtyp die tragenden Domaenen und Dateien."""
    dateien = gd_dateien() if dateien is None else dateien
    arrays = {}
    for relativ, code in dateien:
        kuerzel = _kuerzel(_domaene(relativ))
        for typ in ARRAY_MUSTER.findall(code):
            arrays.setdefault(typ, {}).setdefault(kuerzel, set()).add(relativ)
    return arrays


def array_matrix_text(arrays):
    """Gesamtmatrix aller `Array[Typ]` ueber dieselben Domaenen."""
    zeilen = ["| Array-Elementtyp | Gesamt |" +
              "".join(" %s |" % kuerzel for _s, kuerzel, _p, _o in ALLE_DOMAENEN),
              "| --- | --- |" + " --- |" * len(ALLE_DOMAENEN)]
    for typ, traeger in sorted(arrays.items(),
                               key=lambda eintrag: (-sum(len(v) for v in eintrag[1].values()),
                                                    eintrag[0])):
        gesamt = sum(len(dateien) for dateien in traeger.values())
        zellen = "".join(" %s |" % (len(traeger[kuerzel]) if kuerzel in traeger else "-")
                         for _s, kuerzel, _p, _o in ALLE_DOMAENEN)
        zeilen.append("| `%s` | %d |%s" % (typ, gesamt, zellen))
    return zeilen


def zusammenfassung(signale, arrays):
    """Zahlen fuer Kopfzeilen und Delta: Signale, Rollen und Array-Typen."""
    return {
        "signale": len(signale),
        "array_typen": len(arrays),
        "array_vorkommen": sum(len(dateien) for traeger in arrays.values()
                               for dateien in traeger.values()),
    }
