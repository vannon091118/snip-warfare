# Plan: Globaler LOC-Cap für alle Spiel-Inhalte

Version: V0.02

Der Code ist die Quelle der Wahrheit; dieser Plan ist der momentane Schnappschuss des Vorhabens
und wird je Slice mit einer Status-Zeile nachgezogen. Stand: Slice L0 offen.

## Ausgangslage

Der Auftrag lautet: Ein LOC-Cap gilt global für alle spielrelevanten Inhalte, nicht nur für
GDScript-Klassen. Observer bekommen so viel LOC wie ein Observer braucht, und Riesen werden auf
UI-, HUD-, Node- und Control-Zuständigkeiten geteilt. Die Bestandsaufnahme hat die Hintertür
gefunden: Die locregel prüft heute nur Dateien mit class_name, deshalb steht das Szenen-Skript
welt.gd mit 580 Zeilen unantastbar da, obwohl jede andere Klasse bei 100 bis 160 Zeilen gefriert.
Zweite Lücke: Szenen, Ressourcen, Shader und JSON-Pools tragen überhaupt keine Grenze; der
Element-Katalog wächst mit 547 Zeilen unbewacht. Dritte Beobachtung: Die Frostliste aus einer
alten Stufe ist weg, die Grenzen stehen nur noch im Code der Prüfung.

## Feste Entscheidungen

1. Die Hintertür stirbt: Zeilen-Grenzen gelten in den Fach-Ordnern für jede .gd-Datei, mit oder
   ohne class_name. Szenen-Skripte tragen eigene Grenzen, Welt-Szenen 160 und UI-Szenen 120.
2. Der Cap wird global: .tscn und .tres bei 140, .gdshader bei 120, .json-Datenpools bei 300
   Zeilen. Alles unterhalb der Grenze bleibt unberührt; die Prüfung schreit erst beim Wachsen.
3. Die Frostliste kehrt zurück als tools/preflight/locregel_frost.json: Für jede heutige
   Überschreitung trägt sie Datei, Ist-Zeilen und Ziel-Grenze. Ihr Vertrag ist einseitig: Sie
   darf nur schrumpfen. Sinkt der Ist-Wert, zieht die Datei nach; steigt der Wert oder verlässt
   ein Eintrag die Liste nach oben, fällt der Lauf rot.
4. Geteilt wird nach Zuschauereigenschaft, nicht nach Dateigröße: Ein Observer kriegt seine
   Grenze als eigenes Suffix, _beobachter mit 60 Zeilen, _verdrahtung mit 140, _aufbau mit 140.
   Suffix-Grenzen gelten auch für Namen ohne class_name.
5. Geteilt wird auf UI-, HUD-, Node- und Control-Zuständigkeiten: Welt-Szenen behalten nur
   Komposition und Verdrahtung, HUD- und Panel-Aufbau wandern in die UI-Spitzen, Kamera und
   Eingabe in die Ui_Steuerungen, Rechenkern in Maschinen und Observer.
6. Kein Nachlass: Für die Frostliste gilt schrumpfen ja, wachsen nie. Neue Dateien starten
   sofort unter ihrer Grenze; es gibt keinen dritten Weg mehr.
7. Der globale Check ist als Eigenschaft der locregel gebaut und bleibt in E041 verankert; der
   Vertragsstest der Anti-Hintertür kommt als test_locregel_global.py in die pytest-Familie.

## Slices

### Slice L0: Übernommener Bestand grün fahren (Status: offen)

Der Arbeitsstand kam rot über: Der Engine-Koordinator aus der Blackboard-Migration meldet sich
an der Weltuhr an, steht aber nicht in der Tick-Ordnung; zwei neue Kern-Klassen tragen
Daten-Arrays ohne Trennungs-Marker; zwei Kern-Datenpools tragen Tabulatoren; Dokumente und
Indizes erzählen alte Zahlen. L0 zieht alles nach, bis Voller Preflight und pytest grün sind,
ohne fachliche Zuwächse aus dem Plan.

### Slice L1: Prüfung bauen (Status: offen)

pruef_locregel.py wird zur globalen Prüfung: Grenzen für alle .gd in den Fach-Ordnern ohne
class_name-Schachtel, Grenzen für .tscn, .tres, .gdshader und .json, Lesen der Frostliste mit
Schrumpf-Zwang. Die Frostliste entsteht mechanisch aus dem Ist-Bestand. test_locregel_global.py
verankert die Anti-Hintertür am Code: Ohne class_name geprüft, Szenen geprüft, JSON geprüft,
Frostliste darf nur schrumpfen, Gegenprobe mit einer erfundenen Riesen-Datei schlägt laut an.

### Slice L2: welt.gd teilen, 580 auf 160 (Status: offen)

Geteilt wird auf die vier Zuständigkeiten: HUD- und Panel-Fenster (Warum-Verdrahtung,
Rückmeldungen, Ladeleiste-Speisung) in die Ui_Rückmelde- und Aufbau-Spitzen, die
Erste-Einheit- und Landeplatz-Kette in eine Welt_AnkunftsKette, die Ankunfts- und Blick-Rechnung
in einen Welt_BlickBeobachter mit 60 Zeilen, der Rest bleibt Komposition. Jede neue Datei startet
unter ihrer Grenze, die Frostliste zieht nach unten, test_sozial_domaene, test_ui_bau_panel_und_steuerung,
test_y_sort_und_landeplatz, test_einstiegs_progression und test_datengetriebene_naht bleiben grün,
weil die Zeichenketten-Verträge an den neuen Orten stehen.

### Slice L3: welt_renderer.gd teilen, 676 auf 100 (Status: offen)

Der Renderer wird Darsteller-Familie: Kachel-Aufbau, Objekt-Knoten-Nachzug, Sichtbereich und
 Faulbau-Abschluss wandern in eigene Spitzen mit eigenen Grenzen. Die Karte bleibt nur die
Anhängespitze. Beweis: lauf_pruefung_lader_sichtbar und die Sondenszenen zeichnen dieselbe Karte.

### Slice L4: welt_model.gd teilen, 529 auf 100 (Status: offen)

Das Modell wird Daten-Familie: Raster, Regionen, Biom-Zeilen, Tile-Leben und Objektliste ziehen
in eigene Basis-Klassen mit je 80 Zeilen, Welt_Model bleibt Fassade mit Durchreiche. Die
Datenparität-Prüfung wacht über die Pools.

### Slice L5 und folgende: Rest der Frostliste (Status: offen)

Reihenfolge nach Größe: welt_generator 412, ui_eingabe_steuerung 369, menue_buehnen_meister 348,
welt_world 304, einheit_ressourcen 264, einheit_verdrahtung 292, fraktions_keimling_analysator
274, welt_netzwerk_planer 296, karten_editor 245, element_katalog.json 547 mit Aufteilung des
Katalogs in eigene Pools je Kategorie. Je Slice 10 bis 15 Dateien, je Slice schrumpft die
Frostliste messbar, bis sie leer ist. Eine leere Liste heißt: Der globale Cap gilt ohne
Ausnahme.

## Verifikation je Slice

Je Slice in dieser Reihenfolge: git status auf Parallel-Änderungen, vollen Preflight grün, pytest
grün, den betroffenen Beweislauf headless fahren, das Ergebnis im laufenden Spiel sichtbar
verifizieren, shinon/commit_msg.txt mit nummerierten ganzen Sätzen und Nennung jeder geänderten
Datei füllen, Commit eins zu eins aus der Datei, Status-Zeile in diesem Plan nachziehen.
