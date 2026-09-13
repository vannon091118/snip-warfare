# -*- coding: utf-8 -*-
"""Die adversariale Gegenrede: Widerspricht die Roadmap dem Code, sagt sie es.

Eine Zustaendigkeit: Beide Richtungen der Luege benennen. Ein Haekchen ohne
Deckung ist eine Luege nach aussen, ein offener Eintrag ueber laengst
gegebenem Code eine Luege nach innen.

Jeder Eintrag landet in genau einer Gruppe, geordnet nach der Schwere. Dabei
wird streng zwischen rot und ungeprueft getrennt: Ein Beleg, den niemand
gestartet hat, darf nie als Widerlegung erscheinen. Ein widerlegtes Haekchen
ist ein Fehler, ein ungeprueftes eine offene Frage, ein unbelegtes eine
Dokumentationsschwaeche. Doppelmeldungen derselben Zeile verdecken die Menge
der echten Probleme, deshalb gibt es sie hier nicht.
"""

FALSCH = "WIDERLEGTES HAECKCHEN"
UNGEPRUEFT = "UNGEPRUEFTES HAECKCHEN"
UNBELEGT = "UNBELEGTES HAECKCHEN"
FEHLENDE_KLASSE = "FEHLENDE KLASSE"
TOTE_KLASSE = "TOTE KLASSE"
ROTER_BEWEIS = "ROTER BEWEIS"
KLASSEN_SCHON_DA = "OFFEN, ABER KLASSEN SCHON DA"
ABHAK_BEREIT = "ABHAK-BEREIT"
OHNE_BEWEIS = "OHNE BEWEIS"
DOPPELTE_NUMMER = "DOPPELTE NUMMER"

# Alle Gruppen in der Reihenfolge ihrer Dringlichkeit.
GRUPPEN = (FALSCH, FEHLENDE_KLASSE, TOTE_KLASSE, ROTER_BEWEIS, KLASSEN_SCHON_DA,
           ABHAK_BEREIT, UNGEPRUEFT, UNBELEGT, OHNE_BEWEIS)

# Gruppen, deren Eintraege einzeln als Satz genannt werden. Die Sammelgruppen
# danach werden als Zahl mit Namensliste gemeldet: Ein Satz je Eintrag wuerde
# den Bericht zumuellen, ohne dass ein Leser daraus eine Handlung ziehen kann.
EINZELN_GENANNT = (FALSCH, FEHLENDE_KLASSE, TOTE_KLASSE, ROTER_BEWEIS,
                   KLASSEN_SCHON_DA, ABHAK_BEREIT)
GESAMMELT_GENANNT = (UNGEPRUEFT, UNBELEGT, OHNE_BEWEIS)


def _klassengruende(urteil):
    """Trennt Klassengruende in nicht vorhandene und nicht verdrahtete."""
    fehlend, tot = [], []
    for text in urteil.klassenfehler:
        if "existiert nirgends" in text:
            fehlend.append(text)
        else:
            tot.append(text)
    return fehlend, tot


def _einordnen(urteil):
    """Ordnet einen Checkpoint genau einer Gruppe zu.

    Reihenfolge der Pruefung ist die Reihenfolge der Schwere. Ein fertiger
    Eintrag kann widerlegt, ungeprueft oder unbelegt sein; ein offener Eintrag
    kann nicht widerlegen, aber er kann Klassen nennen, die es nicht gibt oder
    die niemand aufruft.
    """
    eintrag = urteil.checkpoint
    fehlend, tot = _klassengruende(urteil)
    if eintrag.ist_fertig:
        if urteil.widerlegt:
            return FALSCH
        if not eintrag.hat_beweis():
            return UNBELEGT
        if urteil.ungeprueft:
            return UNGEPRUEFT
        return None
    if not eintrag.ist_offen:
        # Die halbe Tilde deckt nicht; sie wird nicht beurteilt, aber auch
        # nicht als fertig ausgegeben.
        return None
    if fehlend:
        return FEHLENDE_KLASSE
    if tot:
        return TOTE_KLASSE
    if urteil.widerlegt:
        # Ein offener Eintrag mit rotem Beweis ist kein ungepruefter Wunsch:
        # Die Pruefung, die ihn belegen soll, laeuft schon jetzt ins Leere.
        return ROTER_BEWEIS
    if urteil.bestanden:
        return ABHAK_BEREIT
    if eintrag.klassen():
        return KLASSEN_SCHON_DA
    return OHNE_BEWEIS


def befunde_sammeln(urteile, doppelte):
    """Alle Befunde als Gruppen-Dictionary plus die doppelten Nummern."""
    gruppen = {titel: [] for titel in GRUPPEN}
    for urteil in urteile:
        ziel = _einordnen(urteil)
        if ziel is not None:
            gruppen[ziel].append(urteil)
    return gruppen, dict(doppelte)


def saetze(gruppen, doppelte):
    """Formt die Befunde zu nummerierten deutschen Saetzen.

    Die Nummerierung ist lueckenlos und jeder Satz endet mit einem Punkt, weil
    derselbe Bericht als Vorlage fuer die Commit-Erzaehlung taugt.
    """
    ausgabe = []
    for titel in EINZELN_GENANNT:
        for urteil in gruppen[titel]:
            eintrag = urteil.checkpoint
            ausgabe.append("%s: %s in Zeile %d, Kapitel %s (%s)."
                           % (titel, eintrag.name, eintrag.zeile,
                              eintrag.kapitel or "ohne Kapitel", urteil.kurzfassung()))
    for titel in GESAMMELT_GENANNT:
        eintraege = gruppen[titel]
        if not eintraege:
            continue
        namen = ", ".join(urteil.checkpoint.nummer for urteil in eintraege)
        ausgabe.append("%s: %d Eintraege, naemlich %s." % (titel, len(eintraege), namen))
    for nummer in sorted(doppelte):
        ausgabe.append("%s: %s ist in den Zeilen %s vergeben."
                       % (DOPPELTE_NUMMER, nummer,
                          ", ".join(str(z) for z in doppelte[nummer])))
    return ausgabe


def bericht(gruppen, doppelte):
    """Der vollstaendige Befund als Liste fertiger Zeilen, nummeriert.

    Leere Gruppen werden mit Null benannt, nicht verschwiegen: Ein Bericht, der
    nur seine Treffer zeigt, verdeckt den Unterschied zwischen sauber und
    ungeprueft.
    """
    zeilen = ["%s: %d" % (titel, len(gruppen[titel])) for titel in GRUPPEN]
    zeilen.append("%s: %d" % (DOPPELTE_NUMMER, len(doppelte)))
    zeilen.append("")
    for nummer, satz in enumerate(saetze(gruppen, doppelte), start=1):
        zeilen.append("%d. %s" % (nummer, satz))
    return zeilen
