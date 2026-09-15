# Plan: Vollständige, lückenlose Architektur-Bestandsaufnahme (read-only)

Status: Plan, V0.01-Stand 13.09.2026. Der Plan ist die Arbeitsgrundlage für die Bestandsaufnahme; er ändert selbst keinen Code. Alles Folgende ist aus dem Code gelesen, nicht geraten. Ziel: Eine lückenlose Inventur der Godot-Szenen-API-Nutzung, ein Hotspot-Register mit Defusing-Plan je Fundstelle und ein Schnittplan, wo Altlasten gestrichen werden. Alles läuft read-only: Es wird gemessen, verglichen und protokolliert, aber nichts umgebaut.

## 1. Prüfgrenze: Was vollständig erfasst wird (Lückenlosigkeit als E085-Vertrag)

Die Inventur gilt nur dann als vollständig, wenn jede der folgenden Dateigruppen geprüft ist und jeder Fund eine fortlaufende Fundstellen-ID trägt. Ein Bereich ohne Befund wird ausdrücklich als "geprüft und leer" notiert, nicht übersprungen.

1. Alle 11 Szenen-Dateien (.tscn): ui/scenes/hauptmenue.tscn, ui/scenes/uebergang.tscn, ui/scenes/panels/bau_panel.tscn, einheit_panel.tscn, pop_einheit_panel.tscn, tier_panel.tscn, world/scenes/welt.tscn, welt_map.tscn, waerme_overlay.tscn, karten_editor.tscn, control.tscn.
2. Alle .gd-Skripte (304 Dateien), gruppiert nach Domäne: core, world, game, population, economy, ui, tools.
3. Die 3 Autoloads aus project.godot: Weltuhr (Kern_Weltuhr), WeltSitzung (Ui_WeltSitzung), KernSignalBusAutoload (Kern_SignalBus).
4. Alle JSON-Datenpools als Werkgrenze: core/data, world/data, game/data, population/data, economy/data.
5. Die Prüf- und Beweis-Werkzeuge: tools/preflight/ (19 Kategorien), tools/warnungs_scan.py, die 16 Lauf-Beweise tools/lauf_*.gd, die 19 Pytest-Dateien im Stamm.
6. Die Szenenwechsel-Kanten: jede change_scene_to_file-Stelle, jeder PackedScene.instantiate()-Ruf, jeder preload-Konstantenpfad.

## 2. Inventar-Schicht A: Bestandsaufnahme der Ist-Architektur (read-only)

Schritt A1: Domänen- und Klassengrenzen. Abgleich der Klassenpräfixe (Kern_, Welt_, Objekt_, Einheit_, Job_, Pop_, Soz_, Lager_, Gebaeude_, Ui_, Tier_, Resources_, Orchestrator_, Feedback-, Generator-, Atmosphaere-Grenzen) gegen Architektur.md Abschnitt 1 und die INDEX-Familie. Ergebnis: Ist-Tabelle Domäne, Klassenanzahl, Ordner, Abweichungen.

Schritt A2: Zuständigkeits-Matrix je State-Maschine. Jede Maschine (Einheit_Status, Einheit_VitalStatus, Einheit_TaktMaschine, Einheit_VerhaltensMaschine, Einheit_ErnteMaschine, Einheit_TruppMaschine, Einheit_TransportMaschine, Einheit_EinwanderungsMaschine, Einheit_VersorgungsMaschine, Gebaeude_BauMaschine, Gebaeude_ProduktionsMaschine, Pop_MoodMaschine, Welt_TageszyklusMaschine, Welt_FortschrittsMaschine, Welt_ProgressionsMaschine, Tier_Status, Orchestrator_Status, Kern_ModifikatorMaschine, Ui_BauAuftragMaschine) wird auf genau eine Verantwortung geprüft: Zustandsfelder, Übergänge, ob sie fremde Domänen-Logik anfassen. E023 ist die bereits existierende Schranke.

Schritt A3: Datenfluss-Audit. Für jeden der 14 JSON-Pools: Besitzer-Registry, alle Leser, alle Schreibstellen. Der Index (INDEX_DATEN.md) liefert den Soll-Stand, der Code die Wahrheit; jede Diskrepanz ist ein Befund mit Fundstellen-ID.

Schritt A4: Zeit-Audit. Kern_Weltuhr bleibt die einzige Uhr: Alle tick-Abonnenten, alle Time.get_*/OS.get_*-Funde (E012-Griffweise), alle create_timer-Flüchtige-Anzeigen (uebergang.gd:39-40, uebergang.gd als einziges erlaubtes SceneTreeTimer-Muster prüfen), alle Tween-Nutzungen (welt_landeplatz_anzeige.gd, Feedback-Spitzen). Ergebnis: Liste aller Zeitquellen mit Einordnung Simulation oder Effekt.

Schritt A5: Szenen-API-Inventar (Schwerpunkt). Für jede der 11 Szenen und ihre angeschlossenen Skripte:
1. Knotentyp und Eigentum: Was gehört fest zur Szene, was wird zur Laufzeit erzeugt (Renderer-Ebenen, Darsteller, HUD-Panels via PackedScene.instantiate, Overlays via preload().instantiate bzw. .new()).
2. Lebenszyklus: _ready-Reihenfolge, _enter_tree/_exit_tree-Paare, ob jede connect-Stelle eine is_connected-Wächter- und eine disconnect-Seite besitzt (ist der Fall bei Tier_Manager, Gebaeude_Manager, Einheit_Manager, Welt_KarawanenManager, Welt_ProgressionsMaschine, Feedback_Manager, Lager_Darsteller, Pop_EinheitPanel, Welt_SchlagStaub).
3. Instanziierungsweg: add_child zum richtigen Elternknoten, einrichten()-Pflicht nach dem Einfügen, get_node_or_null-Schutz an jedem Kreuz-Szenen-Zugriff.
4. Eingabe-Kanäle: _input, _unhandled_input, gui_input je Szene, und ob die Steuerungs-InputMap aus steuerung.json die einzige Quelle bleibt (Kern_SteuerungRegistry.inputmap_registrieren als einzige Schreibstelle, Rückfall ui_left/ui_right im Karten-Editor dokumentiert).
5. Darstellungstrennung: Ob die Szene nur liest und der Renderer der einzige Knoten-Erzeuger der Welt bleibt.

Schritt A6: Bestandsaufnahme der Altlasten-Kandidaten: control.tscn (leere Control-Szene im Stamm, kein Skript, kein Verweis im Suchlauf), import-Restdateien wie icon.svg.import, legendäre Legacy-Datei world/data/standard_welt.json (Editor-Demo-Raster, bewusst kein Generator-Wahrheit, aber Streichkandidat auf dem Prüfstand), tool-Skripte, die nur für einzelne Beweise existieren, und die geänderten Dateien aus dem Arbeitsstand (core/data/kern_logik.json, core/data/kern_modifikatoren.json, tools/lauf_sonde_verwaiste.gd, tools/lauf_sonde_welt_szene.gd).

## 3. Mess-Schicht B: Wie gemessen wird (werkzeuggetreu, ohne Doppelbau)

Schritt B1: Statische Läufe, alles read-only: python tools/preflight.py (volle 19 Kategorien), python tools/preflight.py --kategorie warnungen (E025 als Godot-Warnspiegel), python tools/preflight.py --kategorie determinismus, --kategorie lokregel (E041: LOC-Grenzen, Nachlassliste tools/preflight/locregel_nachlass.json), python tools/index_generieren.py und Abgleich der vier Index-Dateien als Soll-Spiegel.

Schritt B2: Lauf-Beweise headless (godot --headless --script), jeder Einzelbeweis als Existenznachweis, keine Freigabe (Regel 9 verlangt zusätzlich die sichtbare Ingame-Verifikation): tools/lauf_pruefung_hud.gd, lauf_pruefung_welt.gd, lauf_pruefung_wasser.gd, lauf_pruefung_sozial.gd, lauf_pruefung_makrokarte.gd, lauf_pruefung_progression.gd, lauf_pruefung_determinismus.gd, lauf_pruefung_gesten.gd, lauf_pruefung_lader_sichtbar.gd, lauf_sonde_welt_szene.gd, lauf_sonde_verwaiste.gd, lauf_sonde_szene_kreis.gd.

Schritt B3: Neue read-only Sonden (nur wenn B2 eine Frage offen lässt, jede als eigene tools/lauf_sonde_*.gd-Datei nach dem Muster der Verwaisten-Sonde):
1. connect-Ledger-Sonde: Zählt bei jedem Manager connect, Wächter, disconnect und prüft die Paar-Symmetrie, ohne etwas zu ändern.
2. Verwaisten-Delta-Sonde über vollen Szenen-Zyklus (Hauptmenü, Welt-Map, Welt, zurück): Misst OBJECT_ORPHAN_NODE_COUNT an jeder Kante, um das 520-Verwaiste-Signal aus dem Spieler-Monitor auf die Quelle zu führen.
3. Frame-Zeit-Sonde über 600 Rahmen: misst Weltuhr-Rückstand-Meldungen (push_warning im Uhr-Rahmen), sichtbare Kachel-Sprite-Anzahl und Darsteller-Bestand, um Rahmen-Spitzen auf die Sichtbarkeits-Scheibe zurückzuführen.

Schritt B4: Pytest-Spiegel: python -m pytest (132 Fälle) als Vertrags-Lauf, jede neue Erkenntnis wird als Befundzeile im Bericht verankert, aber kein Test wird während der Bestandsaufnahme umgeschrieben.

## 4. Szenen-API-Konformität: Ist-Bild und Bewertungsregeln

Der Projekt-Konsens aus Architektur.md ist ein eigener Szenen-API-Stil, der bewusst von der Godot-Editor-Doktrin abweicht: Szenen sind dünne Ansichten, die Logik steht in plain-Klassen ohne Node-Basis, die Szene stempelt sie und ruft einrichten(); Autoloads tragen Kurz-Globalnamen, Klassen tragen Präfixe; der Renderer erzeugt Weltknoten, Panels sind PackedScene-Beobachter. Bewertet wird deshalb nicht an "typischem Godot-Stil", sondern an der internen Vertragslinie, plus an echten Engine-Risiken.

Konform befundet (Ist, aus dem Code gelesen):
1. Knoten-Erzeugung liegt beim Renderer mit Faulbau- und Sichtgebiet-Schichten; Kacheln tragen ihre Adresse im Namen statt in einem Index-Buch.
2. Panels als PackedScene mit instantiate + einrichten + _ready-Garantie + get_node_or_null-Schutz; Debug-Panels setzen set_process nach Sichtbarkeit, unsichtbare Beobachter lesen nichts.
3. Tick-Ordnung: genau ein globaler Tick, Manager verbinden mit Wächter und trennen in _exit_tree; die Szene verbindet ausschließlich den Tageszyklus.
4. Flucht-Pfade: change_scene_to_file nur in den drei Kanten Hauptmenü, Welt-Map, Uebergang; WeltSitzung als zustandsloser Verweis-Träger zwischen den Szenen.

Bewertungsregeln für Befunde (jeder Fund fällt unter genau eine Regel):
1. R1 Lebenszyklus-Lücke: connect ohne disconnect, _ready ohne Schutz, Knoten ohne Besitzer (Beweis: Verwaisten-Sonde).
2. R2 Zweite Wahrheit: Logik in der Szene, zweiter Takt, zweites Datenlesen neben der Registry, Frame-Polling statt Signal.
3. R3 Eingabe-Doppelkanal: _input und _unhandled_input fangen dasselbe Ereignis, oder ein Kanal umgeht die InputMap aus steuerung.json.
4. R4 Renderlast: Knoten oder Frame-Arbeit außerhalb der Sichtbarkeits-Scheibe, ohne Beweis, dass sie gebraucht werden.
5. R5 Altlast: Datei oder Szene ohne Verweis, ohne Beweislauf, ohne Verbraucher (control.tscn als aktueller Kandidat).

## 5. Hotspot-Register: Wo die Verletzungsquellen sitzen und wie sie entschärft werden

Jeder Eintrag trägt Ort, Befundregel, Risiko und die Entschärfung. Die Entschärfung selbst bleibt Umbau-Arbeit nach der Bestandsaufnahme, hier steht nur der Plan.

1. Hotspot H1, Regel R4, welt_renderer.gd: Kachel-Sprites als einzelne Sprite2D-Knoten je Kachel (Kachel_X_Y im Fliesen-Knoten), auch im Sichtgebiet-Zuschnitt zahlreich. Risiko: Knotenzahl und Frame-Zeit auf großen Karten. Entschärfung: Messen mit der Frame-Zeit-Sonde; Schwelle erst nach Zahlen entscheiden; Alternative wäre eine TileMap-artige Batch-Schicht oder MultiMesh, aber erst wenn die Messung sie fordert. Bewusst kein Umbau ohne Messbefund.
2. Hotspot H2, Regel R1, Renderer- und Panel-Instanzierung: kachel_erneuern_fuer_chunk erzeugt Sprites per add_child ohne is_instance_valid-Wächter, die UI-Aufbau- und HUD-Panels stapeln instantiate + add_child über mehrere Stellen (welt_ui_aufbau.gd, hud_debug_panel.gd, welt.gd Zeile 123). Risiko: Verwaiste Knoten (520-Signal aus dem Monitor, die Verwaisten-Sonden suchen die Quelle). Entschärfung: connect-Ledger- und Verwaisten-Delta-Sonde laufen lassen, Fundstellen benennen, dann je Quelle entweder queue_free-Disziplin oder Elternwechsel; die eine Kartenwahrheit und die Instanz-Übernahme (model_uebernehmen) bleiben unangetastet.
3. Hotspot H3, Regel R3, Eingabe-Kanäle: welt.gd trägt _input und _unhandled_input parallel (Eingabe-Steuerung als Übersetzer), der Karten-Editor liest Kamera-Richtung in _process über die InputMap mit ui_-Rückfall. Risiko: Doppelverarbeitung desselben Ereignisses oder Umgehung der Steuerungs-JSON. Entschärfung: Kanal-Matrix je Aktion aus steuerung.json prüfen (welche Aktion auf welchem Kanal), Rückfall nur als dokumentierter Notpfad belassen oder in die Steuerungs-Registrierung ziehen.
4. Hotspot H4, Regel R2, Frame-Poller: einheit_panel.gd und tier_panel.gd pollesen Beobachter-Zeilen je Frame, wenn sichtbar (bewusst mit set_process-Disziplin), ui_auswahl_markierung.gd, welt_bau_geist.gd, welt_landeplatz_anzeige.gd und welt_sonnen_effekt.gd laufen in _process für Effekt-Interpolation, karten_editor.gd und welt.gd bewegen Kamera und Sichtscheibe im Frame. Risiko: Zweite Zeitwahrheit neben der Weltuhr für Effekte, unbewachter Frame-Aufwand. Entschärfung: Für reine Effekte bleibt der _process-Weg nach Architektur.md 6b legal, solange kein Zustand geändert wird; geprüft wird nur, ob jede _process-Stelle wirklich nur darstellt. Frame-Poller der Panels sind bewusst, wenn die Messung sie als spürbar zeigt, auf Sichtbarkeits-Takt umstellen (Takt-Abonnement aus der Weltuhr, kein eigener Timer).
5. Hotspot H5, Regel R1, Signallandschaft: 66 Signal-Deklarationen, 159 connect-Stellen, verteilt über Manager, Szene, Panels und Werkzeuge. Risiko: Verlorene Verbindungen bei Szenenwechsel, Doppelverbindungen nach Erweiterung. Entschärfung: connect-Ledger-Sonde als Bestandsaufnahme, dann je Domäne die Paar-Symmetrie (Wächter und Gegenstelle) nennen; Werkzeug-Skripte bleiben außerhalb der Spiel-Verbindungsregeln, werden aber als Werkzeug markiert.
6. Hotspot H6, Regel R5, Altlast control.tscn: leere Control-Szene im Projektstamm, ohne Skript, ohne Verweis in Szenenwechsel, Instanzierung oder Tests. Risiko: Kein Laufzeitrisiko, aber eine unbetreute Datei, die in jedem Inventar als unerklärte Spitze auftaucht. Entschärfung: Streichen im Schnitt-Plan (Abschnitt 6), nach Bestätigung durch die Nutzerin; bis dahin bleibt sie nur dokumentiert.
7. Hotspot H7, Regel R2, Tag/Nacht-Doppelpfad-Restbestand: tageszyklus_overlay.gd verbindet phase_geaendert selbst, welt_sonnen_effekt.gd, welt_papier_licht.gd und welt_papier_korn_ebene.gd je über die Verdrahtung. Risiko: Eine zweite Verbindungsstelle neben der gesetzten Regel (Szene verbindet ausschließlich den Tageszyklus) ist entweder ein bewusster Beobachter oder ein Befund. Entschärfung: Inventar-Eintrag je Stelle mit Einordnung; die Maschine selbst bleibt die einzige Phasen-Quelle.
8. Hotspot H8, Regel R1, Autoload-Zugriff: get_node_or_null("/root/Weltuhr") und baum.root.get_node_or_null stehen neben dem statischen Weltuhr.bus()-Weg. Risiko: Zwei Zugriffswahreheiten für denselben Autoload, Headless-Läufe ohne Autoload scheinen gesondert behandelt. Entschärfung: Ein Pfad bleibt Vertrags-Weg (statisch bus()), die get_node_or_null-Stellen werden als Beweis-Notwege markiert oder auf bus() gezogen; die Weltuhr bleibt unangetastet als Basis der Pyramide.
9. Hotspot H9, Regel R4, Async-Chunk-Lader und Wasser-Automat: schrittweise Füllung im _process von welt.gd plus Weltuhr-Abos im Wasser-Automat. Risiko: Arbeit im Frame und im Tick ohne sichtbare Trennung. Entschärfung: Messen, wie viele Rahmen die Füllung braucht, und die Trennung dokumentieren (Füllung ist Darstellungsvorbereitung, kein Simulationszustand), dann in Architektur.md Abschnitt 5b festhalten.

## 6. Schnitt-Plan: Wo gestrichen wird (der letzte Schritt, nur nach der Inventur)

Die Streich-Liste entsteht erst aus den Befunden; Kandidaten heute, jeder mit Streich-Bedingung:
1. control.tscn: Streichen, wenn die Verwaisten-Delta-Sonde und der Verweis-Scan keinen Verbraucher zeigen und die Nutzerin zustimmt (Befund H6).
2. world/data/standard_welt.json: Bleibt, solange der Karten-Editor im Kreativmodus sein Demo-Raster daraus lädt; Streich-Kandidat erst, wenn der Editor sein Beispiel aus dem Generator zieht.
3. Doppelte Beweis-Skripte: lauf_sonde_verwaiste.gd und lauf_sonde_welt_szene.gd messen überlappend; nach der Bestandsaufnahme bleibt die ehrlichere (die Welt-Szene-Sonde) und die gerichtete wird um die fehlende Messstelle ergänzt oder gestrichen.
4. Werkzeug-Skripte ohne Befundwert: Jedes lauf_*-Skript wird in der Inventur mit seiner letzten Beweis-Aussage gelistet; Skripte, die keinen Vertragswert mehr tragen, wandern in den Streich-Vorschlag, nicht in den stillen Löschkorb.
5. Nicht-Streich-Regel: Die LOC-Nachlassliste (E041) darf keine Streichung erzwingen, die einen Beweis trägt; Nachlass-Einträge werden in der Bestandsaufnahme als solche markiert, nicht als Schulden.

## 7. Reihenfolge und Endprodukt (Arbeits-Schritte als Checkliste)

1. Schritt 1, Statisch: Preflight voll, Index neu erzeugen, Ist-Tabellen A1 bis A6 füllen.
2. Schritt 2, Lauf-Beweise: Alle bestehenden lauf_*-Beweise headless ausführen, Ergebnisse je Beweis notieren.
3. Schritt 3, Sonden: Fehlende Sonden nach B3 ergänzen und ausführen (neue Dateien, read-only im Spielverhalten, sie ändern nichts).
4. Schritt 4, Befund-Register: Jeder Fund unter Fundstellen-ID, Regel R1 bis R5, Hotspot H1 bis H9; jeder leere Bereich als "geprüft und leer" vermerkt.
5. Schritt 5, Bericht: Ein Dokument (Bestandsaufnahme-Bericht) mit Ist-Bild, Szenen-API-Konformität je Szene, Hotspot-Register, Entschärfungen und Schnitt-Vorschlag, plus einem Ingame-Verifikations-Nachweis je behauptetem Verhalten (Regel 9).
6. Schritt 6, Übergabe: Der Bericht wird die Grundlage für die folgenden Umbau-Slices; jeder Umbau-Slice bekommt eigene Tests, eigenen Beweislauf und eigenen Shinon-Commit.

Die Bestandsaufnahme selbst endet mit dem Bericht. Kein Code wird im ersten Durchgang geändert; wo der Plan Umbauten nennt, steht das Wort Entschärfung als Zielbild, nicht als erledigte Arbeit.

Version: V0.02
