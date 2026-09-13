# -*- coding: utf-8 -*-
"""Beweislauf: Was ein Checkpoint behauptet, wird ausgefuehrt, nicht geglaubt.

Eine Zustaendigkeit: Je Beweisart entscheiden, ob sie bestanden ist, gescheitert
ist oder gar nicht gelaufen ist. Die dritte Moeglichkeit ist die wichtigste
dieses Moduls: Ein Lauf, den niemand gestartet hat, ist kein Fehlschlag und
kein Gruen, sondern eine offene Frage. Wer Ungeprueftes als Widerlegt meldet,
bezichtigt den Code zu Unrecht; wer es als Gruen meldet, hakt ungedeckt ab.

Eine genannte Klasse gilt nur, wenn sie existiert UND verdrahtet ist: Ein
class_name, den niemand aufruft oder zuordnet, ist kein System, sondern ein
Grabstein.
"""

import subprocess
import sys

from .kern import PROJEKT_STAMM, datei_existiert

GRUEN = "gruen"
ROT = "rot"
UNGEPRUEFT = "ungeprueft"

# Zeitgrenzen: Ein Beweislauf, der haengt, bricht ab statt zu blockieren.
PYTEST_ZEITGRENZE = 600
GODOT_ZEITGRENZE = 300

# Godot-Fehlerzeilen, die einen Beweislauf entwerten, auch wenn der
# Rueckgabewert faelschlich Null bliebe.
GODOT_BRUCH_MUSTER = ("Parse Error", "Failed to load script", "SCRIPT ERROR")


class Beleg:
    """Ein einzelner Beleg: gruen bestanden, rot gescheitert, sonst ungeprueft."""

    def __init__(self, status, text):
        self.status = status
        self.text = text

    @property
    def ist_gruen(self):
        """Nur der gruene Beleg traegt eine Zusage."""
        return self.status == GRUEN

    @property
    def ist_rot(self):
        """Nur der rote Beleg widerlegt die Zusage."""
        return self.status == ROT

    def __repr__(self):
        return "Beleg(%s, %s)" % (self.status, self.text)


def _klassen_index():
    """Alle class_name des Projekts, relativ zu ihrem Pfad.

    Die Klassenliste kommt aus dem Index-Paket; eine zweite Sammelstelle waere
    eine zweite Wahrheit ueber denselben Code.
    """
    from index.kern import gd_dateien, klassen_name_holen
    index = {}
    for relativ, code in gd_dateien():
        name = klassen_name_holen(code)
        if name is not None:
            index.setdefault(name, relativ)
    return index


def _korpus_sammeln():
    """Alle durchsuchbaren Texte des Projekts als (relativer Pfad, Inhalt).

    GDScript und JSON in einem Zug: Ein Job oder eine Ressource kann
    ausschliesslich ueber das script-Feld seiner JSON-Konfiguration angebunden
    sein; das ist die Plugin-Naht des Projekts und zaehlt als Verdrahtung.
    """
    from index.kern import gd_dateien
    korpus = list(gd_dateien())
    for pfad in sorted(PROJEKT_STAMM.rglob("*.json")):
        if ".godot" in pfad.parts or "__pycache__" in pfad.parts:
            continue
        try:
            roh = pfad.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        relativ = str(pfad.relative_to(PROJEKT_STAMM)).replace("\\", "/")
        korpus.append((relativ, roh))
    return korpus


class Beweisstand:
    """Der eine Beweisstand eines Laufs: Klassen, Pytest und Laufpruefungen.

    Die Register werden einmal gefuellt und danach nur gelesen, damit ein Lauf
    ueber alle Checkpoints nicht wiederholt ueber denselben Baum laeuft.
    """

    def __init__(self, mit_godot=True, godot_befehl="godot"):
        self.mit_godot = mit_godot
        self.godot_befehl = godot_befehl
        self._klassen = None
        self._korpus = None
        self._verdrahtung = {}
        self._pytest_ergebnis = {}
        self._godot_ergebnis = {}

    def klassen_index(self):
        """Der Klassenindex, beim ersten Zugriff einmal aufgebaut."""
        if self._klassen is None:
            self._klassen = _klassen_index()
        return self._klassen

    def korpus(self):
        """Der durchsuchbare Projekttext, beim ersten Zugriff einmal gelesen."""
        if self._korpus is None:
            self._korpus = _korpus_sammeln()
        return self._korpus

    def fundstellen(self, name):
        """Fundstellen einer Klasse ausserhalb ihrer eigenen Definitionsdatei.

        Gezaehlt wird zweierlei, weil das Projekt beide Naehte fahrt: der
        Klassenname selbst und der Pfad der Definitionsdatei. Die zweite Form
        ist die Plugin-Naht des Projekts; ein Job, eine Ressource oder eine
        Spitze wird ueber das script-Feld einer JSON-Konfiguration oder ueber
        preload("res://...") angebunden, ohne dass der Klassenname je im
        Fremdcode steht. Wer nur den Namen sucht, haelt jedes Plugin fuer tot.

        Nur gefragte Klassen werden gezaehlt; der Korpus bleibt im Speicher,
        damit ein Lauf ueber alle Checkpoints nicht wiederholt liest.
        """
        if name in self._verdrahtung:
            return self._verdrahtung[name]
        eigene = self.klassen_index().get(name)
        treffer = 0
        for relativ, inhalt in self.korpus():
            if relativ == eigene:
                continue
            if name in inhalt:
                treffer += 1
                continue
            if eigene is not None and eigene in inhalt:
                treffer += 1
        self._verdrahtung[name] = treffer
        return treffer

    def klasse_beleg(self, name):
        """Beurteilt eine genannte Klasse als Beleg."""
        pfad = self.klassen_index().get(name)
        if pfad is None:
            return Beleg(ROT, "Klasse %s existiert nirgends" % name)
        treffer = self.fundstellen(name)
        if treffer == 0:
            return Beleg(ROT, "Klasse %s liegt in %s, wird aber nirgends "
                              "aufgerufen oder zugeordnet" % (name, pfad))
        return Beleg(GRUEN, "Klasse %s ist verdrahtet (%d Fundstellen)" % (name, treffer))

    def pytest_beleg(self, relativ):
        """Beurteilt eine Pytest-Beweisdatei als Beleg."""
        if relativ not in self._pytest_ergebnis:
            self._pytest_ergebnis[relativ] = self._pytest_datei_ausfuehren(relativ)
        return self._pytest_ergebnis[relativ]

    def _pytest_datei_ausfuehren(self, relativ):
        """Fuehrt genau diese Testdatei aus; Rueckgabewert Null heisst gruen."""
        if not datei_existiert(relativ):
            return Beleg(ROT, "Beweisdatei %s fehlt" % relativ)
        befehl = [sys.executable, "-m", "pytest", "-q", relativ]
        try:
            ergebnis = subprocess.run(befehl, cwd=str(PROJEKT_STAMM), capture_output=True,
                                      text=True, encoding="utf-8", errors="replace",
                                      timeout=PYTEST_ZEITGRENZE)
        except (subprocess.TimeoutExpired, OSError) as fehler:
            return Beleg(UNGEPRUEFT, "Beweisdatei %s nicht ausfuehrbar: %s" % (relativ, fehler))
        if ergebnis.returncode == 0:
            return Beleg(GRUEN, "Beweisdatei %s ist gruen" % relativ)
        schluss = [zeile for zeile in (ergebnis.stdout or "").splitlines() if zeile.strip()]
        return Beleg(ROT, "Beweisdatei %s ist rot: %s"
                     % (relativ, schluss[-1] if schluss else "ohne Meldung"))

    def godot_beleg(self, relativ):
        """Beurteilt eine Laufpruefung als Beleg."""
        if relativ not in self._godot_ergebnis:
            self._godot_ergebnis[relativ] = self._laufpruefung_ausfuehren(relativ)
        return self._godot_ergebnis[relativ]

    def _laufpruefung_ausfuehren(self, relativ):
        """Startet die Laufpruefung headless; nur fehlerfrei heisst bestanden."""
        if not datei_existiert(relativ):
            return Beleg(ROT, "Laufpruefung %s fehlt" % relativ)
        if not self.mit_godot:
            return Beleg(UNGEPRUEFT, "Laufpruefung %s ist nicht gelaufen" % relativ)
        befehl = [self.godot_befehl, "--headless", "--path", str(PROJEKT_STAMM),
                  "--script", relativ]
        try:
            ergebnis = subprocess.run(befehl, cwd=str(PROJEKT_STAMM), capture_output=True,
                                      text=True, encoding="utf-8", errors="replace",
                                      timeout=GODOT_ZEITGRENZE)
        except (subprocess.TimeoutExpired, OSError) as fehler:
            return Beleg(UNGEPRUEFT, "Laufpruefung %s nicht ausfuehrbar: %s" % (relativ, fehler))
        ausgabe = (ergebnis.stdout or "") + (ergebnis.stderr or "")
        for bruch in GODOT_BRUCH_MUSTER:
            if bruch in ausgabe:
                zeile = next((z.strip() for z in ausgabe.splitlines() if bruch in z), bruch)
                return Beleg(ROT, "Laufpruefung %s bricht ab: %s" % (relativ, zeile))
        if ergebnis.returncode != 0:
            return Beleg(ROT, "Laufpruefung %s meldet Rueckgabewert %d"
                         % (relativ, ergebnis.returncode))
        return Beleg(GRUEN, "Laufpruefung %s ist gruen" % relativ)

    def beweis_belege(self, checkpoint):
        """Alle Beweise eines Checkpoints als Belege, in genannter Reihenfolge."""
        belege = []
        for pfad in checkpoint.beweis_pfade():
            if pfad.endswith(".py"):
                belege.append(self.pytest_beleg(pfad))
            else:
                belege.append(self.godot_beleg(pfad))
        return belege

    def klassen_belege(self, checkpoint):
        """Alle genannten Klassen eines Checkpoints als Belege."""
        return [self.klasse_beleg(name) for name in checkpoint.klassen()]
