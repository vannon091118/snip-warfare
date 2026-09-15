# Domänen-Gap-Register: Funktionsprüfung und Schließungsplan

Version: V0.02

## 1. Funktionsurteil je Domäne

| Domäne | Beweis | Urteil |
| --- | --- | --- |
| core (Weltuhr, Zufall, Modifikatoren, Logik) | Pytest test_kern_hash_vertrag, test_tick_ordnung_contract; lauf_pruefung_determinismus GRUEN | Funktionsfähig |
| world (Modell, Generator, Makrokarte, Tiere, Wasser, Tageszyklus) | lauf_pruefung_makrokarte OK, lauf_pruefung_wasser GRUEN, lauf_pruefung_lader_sichtbar OK, lauf_pruefung_determinismus GRUEN | Funktionsfähig |
| game (Jobs, Einheiten, Ernte, Ressourcen) | lauf_pruefung_progression GRUEN, lauf_pruefung_gesten GRUEN; lauf_pruefung_welt PARSE-FEHLER | Teilweise belegt: Der Welt-Gesamtbeweis kompiliert nicht mehr (Gap G1) |
| population (Needs, Mood, Rassen, Sozial) | lauf_pruefung_sozial läuft mit Gerücht-, Blase- und Beziehungs-Ausgaben fehlerfrei | Funktionsfähig |
| economy (Lager, Mutationen) | indirekt über lauf_pruefung_progression und lauf_pruefung_welt-Anteile | Belegt, sobald G1 geschlossen ist |
| ui (Hauptmenü, Panels, HUD, Eingabe) | lauf_pruefung_hud PARSE-FEHLER, weil er die Welt-Szene lädt | Blockiert durch Gap G2 |
| military | Nur leere Ordnerstruktur mit .gitkeep, kein Code, kein Datenpool | Bewusste Reserve, kein Gap im engeren Sinn, aber die Domäne hat null Funktionsbeleg |
| shinon (Commit Gate) | Voller Preflight grün inklusive Kategorie shinon | Funktionsfähig |
| Szenen-API-Schicht (welt.tscn und ihre Skripte) | lauf_sonde_welt_szene: Parse Error in welt.gd | Funktionsunfähig im aktuellen Arbeitsstand (Gap G2) |

## 2. Die Gaps im Einzelnen

### G1: Beweis-Drift lauf_pruefung_welt.gd (Fehlerklasse Werkzeug, nicht Spiel)
Beweis: godot --headless --script tools/lauf_pruefung_welt.gd endet mit Parse Error an Zeile 700. Der Beweis ruft jagd_ernte.einrichten(jagd_ressourcen, jagd_modell, jagd_tiere) mit drei Argumenten; die echte Klasse Einheit_ErnteMaschine.einrichten verlangt heute vier (inventar, ressourcen, model, tiere, siehe einheit_ernte_maschine.gd Zeile 18). Der Beweis hinkt hinter einer Signatur-Änderung her.
Schließung: Zeile 700 um ein Einheit_Inventar-Objekt ergänzen (das Muster steht imselben Beweis mehrfach), dann Beweis erneut ausführen und die GRUEN-Zeile ins Lauf-Log schreiben.

### G2: Unvollständige LadeLeiste-Slice bricht die Welt-Szene (Fehlerklasse Spiel, kritisch)
Beweis: lauf_pruefung_hud und lauf_sonde_welt_szene melden Parse Error Identifier _lade_canvas not declared in welt.gd, dazu Could not resolve external class member lade_leiste. Ursache: In welt.gd Zeile 225 bis 228 wird _lade_canvas benutzt, aber nie deklariert; die Deklaration fehlt im Datenbereich der Szene. Der Artefakt-Endstand aus der vorherigen Sitzung war offenbar nur teilweise angewendet: welt_ui_aufbau.gd und ui_lade_leiste.gd existieren, die Szene-Naht fehlt zur Hälfte.
Schließung: In welt.gd den Datenbereich um var _lade_canvas: CanvasLayer = null ergänzen. Das ist eine Ein-Zeilen-Reparatur, die die halbe Slice vollendet; danach kompiliert die Szene wieder und die LadeLeiste wird sichtbar (Regel 9: Ingame-Verifikation über die Welt-Szene mit sichtbarem Balken während der Chunk-Füllung).

### G3: Stilles Grün im Preflight (Fehlerklasse Frühwarnsystem)
Beweis: python tools/preflight.py meldet PREFLIGHT OK, während dieselbe Arbeitsstand die Welt-Szene nicht kompiliert. Ursache: Die Kategorie godot startet nur die Hauptszene mit --quit-after 120 (pruef_godot.py Zeile 60 bis 62). Die Hauptmenü-Szene kompiliert, weil sie die Welt-Szene nie lädt; der gebrochene Knoten sitzt einen Szenenwechsel weiter und bleibt unsichtbar für die Prüfung.
Schließung: Ein neuer Preflight-Teilprüfer compile_check, der --check-only über alle .gd-Dateien laufen lässt (Godot 4 kennt --check-only --script je Datei; lückenlos über die 305 Dateien) oder der die Beweis-Skripte als Kompilier-Opfer einplant. Die Kategorie godot ruft ihn nach dem Hauptlauf. Damit endet das stille Grün: Jede gebrochene Klasse wird gemeldet, egal welche Szene sie lädt.

### G4: Beweisbestand ohne Inventar (Fehlerklasse Nachvollziehbarkeit)
Beweis: Zwölf lauf_*-Skripte liegen in tools/, aber kein Dokument sagt, welcher Beweis welche Domäne trägt und wann er zuletzt lief. Der Drift von G1 zeigt die Folge: Niemand bemerkt, dass ein Beweis veraltet, weil sein Scheitern nirgends auftaucht.
Schließung: Beweis-Inventar als Abschnitt im Bestandsaufnahme-Bericht oder als eigene Datei: je Skript Domäne, behauptete Aussage, letzter Lauf, Vertragswert. Danach gehören alle Beweise in den Schließungs-Slices zur Pflicht-Verifikation (Regel 9).

### G5: Military-Domäne ohne jeden Funktionsbeleg
Beweis: military/ trägt nur .gitkeep-Dateien (assets, data, logic/armies, combat, formations, units, scenes, state), kein Code, kein JSON-Pool. Die Roadmap nennt Konflikte und Schlachten als Vision, aber die Domäne hat weder Klassen noch einen Beweis.
Schließung: Kein sofortiger Umbau. Die Domäne bleibt bewusste Reserve; der Bestandsaufnahme-Bericht listet sie als leer. Sobald ein Militär-Slice startet, folgen Registry-Datenpool, Klassen mit Präfix Milit_ (oder eigener Eintrag in der Präfix-Tabelle) und ein eigener lauf_pruefung_militaer als Beweis. Erst dann gilt die Domäne als belegt.

### G6: Vorab-Änderungen ohne Nachvollziehbarkeitskette
Beweis: git status zeigt die lokale Änderung welt_ui_aufbau.gd und die neue Datei ui_lade_leiste.gd; dazu sind core/data/kern_logik.json und kern_modifikatoren.json aus einer früheren Sitzung geändert. Der Shinon-Artefakt-Endstand (commit_msg.txt) nennt die LadeLeiste, aber die Commit-Kette fehlt.
Schließung: Die halbe Slice (G2) zuerst vollenden, dann alle Beteiligten als ein Slice committen: welt.gd, welt_ui_aufbau.gd, ui_lade_leiste.gd, commit_msg.txt. Die Daten-JSONs vorher funktional prüfen (Pytest deckt sie über test_kern_hash_vertrag ab) und gegebenenfalls als eigenen Slice trennen.

## 3. Schließungs-Reihenfolge

1. Schritt 1 (G2): Deklaration in welt.gd ergänzen, Szene kompiliert, LadeLeiste sichtbar prüfen. Kleinster Schritt mit größtem Heilwert.
2. Schritt 2 (G1): Beweis lauf_pruefung_welt.gd auf die neue Signatur ziehen, erneut laufen lassen.
3. Schritt 3 (G3): compile_check als Preflight-Teilprüfer bauen, damit Parse-Fehler nie wieder still grün bleiben. Danach vollen Preflight mit Beweis.
4. Schritt 4 (G6): Commit-Slice über die LadeLeiste mit Shinon-Gate.
5. Schritt 5 (G4): Beweis-Inventar dokumentieren.
6. Schritt 6 (G5): Military bleibt Reserve und wird im Bericht als leer geführt.

Der Register-Stand gilt für den Arbeitsstand vom 13.09.2026; nach jedem Schließungs-Slice wird die betroffene Zeile mit neuem Beweis aktualisiert.

Version: V0.02
