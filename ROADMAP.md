# SnipWarfare — Globale Konsolidierte Roadmap & Master-Plan

Dieses Dokument ist die **einzige verbindliche Planungs- und Roadmap-Quelle** für SnipWarfare. Es konsolidiert alle historischen Befunde, Inventuren, Wirkungsketten und Vision-Dokumente (`Inventur_Stand.md`, `BEFUND.md`, `ODO_GAMEPLAY_WIRKUNGS.md`, `Fundliste_Sortierung_Und_Plugins.md`, `Fundliste_Ingame_Befunde.md`, `VISION_UND_TRANSFORMATION_ROADMAP.md`) in ein zentrales, strukturiertes Referenzwerk.

---

## 1. Systemstatus & Geprüfter Bestand

* **Engine:** Godot 4.7.2 (GL Compatibility)
* **Klassenbestand:** 162 Klassen auf 181 GDScript-Dateien
* **JSON-Datenpools:** 14 Pools (Wirtschaft, Bevölkerung, Welt, Jobs, Gebäude, Progression, Steuerung, Modifikatoren, Animationen)
* **Szenen:** 8 aktive `.tscn`-Szenen
* **Autoloads:** `Weltuhr` (`Kern_Weltuhr`, 24 Hz), `WeltSitzung` (`Ui_WeltSitzung`), `KernSignalBusAutoload` (`Kern_SignalBus`)
* **Testabdeckung:** 17/17 Pytest-Fälle grün, Preflight-Prüfung (Kategorien 1–16) grün (0 Befunde)

---

## 2. Historie & Abgeschlossene Checkpoints (Verifizierter Code-Stand)

Alle nachfolgenden Checkpoints sind im aktuellen Code implementiert, getestet und durch automatisierte Tests verifiziert:

### Kern-Architektur & Zeit (Core)
- [x] **CP-0.1 (Weltuhr):** `Kern_Weltuhr` in `core/logic/clock/weltuhr.gd` als alleiniger Simulationstakt (24 Ticks/s) mit Akkumulator-Schutz (`rahmen_budget()`) und Übersetzungsmethoden (`ticks_aus_faktor`, `ticks_aus_minuten`).
- [x] **CP-0.2 (Zufall):** `Kern_Zufall` als deterministischer Zufallskern; `abgeleitet_fuer` für Regionen und `abgeleitet_fuer_chunk` für Chunks (Ausschluss von Engine-RNG).
- [x] **CP-0.3 (Signalbus):** `Kern_SignalBus` als Event-Kanal mit `_emit`-Wrappern für Schaden, Tod, Menü-Events und Kannibalismus-Tatorte.
- [x] **CP-0.4 (Timeline):** `Kern_Timeline` für Ursprungs-Snapshots und Delta-Buchungen der Ressourcen; Anbindung an den "Warum"-Dialog im HUD.
- [x] **CP-0.5 (Modifikatoren):** `Kern_ModifikatorMaschine` und geteilte `Kern_ModifikatorRegistry.geteilte()` zur Berechnung von Geschwindigkeiten und Arbeitszeiten.
- [x] **CP-0.6 (Logik-Faktoren):** `Kern_LogikRegistry` liefert Basisfaktoren; `Objekt_Basis.effektiver_faktor()` skaliert Job-Erntezeiten (G1/G2-Verdrahtung).

### Welt, Generator & Multi-Map (World)
- [x] **CP-0.7 (Modell & Speicher):** `Welt_Model` als Datenanker mit Regionen, Chunks, autoritativem `welt_seed` und Speicherversion 5.
- [x] **CP-0.8 (Multi-Map-World):** `Welt_World` als Map-Container, `Welt_MapFabrik` für dynamische Expansion und `Welt_Speicher` für World-Savegames.
- [x] **CP-0.9 (Deterministischer Generator):** `Welt_Generator` mit `Welt_GeneratorVerteilung` und `Welt_GeneratorChunkPruefer`; Cluster-Stempelung für dichte Objektgruppen.
- [x] **CP-0.10 (Biom-Mutation):** `Welt_BiomManager` und `Welt_BiomRegistry` steuern Biom-Mutationen und Kachelfarben.
- [x] **CP-0.11 (Wärme & Tageszyklus):** `Welt_WaermeFeld` mit Kachel-Wärmequellen; `Welt_TageszyklusMaschine` direkt an Weltuhr angebunden; `needs.json` steuert Takt/Tag/Nacht.

### Wirtschaft & Gebäude (Economy & Buildings)
- [x] **CP-0.12 (Gebäude-Maschinen):** `Gebaeude_BauMaschine` und `Gebaeude_ProduktionsMaschine` gesteuert über `Gebaeude_Manager`; atomare Ressourcenbuchung mit Rollback-Schutz.
- [x] **CP-0.13 (Lager-System):** `Lager_Manager` mit Mutationsklassen `Lager_MutationEinlagern`/`Lager_MutationEntnehmen`; Bestände werden ortsabhängig geführt.
- [x] **CP-0.14 (Ressourcen-Plugin-Naht):** `game/data/ressourcen.json` instanziiert Klassen deklarativ über das `script`-Feld (`Ressource_Raeuchelfleisch`, `Ressource_Werkzeug`, etc.).

### Bevölkerung, Jobs & Steuerung (Game, Population, UI)
- [x] **CP-0.15 (Einstiegs-Progression):** `Welt_FortschrittsMaschine` steuert Stufen (Lagerfeuer -> Erstes Haus -> Einwanderung) basierend auf `progression.json`.
- [x] **CP-0.16 (Wegplanung & A*):** `Einheit_WegPlanung` integriert `Kern_PathFinder`, A*-Netz und Cache ohne Frame-Drops.
- [x] **CP-0.17 (Job-Queue & Autonomie-Grundstein):** `Einheit_Status` mit eigener Auftrags-Warteschlange; `kannibale`-Job als Notfall-Eskalation bei extremem Hunger.
- [x] **CP-0.18 (Bedürfnis-System):** `Pop_NeedBaum`, `Pop_MoodMaschine` und `Pop_MoodModifikatorRegistry` mit Schwellwert-Steuerung.
- [x] **CP-0.19 (UI-Panels & Übersetzung):** `Ui_EingabeSteuerung`, `Ui_KameraSteuerung`, `Ui_BauPanel`, `Ui_EinheitPanel`, `Ui_TierPanel` und zielgefiltertes Kontextmenü.

---

## 3. Zielbild: Die RimWorld-Einstiegskette in SnipWarfare

1. **Makro-Start:** Der Spieler wählt auf einer echten Kontinent-Makrokarte einen Startbereich aus vielen Regionen.
2. **Landeplatz:** Auf der lokalen Karte erscheint ein sichtbarer Landeplatz am Zentrum; das Platzieren des Lagerfeuers ist die erste Aktion.
3. **Startvorrat & Wärme:** Das Lagerfeuer aktiviert Wärme, schaltet das Bau-Panel frei und nimmt den Startvorrat auf.
4. **Blueprint-Bauen:** Gebäude entstehen als Bauplan; Siedler tragen zuerst Material heran (`Job_BaustelleBeliefern`), bevor die Bauarbeit beginnt.
5. **Direktsteuerung & Auswahl:** Der aktive Siedler trägt einen goldenen Stern; Rechtsklick führt Jobs direkt am Klickort aus oder erteilt Marschbefehle.
6. **Autonomie:** Unbeschäftigte Siedler gehen autonom zum Lagerfeuer, transportieren Baustellen-Material oder setzen frühere Aufgaben fort.
7. **Eskalation & Moral:** Hunger/Kälte/Hitze eskalieren nachvollziehbar; Verzweigungen über Spielergrundsätze (`Pop_MoralInstanz`) und Traits (z. B. "Mag kein Papier").
8. **Ökonomie:** Bergbau an Felsmassiven liefert Erze, die in Schmelze und Schmiede zu Barren und Werkzeugen verarbeitet werden.

---

## 4. Zukünftige Checkpoints je Slice

### Slice 1: Aufräumen und Entdoppeln (Vorarbeit & Gating)
- [ ] **CP-1.1:** Gating-Wahrheit (`gesperrt_ab_stufe`) vollständig in `world/data/gebaeude.json` verankern; Steuerungskonfiguration bereinigen.
- [ ] **CP-1.2:** Deklarative `ziel_tags` in `world/data/element_katalog.json` und `game/data/steuerung.json` einführen; feste String-Vergleiche im Kontextmenü ersetzen.
- [ ] **CP-1.3:** Debug-Overlay in eigenständiges `Ui_DebugPanel` auslagern (F3-Umschaltung, Standard: unsichtbar).
- [ ] **CP-1.4:** Doppelte Produktionsstatuszeile im HUD eliminieren.
- [ ] **CP-1.5:** Preflight und alle Tests nachweislich grün halten.

### Slice 2: Maßstab und Terrain (Micro-Tiles & Tiefenschärfe)
- [ ] **CP-2.1:** Kachelgröße datengetrieben auf 64 px kalibrieren; alle statischen Konstanten (`Welt_Model.KACHEL_GROESSE`) im Renderer durch `_model.kachel_groesse` ersetzen.
- [ ] **CP-2.2:** Terrain-Datenpool `world/data/terrain.json` anlegen (`wasser`, `ufer`, `geroell`, `fels`, `waldboden`, `acker`, `weg`, `sand`).
- [ ] **CP-2.3:** `Welt_TerrainBlatt` zur deterministischen Varianten- und Spiegelungswahl je Kachel-Koordinate implementieren.
- [ ] **CP-2.4:** `y_sort_enabled` im `Welt_Renderer` aktivieren; Sprite-Ursprünge auf Fußpunkte setzen (korrekte Überdeckung von Bäumen und Felsen).

### Slice 3: Landschaft (Gewässer, Felsmassive, Erzadern & Ruinen)
- [ ] **CP-3.1:** `Generator_Gewaesser` für deterministische Teiche, Flüsse und Uferzonen aus dem Seed implementieren.
- [ ] **CP-3.2:** `Generator_Felsmassive` für zusammenhängende Klippen und Abbauzonen integrieren.
- [ ] **CP-3.3:** Neue Weltobjekt-Klassen: `Objekt_Berg`, `Objekt_Felswand`, `Objekt_Erzader`, `Objekt_Ruine`, `Objekt_Steinkreis`.
- [ ] **CP-3.4:** Cluster-Definitionen in `world/data/generator_gewichte.json` für Ruinen und dichte Wälder erweitern.

### Slice 4: Weltkarte und Einstieg (Makro-Domäne)
- [ ] **CP-4.1:** Eigene Makro-Domäne `world/data/weltkarte_definition.json` und `Welt_MakroGenerator` (kein Aufruf des lokalen Generators beim Betrachten der Weltkarte).
- [ ] **CP-4.2:** Minimaler Startbereich (1 Region unter vielen) mit duplikatfreiem Fraktionsnetzwerk.
- [ ] **CP-4.3:** `Welt_LandeplatzAnzeige` zur visuellen Markierung des Startplatzes; Startvorrat aus `gebaeude.json` beim Entzünden des Lagerfeuers einbuchen.

### Slice 5: Bauen und Logistik (Blueprint & Materialtransport)
- [ ] **CP-5.1:** Bauplan-Zustand `BAUPLAN` im `Welt_Model` mit Materialbedarf; keine Vorab-Abbuchung der Baukosten.
- [ ] **CP-5.2:** `Welt_BaustellenBedarf` (Bedarfsermittlung) und `Job_BaustelleBeliefern` mit `Einheit_TransportMaschine`.
- [ ] **CP-5.3:** `Gebaeude_BauMaschine` startet Baufortschritt erst nach vollständiger Materiallieferung.
- [ ] **CP-5.4:** `Welt_BauGeist` zur halbtransparenten Blueprint-Darstellung mit visualisiertem Bedarfsbalken.
- [ ] **CP-5.5:** Rechtsklick-Priorisierung von Baustellen-Aufträgen in der Einheiten-Queue.

### Slice 6: Auswahl, Direktklick und Autonomie
- [ ] **CP-6.1:** `Ui_AuswahlMarkierung` (goldener Stern über der selektierten Einheit).
- [ ] **CP-6.2:** Linksklick-Semantik: Einzelauswahl bei Klick, Abwahl bei Klick ins Leere, Erhalt der Rechteckauswahl.
- [ ] **CP-6.3:** Rechtsklick-Direktjob: Sofortige Jobvergabe mit Leerung der Altaufträge; Marschbefehl auf freiem Boden.
- [ ] **CP-6.4:** Autonome `Einheit_VerhaltenMaschine` mit `game/data/autonomie.json` für Idle-Siedler (Lagerfeuer -> Baustellentransport -> Jobfortsetzung).

### Slice 7: UI und Rahmung
- [ ] **CP-7.1:** Vollwertiges `Ui_BauPanel` mit Blueprint-Auswahl, Baukosten-Tooltips und Sperrstufen-Anzeige.
- [ ] **CP-7.2:** Kontextmenü filtert Aktionen strikt über `ziel_tags`.
- [ ] **CP-7.3:** Feste Bildrahmung: Feste Leistenaufteilung (Ressourcen oben, Bauen unten, Status links).
- [ ] **CP-7.4:** Eventbasierte UI-Aktualisierung: Polling in `_process` durch Signal-Abonnements ablösen.

### Slice 8: Eskalation, Traits, Vorlieben und Lernen
- [ ] **CP-8.1:** Eskalations-Ereignisse der `Pop_MoodMaschine` an `Kern_Timeline` melden und im Warum-Fenster visualisieren.
- [ ] **CP-8.2:** `Pop_MoralInstanz` für spielergesteuerte Kolonie-Grundsätze (z. B. Kannibalismus-Verbot).
- [ ] **CP-8.3:** `population/data/traits.json`, `Pop_Trait` und `Pop_TraitRegistry` (inkl. Trait "Mag kein Papier" als Verhaltensblocker).
- [ ] **CP-8.4:** `population/data/vorlieben.json` und `Pop_Vorliebe` für individuelle Arbeits- und Nahrungsvorlieben.
- [ ] **CP-8.5:** Dynamisches Mood-Gedächtnis (`Pop_MoodGedaechtnis`) als Erfahrungs-Gewichtung für autonome Entscheidungen.

### Slice 9: Ökonomie (Erze, Schmelze, Schmiede & Werkzeuge)
- [ ] **CP-9.1:** Neue Ressourcen: `erz_eisen`, `erz_kupfer`, `erz_kohle`, `barren_eisen` in `ressourcen.json`.
- [ ] **CP-9.2:** Produktionsgebäude `schmelze` (Erz -> Barren) und `schmiede` (Barren -> Werkzeug) in `world/data/gebaeude.json`.
- [ ] **CP-9.3:** Stufenweiser Erzabbau über `world/data/ressourcen_progression.json`.
- [ ] **CP-9.4:** Werkzeugausrüstung senkt `harvest_zeit_ticks` aller handwerklichen Jobs spürbar.

### Slice A: Qualitätssicherung & Release-Gate
- [ ] **CP-A.1:** Pytest-Suite deckt alle neuen Datenpools und Registry-Nähte ab.
- [ ] **CP-A.2:** Voller Preflight (`python tools/preflight.py`) meldet 0 Befunde.
- [ ] **CP-A.3:** Headless-Laufbeweis `tools/lauf_pruefung_welt.gd` bestätigt alle Verhaltensketten.
- [ ] **CP-A.4:** Ingame-Verifikation nach Regel 7 im laufenden Spiel bestätigt.

---

## 5. Anti-Patterns & Verbindliche Verbote ("Nicht tun")

1. **Kein Lieferzustand in der Bau-Maschine:** Logistik und Bauzeit sind zwei getrennte Domänen; Materialtransport ist ein Job (`Job_BaustelleBeliefern`), nicht Teil von `Gebaeude_BauMaschine`.
2. **Keine doppelte Kachelgröße:** Weder Konstanten im Code noch abweichende Szenenwerte; einzige Wahrheit ist `model.kachel_groesse` aus `welt_definition.json`.
3. **Kein lokaler Generator auf der Weltkarte:** Die Makrokarte generiert nur das Makroraster.
4. **Keine hardcodierten Namen in der UI:** Alle Gebäudenamen, Kosten, Sperrstufen und Filterkriterien stammen aus JSON-Dateien.
5. **Kein zweiter Simulationstakt:** Keine Timer, kein Fachcode in `_process`, keine autonome Domänenzeit; alles läuft über `Kern_Weltuhr`.
6. **Keine Verletzung der Datenkapselung:** Kein direkter Zugriff auf fremde Arrays (`_einheiten`, `_job_queue`, `_objekte`); Nutzung der öffentlichen API.
7. **Keine toten Systeme:** Jedes System muss im Spiel sichtbar oder bedienbar enden (Regel 7).

---

## 6. Ein-Befehl-Schnellzugriff (1-Command Navigation)

Alle Qualitäts-, Status- und Testprüfungen des Projekts lassen sich mit einem einzigen Befehl aufrufen:

```bash
python tools/preflight.py
```

* **Vollprüfung:** Führt alle 16 Prüfkategorien (Naming, Trennung, Determinismus, Registries, Godot-Headless, Warnungs-Scan, Shinon Gate) aus.
* **Scope-Gezielt:**
  * `python tools/preflight.py --kategorie warnungen` (GDScript-Warnungs-Scan nach Regel 6)
  * `python tools/preflight.py --kategorie shinon` (Shinon Gate Prüfung E030–E039)
  * `python tools/preflight.py --kategorie godot` (Headless Engine-Kompilierung)
* **Unittests:** `python -m pytest` führt alle 17 Unittests aus.
