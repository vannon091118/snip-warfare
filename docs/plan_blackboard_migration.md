# Plan: Blackboard-Migration mit Engine-Registrar und Konsolidator

Version: V0.02

Dieses Dokument ist die Arbeitsgrundlage der Migration. Der Code bleibt die Quelle der Wahrheit;
dieser Plan ist der momentane Schnappschuss des Vorhabens und wird je Slice mit einer Status-Zeile
nachgezogen. Stand: Slice 0.

## Ziel

Die drei verifizierten Cross-Domänen-Lecks werden geschlossen, indem fachliche Logik in Engines
wandert, die ihre Zustände in Sektoren eines Blackboards ablegen. Ein Koordinator besitzt das Brett,
treibt den Zyklus an der Weltuhr und reicht Views nur während der Phasen aus. Ein Konsolidator liest
alle Sektoren und schreibt genau einen konsolidierten Sektor, aus dem jede Domäne die Zustände der
anderen liest. Callables, die über Domänengrenzen zeigen, sterben; der Kern-SignalBus behält nur die
Darstellungs-Signale.

## Verifizierte Fakten (Runde 1, 21 Werkzeugaufrufe gegen den Code)

1. Leck 1: pop_mood_maschine.gd hält _lager: Lager_Manager als Feld (Zeile 15) und liest Economy
   direkt (Zeilen 93 bis 97). pop_need_nahrung.gd trägt denselben Zeiger im Override
   verfuegbar_summe(lager: Lager_Manager) (Zeile 23). Beide Dateien wandern auf Bestand-Snapshots.
2. Leck 2: soz_zeugen_maschine.gd und soz_geruecht_maschine.gd tragen je position_fuer: Callable.
   Soz_Manager setzt die Callables je Tick neu. position_melden (soz_manager.gd Zeile 53) hat null
   Aufrufer. Die Positionen stammen aus einheit_anmelden (einmalig, welt.gd Zeile 517, nur Einheit 0)
   und bleiben am Ankunftspunkt eingefroren, nicht Vector2.ZERO.
3. Leck 2 verschärft: Soz_Manager.auf_tick hat im Spielbaum keinen Aufrufer. Sozial tickt im Spiel
   nie, Gerüchte wandern nie, _bekannte enthält nur Einheit 0. Das ist ein Live-Bug, nicht nur
   Architektur-Schulden. Slice 2 behebt ihn.
4. Leck 3: einheit_verdrahtung.gd trägt _sozial_lese_ruf (Zeile 14) und den sozial_bubble_tick-Ruf.
   sozial_lese_ruf_setzen (einheit_manager.gd Zeile 58) hat null Aufrufer: Blasen entstehen nie,
   der Blasen-Tick iteriert ein leeres Array. Die Brücke ist tot und wird in Slice 4 gelöscht.
5. Kein Leck: ethik_von, glaube_von, trait_wirkung in Soz_BeziehungsEngine bleiben innerhalb der
   Sozial-Domäne und bleiben erlaubt.
6. Weltuhr: ordnung.json trägt 13 Teilnehmer mit Domäne und Grund. Tier_Manager zuerst, Einheiten-
   Manager in _enter_tree. Soz_Manager hat keinen Connect und keinen Eintrag in der Ordnung.
7. Preflight: E045 ist durch die Kategorie bau_kette belegt (kategorie_register.py, pipeline.py).
   Die neue Kategorie engine_bruecken verwendet deshalb E046 bis E050.
8. LOC-Grenzen (E041) prüfen nur Suffix-Dateinamen in den Fach-Ordnern: _basis 80, _mutation 60,
   _maschine 120, _manager 150. einheit_manager.gd liegt bei 147 von 150, pop_mood_maschine.gd bei
   112 von 120, soz_manager.gd bei 80 von 150 (kein Suffix-Treffer, Fassade bleibt frei).
9. Brücken-Signale: kannibalismus_erreignis wird von einheit_ernte_maschine.gd ausgestoßen und hat
   keinen Konsumenten. konflikt_erklaert hat Sender fraktions_ki_maschine.gd und keinen Konsumenten.
   decken_entfernt hat Sender job_graben.gd und den lebenden Konsumenten welt_wasser_automat.gd.
   produktionsraum_entstanden hat den lebenden Konsumenten welt_fortschritts_maschine.gd.
10. Warteschlange: tools/warteschlange/ trägt Tickets für godot_headless, sonden_fenster und
    git_push; slice_bauer.py schneidet Slices von 10 bis 15 Dateien je Domänen-Präfix.

## Feste Architektur-Entscheidungen

1. Bus-Teilung: Darstellungs-Signale (schaden_erhalten, gestorben, lager_geaendert, kachel_geaendert,
   timeline_eintrag, menue_geoeffnet, einheit_ausgewaehlt) bleiben am Kern_SignalBus. Die Brücken
   (kannibalismus_erreignis, konflikt_erklaert, decken_entfernt, produktionsraum_entstanden) wandern
   als Event-Queues in Sektoren über den Konsolidator, mit einem Takt Latenz.
2. Kern_Mutation bleibt unverändert die Zahnrad-Form. Neu sind Kern_Blackboard (Sektoren-Container
   mit Kopiermauer), Kern_BlackboardView (Phasen-View mit Schreib-Sperre) und Kern_Engine
   (Lese-Verarbeiten-Schreiben-Rahmen).
3. Der Koordinator ist der Registrar. Plain-Node, erzeugt in welt.gd, kein Autoload. Er besitzt das
   Brett, hält einen geschützten Weltuhr-Connect und reicht Views nur während der Phasen aus.
4. Views tragen ihren Sektor fest beim Erzeugen. Lesen: eigener Sektor plus konsolidiert. Schreiben:
   nur eigener Sektor. Der Konsolidator liest alles und schreibt nur konsolidiert. Zwischen den
   Phasen halten Engines keine Brett-Referenz.
5. Transformationen sind Kern_Mutation-Subklassen unter core/logic/kategorie_konsolidierung/ und
   RefCounted. JSON trägt nur Metadaten (lesende und schreibende Felder je Sektor, Taktteiler), nie
   Transformationslogik.
6. Taktteiler: engine_register.json je Engine, Vergleich nummer % takt_teiler == 0 auf der
   Weltuhr-Nummer. GATE_TEILER und VERHALTEN_STREUUNG der Einheiten-Maschine bleiben unberührt.
7. Node-Manager (Einheiten-Manager, Sozial-Fassade) behalten ihr extends und implementieren die
   Phasen-Methoden; ihr Engine-Wickel implementiert Kern_Engine.
8. Dateinamen: kern_engine_basis.gd und kern_blackboard_basis.gd tragen das _basis-Suffix, damit die
   80-Zeilen-Kappe mechanisch greift.

## Preflight-Kategorie engine_bruecken (E046 bis E050)

1. E046 View-Zwang: Keine Datei außerhalb von core/logic/kategorie_blackboard/ erzeugt Kern_Blackboard
   oder greift roh auf Sektoren zu.
2. E047 Brücken-Verbot: Callable-Felddeklarationen, deren Quelle und Ziel verschiedene Domänen-
   Präfixe tragen, sind verboten. Innerhalb der Domäne bleibt erlaubt.
3. E048 Registrier-Vertrag: Jede Engine-Datei braucht einen Eintrag in engine_register.json; die
   Felder müssen zu konsolidierung.json passen.
4. E049 Phasen-Form: Engine-Klassen implementieren blackboard_lesen, verarbeiten, blackboard_schreiben.
5. E050 Event-Queue-Schema: Queue-Einträge tragen art und daten, nie ziel_engine.

## Slices

### Slice 0: Aufräumen (Status: in Arbeit)

Plan-Dokument anlegen, vollständigen Git-Bestand sichten, vollen Preflight grün fahren, Bestand in
Slices von 10 bis 15 Dateien schneiden, je Slice mit Warteschlangen-Ticket, shinon/commit_msg.txt und
eins zu eins übernommenem Commit-Text committen, am Ende pushen auf origin/main.

### Slice 1: Fundament (Status: offen)

Kern-Dateien: kern_blackboard_basis.gd, kern_blackboard_view.gd, kern_engine_basis.gd,
kern_engine_koordinator.gd unter core/logic/kategorie_blackboard/. Konsolidator:
kern_konsolidator.gd plus drei Durchreich-Transformationen (Positionen, LagerBestaende, Ereignisse,
alle leer) unter core/logic/kategorie_konsolidierung/. Daten: core/data/konsolidierung.json und
core/data/engine_register.json. Preflight: pruef_engine_bruecken.py mit E046 bis E050, eingehängt in
kategorie_register.py, pipeline.py und tools/preflight.py. Prüfungen: test_blackboard_vertrag.py
(statisch) und tools/lauf_pruefung_blackboard.gd (Beweislauf mit zwei Dummy-Engines, Taktteiler-Kontrast
und sichtbar abgefangener Phasenverletzung). ordnung.json bekommt den Koordinator-Eintrag, welt.gd
hängt ihn als Kind ein, ohne eine Engine zu registrieren. Beweis: Kopflos, Zyklus läuft, Verletzung
wird abgefangen.

### Slice 2: Soz_Engine (Status: offen)

soz_engine.gd extends Kern_Engine in population/logic/sozial/logic/. Soz_Manager bekommt
positionen_uebernehmen(dict) und auf_tick_intern(); auf_tick bleibt als Alias für den bestehenden
Beweislauf; position_melden fällt weg; die vier pro-Tick-Callable-Zuweisungen wandern in eine
einmalige Einrichtung. Die Positions-Transformation bleibt leer. Register, Konsolidierung und Ordnung
ziehen nach; welt.gd registriert die Engine. Positionen bleiben bis Slice 4 eingefroren, das ist
dokumentiert. Beweis: Sozial tickt über den Koordinator, Gerüchte wandern sichtbar.

### Slice 3: Lager_Engine (Status: offen)

lager_engine.gd extends Kern_Engine in economy/logic/storage/; sie liest den Lager-Manager und
schreibt lager_bestaende. Die Summen-Transformation füllt konsolidiert.lager_bestaende_gesamt.
einheit_verdrahtung.gd bleibt unberührt, lager_erneuern bleibt (sie verdrahtet Trupp und Job-Fluss).
Kein Mood-Umbau, weil erst Slice 4 einen Leser bringt. Beweis: Summen sichtbar im konsolidierten
Sektor.

### Slice 4: Einheit_Engine (Status: offen)

einheit_engine.gd extends Kern_Engine. Die Positions-Transformation liefert echte Positionen mit
Teiler 1. einheit_manager.gd verliert den Weltuhr-Connect aus _enter_tree. pop_mood_maschine.gd
tauscht _lager gegen _bestand: Dictionary; pop_need_nahrung.gd nimmt verfuegbar_summe(Dictionary).
einheit_verdrahtung.gd reicht Bestand statt Lager in stimmung_erneuern und verliert die tote
Sozial-Brücke; der lager-Eintrag im Einwanderungs-Bündel wird vor dem Umbau geprüft. Ab diesem Slice
feuert der Zeugen-Radius korrekt. Beweis: Positionen im Brett, Stimmung liest konsolidierte Summen,
Blasen erscheinen.

### Slice 5: Pop_Engine und erste Event-Queue (Status: offen)

pop_engine.gd aggregiert die Needs; Mood-Maschinen bleiben interne Helfer. Die Ereignis-Transformation
liest Sektor-Queues, schreibt konsolidiert.ereignisse und leert die Queues. Nur kannibalismus_erreignis
wandert: die Ernte-Maschine schreibt in den Einheiten-Puffer, die Soz-Engine konsumiert aus
konsolidiert.ereignisse und bucht die Tat mit echtem Tatort; der Test der Sozial-Domäne zieht mit.
decken_entfernt, produktionsraum_entstanden und konflikt_erklaert bleiben bis Slice 6 am Bus. Beweis:
Tat, Queue, Konsolidierung, Zeugen-Buchung, ein Takt Latenz.

### Slice 6: Welt_Engine und Abschluss (Status: offen)

welt_engine.gd. Die drei verbleibenden Brücken wandern: konflikt_erklaert (Sender Fraktions-KI in den
Welt-Puffer), decken_entfernt (Sender Job_Graben in den Einheiten-Puffer, Konsument Wasser-Automat,
ein Takt später), produktionsraum_entstanden (Konsument Fortschritts-Maschine). Reine Darstellungs-
Teilnehmer (Atmosphäre, Story-Regisseur, Tier-Darsteller, Staub) bleiben an der Weltuhr und werden in
einer neuen Sektion Außen stehende Spitzen in Architektur.md verzeichnet. Der Military-Sektor wird
leer deklariert. ordnung.json bleibt Quelle der Uhr-Reihenfolge. Beweis: Wasser füllt den Graben einen
Takt später, der Fortschritt spawnt den Orchestrator wie zuvor.

## Verifikation je Slice

Je Slice in dieser Reihenfolge: Warteschlangen-Ticket nehmen, git status auf Parallel-Änderungen
prüfen, vollen Preflight grün, pytest grün, den Beweislauf des Slices headless fahren, das Ergebnis
im laufenden Spiel sichtbar verifizieren, shinon/commit_msg.txt mit nummerierten ganzen Sätzen und
Nennung jeder geänderten Datei füllen, Commit eins zu eins aus der Datei, Ticket freigeben und die
Status-Zeile in diesem Dokument nachziehen.
