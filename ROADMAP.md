# SnipWarfare — Globale Konsolidierte Roadmap & Master-Plan

Dieses Dokument ist die **einzige verbindliche Planungs- und Roadmap-Quelle** für SnipWarfare. Es konsolidiert alle historischen Befunde, Inventuren, Wirkungsketten und Vision-Dokumente (`Inventur_Stand.md`, `BEFUND.md`, `ODO_GAMEPLAY_WIRKUNGS.md`, `Fundliste_Sortierung_Und_Plugins.md`, `Fundliste_Ingame_Befunde.md`, `VISION_UND_TRANSFORMATION_ROADMAP.md`) in ein zentrales, strukturiertes Referenzwerk.

---

## 1. Systemstatus & Geprüfter Bestand

* **Engine:** Godot 4.7.2 (GL Compatibility)
* **Klassenbestand:** 227 Klassen auf 251 GDScript-Dateien — Inventar siehe [`INDEX.md`](INDEX.md) via `python tools/index_generieren.py`
* **JSON-Datenpools:** 14 Pools (Wirtschaft, Bevölkerung, Welt, Jobs, Gebäude, Progression, Steuerung, Modifikatoren, Animationen)
* **Szenen:** 11 aktive `.tscn`-Szenen
* **Indizes:** `INDEX.md` als Wurzel, `INDEX_DOMAENEN.md` mit der Signal- und Array-Matrix je Domäne, `INDEX_DATEN.md` mit jedem JSON-Pool samt Besitzer und Verbrauchern und die eine Last-Datei `INDEX_LETZTE_AENDERUNG.md`, alle vier von `python tools/index_generieren.py` erzeugt und von der Prüfkategorie `index` (E044) bewacht
* **Autoloads:** `Weltuhr` (`Kern_Weltuhr`, 24 Hz), `WeltSitzung` (`Ui_WeltSitzung`), `KernSignalBusAutoload` (`Kern_SignalBus`)
* **Testabdeckung:** 85/85 Pytest-Fälle grün, Preflight-Prüfung (Kategorien 1–19 inkl. Whitespace E042, Version E043 und Index E044) grün (0 Befunde), dazu die Laufbeweise `tools/lauf_pruefung_hud.gd` und `tools/lauf_pruefung_makrokarte.gd`

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
- [x] **CP-0.15 (Index-Familie):** `python tools/index_generieren.py` erzeugt vier Indizes aus dem Code: `INDEX.md` mit der Index-Familie und dem Klasseninventar, `INDEX_DOMAENEN.md` mit der Signal-Matrix (Deklaration D, Senden S, Verbinden V) und der Array-Matrix (`Array[Typ]` je Domäne), `INDEX_DATEN.md` mit jedem JSON-Pool samt Besitzer, Schluesseln und namentlichen Verbrauchern sowie die eine Last-Datei `INDEX_LETZTE_AENDERUNG.md`, die den Delta des letzten Laufs mitschreibt. Das Paket liegt granular in `tools/index/` (kern, inventar, matrix, daten, root_index, domaenen_index, daten_index, letzte_aenderung, erzeugen), die Prüfkategorie `index` (E044) vergleicht jede Datei mit dem Code und meldet Abweichungen mit Datei und Zeile.

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
9. **Fraktionen und Handel:** Auf der Makrokarte leben Fraktionen mit Siedlungen, die als Außenposten beginnen und zu Städten wachsen; Karawanen transportieren in Echtzeit Waren zwischen ihnen, Handel verändert Beziehungen, und Konflikte eskalieren zu Schlachten, die als vorbereitete Animation am Spieltisch abgespielt werden.

---

## 4. Zukünftige Checkpoints je Slice

### Slice 1: Aufräumen und Entdoppeln (Vorarbeit & Gating) — abgeschlossen
- [x] **CP-1.1:** Gating-Wahrheit (`gesperrt_ab_stufe`) liegt vollständig in `world/data/gebaeude.json`; die Steuerung trägt keine Bau-Aktionen mehr. Beweis: `test_einstiegs_progression.py`.
- [x] **CP-1.2:** `ziel_tags` in `world/data/element_katalog.json` (baum, baum_stumpf, kadaver, stein, steine_gruppe, busch, alle fünf Tiere) und `game/data/steuerung.json` (sammeln, abbauen, marschieren); `KontextMenue` vergleicht nur noch Tag-Schnittmengen, die neuen Aktionen `marschieren` und `ziel_tags_fuer` lösen die harten `contains`-Vergleiche ab. Beweis: `test_datengetriebene_naht.py`.
- [x] **CP-1.3:** Debug-Overlay liegt als `Ui_DebugPanelSzene` (`ui/scenes/hud/hud_debug_panel.gd`) in der UI-Ebene, hält Einheit- und Tierbeobachter, ist standardmäßig unsichtbar und folgt nur dem F3-Schalter. Beweis: `tools/lauf_pruefung_hud.gd`.
- [x] **CP-1.4:** Produktionszeile kommt als Signal `status_geaendert` aus dem `Gebaeude_Manager` und wird nur bei echter Änderung gemeldet; kein Frame-Polling mehr. Doppelbauten auf derselben Kachel verhindert `belegt_kachel` plus `_bauplatz_frei`. Beweis: `test_datengetriebene_naht.py`.
- [x] **CP-1.5:** 59 Pytest-Prüfungen grün, voller Preflight ohne Befund.
- [x] **CP-1.0 (nachgezogen):** HUD-Rahmen als `PanelContainer` mit Knopfzeile im selben Container; Statuszeilen und Knöpfe können sich strukturell nicht mehr überlagern. Beweis: `tools/lauf_pruefung_hud.gd` misst die Rechtecke (Rahmen 440x227, Knopfzeile bei y=200).

### Slice 2: Maßstab und Terrain (Micro-Tiles & Tiefenschärfe) — abgeschlossen
- [x] **CP-2.1:** Kachelgröße datengetrieben auf 64 px kalibriert (`world/data/welt_definition.json` ist die einzige Quelle); der Renderer liest `_model.kachel_groesse` für Position und Skalierung, `Welt_Model.KACHEL_GROESSE` steht dort nur noch als Rückfall für Testläufe ohne Definitions-Registry.
- [~] **CP-2.2:** Der Terrain-Pool liegt nicht in einer zweiten Datei, sondern im bestehenden `world/data/element_katalog.json`: die zehn Einträge mit `typ: kachel` tragen Textur, `varianten`, `spiegelbar` und `toenungen`. Eine eigene `terrain.json` wäre eine zweite Wahrheit derselben Bilder.
- [x] **CP-2.3:** `Welt_TerrainBlatt` (`world/logic/kategorie_welt/welt_terrain_blatt.gd`) wählt Spiegelung und Tönung je Kachelkoordinate deterministisch über `Kern_Zufall.abgeleitet_fuer`.
- [x] **CP-2.4:** `y_sort_enabled` in `Welt`, `Welt_Renderer`, `Tier_Manager` und `Einheit_Manager` hierarchisch aktiviert; Fliesen-Container fest im Hintergrund (`z_index = -1`); Fußpunkt-Ursprünge in `Einheit_Darsteller` und `Tier_Darsteller` kalibriert. Beweis: `test_y_sort_und_landeplatz.py`.
- [x] **CP-2.5 (nachgezogen):** Die zehn Kachelbilder unter `world/assets/terrain/kacheln/` sind importiert (64 px) und der Renderer malt fehlende Bilder als sichtbaren Platzhalter statt als Leerstelle.

### Slice 3: Landschaft (Gewässer, Felsmassive, Erzadern & Ruinen) — abgeschlossen
- [x] **CP-3.1:** `Welt_GeneratorGewaesser` für deterministische Teiche, Flüsse und Uferzonen aus dem Seed implementieren. Beweis: `test_landschaft_generatoren.py`.
- [x] **CP-3.2:** `Welt_GeneratorFelsmassive` für zusammenhängende Klippen und Abbauzonen integrieren. Beweis: `test_landschaft_generatoren.py`.
- [x] **CP-3.3:** Neue Weltobjekt-Klassen: `Objekt_Berg`, `Objekt_Felswand`, `Objekt_Erzader`, `Objekt_Ruine`, `Objekt_Steinkreis` samt SVG-Assets und Katalog-Registrierung. Beweis: `test_landschaft_objekte.py`.
- [x] **CP-3.4:** Cluster-Definitionen in `world/data/generator_gewichte.json` für Felsmassive, Erzlager, Ruinenfelder und Steinkreise erweitert. Beweis: `test_landschaft_generatoren.py`.

### Slice 4: Weltkarte und Einstieg (Makro-Domäne) — abgeschlossen
- [x] **CP-4.1:** Eigene Makro-Domäne `world/data/weltkarte_definition.json` (16 mal 12 Regionen) und `Welt_MakroGenerator`; die Weltkarte plant nur Regionen und ruft keinen lokalen Generator mehr. Beweis: `tools/lauf_pruefung_makrokarte.gd` (0 Objekte auf der Makrokarte, 192 Regionen).
- [x] **CP-4.2:** Startbereich ist eine Region unter vielen, wird deterministisch nahe der Mitte gewählt und meidet Barrieren; die Nachbarliste wächst bei erneuter Planung nicht. Beweis: derselbe Lauf über 12 Seeds.
- [x] **CP-4.3a:** Startvorrat: Das Lagerfeuer trägt `startbestand` in `world/data/gebaeude.json`, `Gebaeude_Manager._startbestand_einbuchen` bucht ihn über die vorhandene Ressourcen-Schnittstelle ins nächste Lager. Beweis: `test_makrokarte_und_barrieren.py`.
- [x] **CP-4.4 (Barrieren):** `gebirge` und `ozean` in `world/data/biome.json` mit `barriere: true`; Gewichte-Einträge tragen `ebene` (`lokal`/`makro`), die lokale Karte zieht nur lokale Biome, der `Welt_NetzwerkPlaner` meidet Barrieren für Fraktionen, Startbereich und Wege, `welt_map.gd` zeichnet Dreiecke und Wellen. Beweis: 560 Barriere-Regionen über 12 Seeds, kein Weg kreuzt eine Barriere.
- [x] **CP-4.3b:** Eigene `Welt_LandeplatzAnzeige` zur sichtbaren Markierung des Startplatzes auf der lokalen Karte; dezentes Atmen und Kanten-Rahmung, verblasst automatisch beim ersten Lagerfeuer. Beweis: `test_y_sort_und_landeplatz.py` und `tools/lauf_pruefung_hud.gd`.

### Slice 5: Bauen und Logistik (Blueprint & Materialtransport) — abgeschlossen
- [x] **CP-5.1:** Bauplan-Zustand `BAUPLAN` im `Welt_Model` mit Materialbedarf; keine Vorab-Abbuchung der Baukosten. Beweis: `test_baustellen_logistik.py`.
- [x] **CP-5.2:** `Welt_BaustellenBedarf` (Bedarfsermittlung) und `Job_BaustelleBeliefern` mit `Einheit_TransportMaschine`. Beweis: `test_baustellen_logistik.py`.
- [x] **CP-5.3:** `Gebaeude_BauMaschine` startet Baufortschritt erst nach vollständiger Materiallieferung. Beweis: `test_baustellen_logistik.py`.
- [x] **CP-5.4:** `Welt_BauGeist` zur halbtransparenten Blueprint-Darstellung mit visualisiertem Bedarfsbalken und Eckwinkeln. Beweis: `test_baustellen_logistik.py` und `tools/lauf_pruefung_hud.gd`.
- [x] **CP-5.5:** Rechtsklick-Priorisierung von Baustellen-Aufträgen in der Einheiten-Queue. Beweis: `test_baustellen_logistik.py`.

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

### Slice 10: Fraktionen und Siedlungen (Makro-Domäne)
- [ ] **CP-10.1:** Neue Domäne Fraktion als eigene Kategorie `military/` mit Prefix `Frakt_`: `Frakt_Basis` (Identität, Beziehungswerte, Grundsätze), `Frakt_Registry` und `Frakt_Manager`; die Makro-Domäne bleibt Eigentümerin der Regionswahrheit, die Fraktionsdomäne liest nur aus ihr.
- [ ] **CP-10.2:** `military/data/fraktionen.json` als Datenpool: Startregionen (deterministisch aus Weltseed über `Kern_Zufall.abgeleitet_fuer`, Barrieren-Meidung über den bestehenden `Welt_NetzwerkPlaner`), Beziehungswerte je Fraktionspaar und Grundsätze; keine zweite Erzeugungsstelle neben der `Welt_MapFabrik`.
- [ ] **CP-10.3:** `Frakt_SiedlungBasis` und `Frakt_SiedlungRegistry`: Eine Siedlung hängt an einer Region, trägt Name, Einwohnerzahl, Lagerbestand und Bauzustand; der Aufstieg Außenposten -> Dorf -> Stadt folgt Eskalationsstufen aus dem Datenpool (`military/data/siedlung_stufen.json`), nicht aus Code.
- [ ] **CP-10.4:** Siedlungswachstum als State-Maschine `Frakt_SiedlungWachstum` an der Weltuhr: Einwohner und Bestände ändern sich im Takt; Beobachter lesen nur über Snapshots.
- [ ] **CP-10.5:** Beweis: Headless-Laufprüfung `tools/lauf_pruefung_fraktionen.gd` über 12 Seeds (deterministische Platzierung, keine Barriere-Kreuzung) plus Pytest-Naht-Test über den Datenpool.

### Slice 11: Grenzüberschreitende Karawanen und Transporte (Verbindungsdomäne)
- [ ] **CP-11.1:** Neue Kategorie `logistic/` mit Prefix `Karw_`: `Karw_Basis` (Fracht, Start-Siedlung, Ziel-Siedlung, Fortschritt), `Karw_Manager` (Vergabe und Takt), `Karw_TransportMaschine` (Reisezustand an der Weltuhr).
- [ ] **CP-11.2:** `military/data/karawanen.json`: Reisegeschwindigkeit, Frachtkapazität, Begleitschutz-Bedarf und Eskalationsstufen für Überfälle je Landschaft; die Reisedauer rechnet ausschließlich über `Kern_Weltuhr.ticks_aus_faktor()`.
- [ ] **CP-11.3:** Karawanen sind die erste grenzüberschreitende Entität: Sie lesen Wegpunkte aus dem bestehenden `Welt_NetzwerkPlaner` (Barrieren-Meidung als einzige Wegwahrheit) und buchen Fracht ausschließlich über die bestehenden `Lager_MutationEinlagern`/`Lager_MutationEntnehmen` der beteiligten Siedlungen, kein zweiter Buchungspfad.
- [ ] **CP-11.4:** Sichtbare Darstellung: Karawanen erscheinen als Markierungen auf der Makrokarte (Vorbild `welt_map.gd`, zeichnend, ohne Simulationslogik); Ankunft und Abfahrt melden sich über den `Kern_SignalBus`.
- [ ] **CP-11.5:** Beweis: Pytest-Test über Frachtbuchung und Reisezeiten, Headless-Laufprüfung über mehrere Seeds; Ingame-Verifikation nach Regel 7 auf der Makrokarte.

### Slice 12: Handel zwischen Siedlungen (Wirtschafts-Verbindungsdomäne)
- [ ] **CP-12.1:** Neue Kategorie `logistic/` mit Prefix `Handel_`: `Handel_Angebot` (Angebot, Nachfrage, Preisrelation als Datenklasse), `Handel_Maschine` (Verhandlungszustand an der Weltuhr) und `Handel_Manager` (Abschluss und Buchung).
- [ ] **CP-12.2:** `military/data/handel.json`: Güterpreise je Siedlungstyp, Preisreaktion auf Bestände und Ereignis-Modifikatoren (Missernte, Krieg); Preisrelationen sind Eskalationsstufen aus Daten, nie hart codiert.
- [ ] **CP-12.3:** Handelsabschlüsse laufen als Karawanen-Transporte (Slice 11) und buchen über dieselben Lager-Mutationen; es gibt keinen zweiten Warenfluss neben der Ernte- und Produktionskette.
- [ ] **CP-12.4:** Beziehungsverbund: Jeder Abschluss verändert Beziehungswerte der Fraktionsdomäne (Slice 10) über die `Kern_ModifikatorMaschine` (Bereich `handel` als neuer Bereich in `modifikator_settings.json`), keine eigene Formel.
- [ ] **CP-12.5:** Beweis: Pytest-Test über Preisreaktionen und Lagerbuchungen; Ingame-Verifikation nach Regel 7 auf der Makrokarte.

### Slice 13: Kriegs-Sequenzen (Militär-Verbindungsdomäne)
- [ ] **CP-13.1:** Neue Kategorie `military/` mit Prefix `Krieg_`: `Krieg_KonfliktBasis` (Kontrahenten, Ursache, Truppenstärke), `Krieg_VorbereitungMaschine` (Truppen sammeln und Marsch an der Weltuhr), `Krieg_AufloesungMaschine` (Ergebnis, Verluste, Gebietsänderung).
- [ ] **CP-13.2:** `military/data/krieg.json`: Truppenstärken je Siedlungsstufe, Ausfälle je Landschaft, Beziehungs-Schwellen für Kriegserklärung; Auslöser sind Eskalationsstufen aus Daten, nie Code-Weichen.
- [ ] **CP-13.3:** Die Schlacht selbst ist eine vorbereitete Animation als Ingame-Sequenz: `Krieg_SchlachtSequenz` spielt eine datengetriebene Ablaufbeschreibung (`military/data/schlacht_ablauf.json`, Setup, Phasen, Wendepunkt, Ergebnis) über die 24 Ticks der Weltuhr ab; die Sequenz ist Darstellung, berechnet kein Fachergebnis.
- [ ] **CP-13.4:** Das Ergebnis rechnet die `Krieg_AufloesungMaschine` deterministisch aus Truppenstärke, Landschaft und Zufallswerten von `Kern_Zufall` (Seite reicht Seeds herein, kein eigener RNG); Verluste und Gebietsänderungen laufen als `Kern_Mutation` in die Fraktions- und Siedlungsdomäne.
- [ ] **CP-13.5:** Bespielbarkeit: Der Spieler kann jede eigene Siedlung wie eine Hauptkarte betreten (`Welt_MapFabrik` erzeugt die Region-Karte, genau eine Kartenwahrheit über `Welt_World`); Kriegsereignisse der Spieler-Kolonie melden sich über den `Kern_SignalBus` und die `Kern_Timeline` (Warum-Kette).
- [ ] **CP-13.6:** Beweis: Pytest-Test über deterministische Auflösung (gleicher Seed, gleiches Ergebnis), Headless-Laufprüfung der Sequenzphasen; Ingame-Verifikation nach Regel 7 mit sichtbarer Schlacht-Sequenz.

### Slice 14: Katzen, Bindung und Moral (Datenschritt zuerst)

Die Daten fragen zuerst, die Klassen folgen danach. Dieser Slice hält die Reihenfolge ein und bleibt in der bestehenden Tier- und Jobarchitektur: Die Katze ist eine Tierart wie jede andere, die Bindung ist ein Wert an der Einheit, die Moral moduliert nur die Zielwahl.

- [ ] **CP-14.1:** `world/data/tier_verhalten.json` erhält Katzen-Einträge mit den Feldern `id`, `name`, `sheet_pfad`, `fleisch`, `hp`, `trigger_radius`, `flucht_geschwindigkeit`, `ausloeser` (zum Beispiel `folgen`, `naeher_kommen`, `warten`), `logik_id`, `modifikator_id` (zum Beispiel `normal`, `bindungsbetont`, `wild`) und `faktor`. Die Datenklasse `Tier_Katze` wird über das `script`-Feld der Registry zugeordnet, kein neues Tier-System.
- [ ] **CP-14.2:** `population/data/bindung.json` als Datenpool: Bindung gehört zu einer Einheit, kann zu mehreren Katzen bestehen und trägt je Eintrag `katze_id`, `level`, `staerke`, `letzte_interaktion` und `verfall_je_takt` sowie optionale Schutzwerte. Lesen und Setzen läuft ausschließlich über eine Bindungs-Registry an der Weltuhr, nie über direkte Feldschreiber.
- [ ] **CP-14.3:** `world/data/moral_regeln.json` als Instanz der Kolonie-Grundsätze: `kannibalismus_erlaubt`, `tiere_bevorzugt`, `bindungsobjekt_geschuetzt`, `ersatzhandlung_bei_blockade` und `wirkung_je_rasse`. Die Moral blockiert keine Jagd, sie moduliert Zielwahl und Auswahl.
- [ ] **CP-14.4:** Die Zielwahl in `Einheit_VerhaltensMaschine.pruefe_verhalten` liest Moral und Bindung über klar definierte Lese-Schnittstellen: gebundenes Tier, moralisch gesperrter Nachbar, Ersatzhandlung statt Verzweiflungstat, notfalls bewusstes Verhungern. Die Ausführung bleibt unverändert in der Ernte-Maschine und der Job-Architektur.
- [ ] **CP-14.5:** Katzen lesen den Bindungs-Kontext über dieselbe Lese-Schnittstelle, niemals über hartkodierte Werte im Körpermuster; die Tier-Domäne bleibt unbelastet.
- [ ] **CP-14.6:** Die vorhandene `Pop_Denkblase` erzählt die moralische Verzweigung als Observer-Spitze (Bindung, Verzicht, Nachbarsstreit), ohne Logik zu tragen; Katzen erscheinen auf der Karte und die Bindung wird im Einheit-Panel sichtbar.
- [ ] **CP-14.7:** Eskalationsstufen und Folgekosten bleiben in `mood_modifikatoren.json` und den bestehenden Balance-Dateien (`needs.json`, `progression.json`, `steuerung.json`); die Balance-Läufe prüfen Nährstoffverbrauch, Einwanderungsraten, Jagd-Reichweite und Katzen-Nahrungsbeitrag über die vorhandenen Datenstellen statt über neue Konstanten.
- [ ] **CP-14.8:** Beweis: Pytest-Test über Bindungs-Aufbau und Moral-Blockade, Headless-Laufprüfung der Zielwahl, danach die sichtbare Ingame-Verifikation nach Regel 9 mit einer Katze auf der Karte und einer erzählenden Gedankenblase.

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
8. **Kein lokaler Generator für Siedlungen und Fraktionen:** Platzierung und Startzustand entstehen nur über Fraktions-Registry plus Datenpool und lesen den bestehenden Makro-Planer; es gibt keine zweite Erzeugungsstelle neben der `Welt_MapFabrik`.
9. **Kein Kriegsergebnis in der Animation:** Die Schlacht-Sequenz ist Darstellung und erzählt nur; das Fachergebnis rechnet ausschließlich die Auflösungs-Maschine deterministisch aus Daten und Weltuhr.
10. **Kein zweiter Buchungspfad über Kartengrenzen:** Handel und Karawanen buchen Fracht ausschließlich über die bestehenden Lager-Mutationen; es gibt keine Spezialwirtschaft für die Makroebene.

---

## 6. Ein-Befehl-Schnellzugriff (1-Command Navigation)

Alle Qualitäts-, Status- und Testprüfungen des Projekts lassen sich mit einem einzigen Befehl aufrufen:

```bash
python tools/preflight.py
```

* **Vollprüfung:** Führt alle 19 Prüfkategorien (Naming, Trennung, Determinismus, Registries, Godot-Headless, Warnungs-Scan, Shinon Gate, Whitespace E042, Version E043, Index E044) aus.
* **Scope-Gezielt:**
  * `python tools/preflight.py --kategorie warnungen` (GDScript-Warnungs-Scan nach Regel 6)
  * `python tools/preflight.py --kategorie shinon` (Shinon Gate Prüfung E030–E039)
  * `python tools/preflight.py --kategorie godot` (Headless Engine-Kompilierung)
* **Unittests:** `python -m pytest` führt alle 85 Unittests aus.
* **Index:** `python tools/index_generieren.py` frischt die Index-Familie auf: Root-, Domänen- und Datenindex plus die eine Last-Datei.

Version: V0.01
