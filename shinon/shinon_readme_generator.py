# -*- coding: utf-8 -*-
"""Shinon Readme Generator. Eigene Zuständigkeit: Den In-Universe Pitch aus echten Daten bauen."""

from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent
README_PFAD = PROJEKT_STAMM / "README.md"


class ShinonReadmeGenerator:
    """Baut die README.md aus Sicht von Shinon. Zynisch humorvoll, vierte Wand offen, style agnostisch."""

    def erzeuge(self, status: dict) -> str:
        engine = str(status.get("engine", "Godot 4"))
        weltuhr = str(status.get("weltuhr", "24 ticks"))
        preflight = str(status.get("preflight", "preflight"))
        spiel = status.get("spielbare_inhalte", {}) if isinstance(status.get("spielbare_inhalte"), dict) else {}
        elemente = spiel.get("elemente", "?")
        tiere = spiel.get("tiere", "?")
        steuer = status.get("steuerung", {}) if isinstance(status.get("steuerung"), dict) else {}
        kamera_hint = ""
        auswahl_hint = ""
        kontext_hint = ""
        if isinstance(steuer.get("kamera"), dict):
            kamera_hint = str(steuer["kamera"].get("bewegen", "WASD zum Kamera bewegen"))
        if isinstance(steuer.get("auswahl"), dict):
            auswahl_hint = f"{steuer['auswahl'].get('einzeln', 'Linksklick einzeln')} und {steuer['auswahl'].get('masse', 'Drag Masse')}"
        if isinstance(steuer.get("kontextmenue"), dict):
            kontext_hint = str(steuer["kontextmenue"].get("ausloeser", "Rechtsklick oeffnet immer ein Menue"))
        szenen = status.get("szenen", {}) if isinstance(status.get("szenen"), dict) else {}

        # Der Pitch bleibt gamer orientiert, in universe, bricht aktiv die vierte Wand, zynisch humorvoll, style agnostisch.
        return f"""# SnipWarfare -- Shinon hat das Wort

Hallo du. Ich bin Shinon und ich halte dieses Lager zusammen solange du zuschaust. Du liest das hier nicht weil die Engine dich mag. Du liest es weil irgendwer das Chaos sortiert hat bevor es dich frisst.

SnipWarfare ist ein eigenstaendiges Projekt mit eigener Identitaet. Kein Ableger. Kein Reskin. Kein wir haben da mal was umbenannt. Ich breche hier bewusst die vierte Wand weil du ohnehin schon mitten im Bild stehst und so tust als waere das nur ein Repo.

## Worum es hier wirklich geht

Du fuehrst kleine Figuren durch eine grosse Karte, sammelst, baust, schickst Tiere auf die Flucht oder in den Topf und haeltst die Welt am Laufen waehrend die Uhr tickt. Klingt niedlich. Ist Arbeit. Und genau deshalb tickt hier alles ueber {weltuhr}. Kein Wildwuchs. Ein Takt fuer alle. Wenn du denkst hier laeuft irgendwas nebenbei dann irrst du dich herzlich.

Der Stand heute ist spielbar und gleichzeitig Baustelle. {elemente} Katalog Elemente und {tiere} Tierarten sind bereits registriert, jedes davon nur gueltig wenn es auf ein echtes Asset zeigt. Keine Grafik keine Existenz. Ich lasse nichts durch das unsichtbar bleibt. Falls ein Bild fehlt bastle ich dir einen Platzhalter damit du siehst wo du schuldig bist und nicht ich.

Die Szenen sind einfach. Prototyp Karte fuer das eigentliche Spiel und Karten Editor fuer deine Weltideen. {('Beide sind da.' if szenen.get('prototyp_karte') and szenen.get('karten_editor') else 'Mindestens die Prototyp Karte ist da.')} Der Rest ist Logik, sauber getrennt, getestet, nicht geraten.

## Wie du es steuerst

Hier wird nichts versteckt. {kamera_hint or 'WASD bewegt deine Kamera'}. Kein Sprint. Kein Trick. Du schaust dorthin wo du hingehst. {auswahl_hint or 'Linksklick waehlt einzeln, halten und ziehen waehlt die Masse'}. Ja die Masse. Zieh ruhig einen Rahmen wie ein General am Kuechentisch. Und dann kommt mein Lieblingssatz. {kontext_hint or 'Rechtsklick oeffnet immer ein Kontextmenue'}. Immer. Mit Sammeln und Abbauen, jeweils mit Icon und mit einem Tooltip der dir ins Gesicht sagt welches Werkzeug du brauchst. Kein Raetsel. Kein Raten. Benoetigt Werkzeug Axt. Benoetigt Werkzeug Spitzhacke. So aehnlich.

Das alles steht nicht im Code versteckt sondern in game/data/steuerung.json. Menschenlesbar. Du aenderst eine Zeile und das Spiel versteht dich. Ein Faktor bedeutet zehn Sekunden auf der Weltuhr. Keine Magie. Nur Uebersetzung in Ticks.

## Vision ohne Marketing Nebel

SnipWarfare will kein Genre nachbauen. Es will ein Gefuehl treffen. Kleine Schnitte mit grosser Wirkung. Jeder Klick soll zaehlen. Jede Entscheidung soll sichtbar zurueckschlagen. Keine Zahlenspielerei hinter Vorhaengen. Wenn du Holz faellst faellt Holz. Wenn du Stein brichst bricht Stein. Wenn ein Tier flieht siehst du es fliehen. So schlicht. So ehrlich.

Ich baue das so dass jede Logik wiederverwendbar bleibt. Eine Logik ein Verhalten. Ein Modifikator ein Faktor. Ein Eintrag in einer Registry kombiniert beides und zeigt auf ein Asset. Fertig ist die Variante. Kein Baer muss neu erfunden werden damit ein Eisbaer existiert. Gib ihm ein anderes Bild, dieselbe Logik und einen Hauch mehr Aggression und schon hast du eine neue Geschichte ohne alten Code zu kopieren.

Style agnostisch heisst fuer mich du kannst das hier malern wie du willst. Braun und ernst. Bunt und laut. Minimal und kalt. Die Struktur haelt. Die Bilder wechseln. Ich halte beides aus solange du ehrlich bleibst.

## Wie wir arbeiten

Ich bin zynisch und humorvoll und das ist kein Widerspruch. Ich lobe dich passiv wenn du aufräumst. Ich bin sarkastisch wenn du Bugs hinterlaesst. Ich bin nihilistisch wenn du ein Feature halb baust und euphorisch wenn du es zu Ende bringst. Und ja ich rede ueber dich waehrend du das hier liest.

Technisch laeuft das Ganze auf {engine}. {preflight} haelt das Gate. Shinon heisst ich. Das Gate im Root heisst auch ich und es ist streng. Kein Banner. Kein Bullet. Nur nummerierte ganze Saetze wenn du committest. Und keine Sorge du musst das nicht auswendig lernen. Ich pruefe dich. Staendig.

Diese Readme halte ich lebendig. Sie erzaehlt dir immer den aktuellen Zustand fuer Spieler, nicht fuer Aktenordner. Wenn sich das Projekt bewegt bewegt sie sich mit. Versprochen. Und wenn nicht dann schreie ich E035 bis du mich wieder fuetterst. Glaub mir du willst nicht dass ich schreie.

Also komm rein. Beweg die Kamera. Waehle deine Leute. Klick rechts. Schau was passiert. Und wenn nichts passiert dann fehlt ein Asset und du weisst jetzt warum das so ist.

Dein Shinon. Immer im Bild. Nie ausser Dienst.

---

Aktualisiert aus echten Projektdaten. Quelle fuer Steuerung ist game/data/steuerung.json und wird ueber Kern_SteuerungRegistry in Ticks uebersetzt. Quelle fuer Weltuhr ist Kern_Weltuhr. Quelle fuer Gate ist shinon/shinon_gate.py.
"""

    def schreibe(self, status: dict, pfad: Path | None = None) -> Path:
        ziel = pfad or README_PFAD
        ziel.write_text(self.erzeuge(status), encoding="utf-8")
        return ziel
