# AGENTEN_INDEX.md — Einstieg für Agenten in SnipWarfare

Diese Datei ist die erste Anlaufstelle für jeden Agenten und jede Person, die an SnipWarfare arbeitet. Sie ist bewusst als Router gebaut: Sie erklärt in wenigen Minuten, wie das laufende System tickt, wo welcher Wert wohnt, wie ein neues System ohne Parallelsystem eingebaut wird und über welche mechanischen Prüfungen jede Änderung muss. Sie ersetzt nicht `Architektur.md`; sie führt dorthin.

Leseordnung:

1. Dieser Index, um zu verstehen, wo du bist und was du anfassen darfst.
2. `Architektur.md`, die verbindliche Referenz für Domänen, Datenklassen, Erweiterungsgrenzen, Verbindungswege und Fehlercodes.
3. Der Datenpool, den deine Aufgabe berührt, plus die zugehörige Registry.
4. `ROADMAP.md`, die konsolidierte Master-Roadmap (abgeschlossene und zukünftige Checkpoints je Slice).

Regel 0 des Projekts gilt auch hier: Der Code ist die Wahrheit. Dieser Index beschreibt den Code, er ist kein Ersatz für ihn. Wenn Index und Code sich widersprechen, gewinnt der Code, und der Index wird nachgezogen.

## 1. Das System in 90 Sekunden

1. SnipWarfare ist eine 2D-Kolonie- und RTS-Simulation auf Godot 4.7 (GL Compatibility). Der Bestand umfasst rund 180 GDScript-Dateien, 9 Szenen, 51 SVG-Assets, 23 JSON-Datenpools und 47 pytest-Fälle in 9 Testdateien.
2. Genau eine Zeit: Das Autoload `Weltuhr` (`Kern_Weltuhr`, 24 Ticks pro Sekunde) ist der einzige Simulationstakt und die einzige Faktor-zu-Ticks-Übersetzung (`ticks_aus_faktor`, `ticks_aus_minuten`). Kein zweiter Timer, kein Fachcode in `_process`, keine eigene Weltzeit einer Domäne.
3. Genau eine Zufallsquelle: `Kern_Zufall`. Direkte Aufrufe wie `randi`, `randf` oder `randomize` sind projektweit verboten (E012). Determinismus entsteht über Seed-Ableitungen (`Kern_Zufall.abgeleitet_fuer` für Regionen, `abgeleitet_fuer_chunk` für Chunks).
4. Genau ein Muster: Datenpool (JSON) → Datenklasse → Registry → Maschine oder Manager → Zustand im `Welt_Model` → Darstellung und Observer. Keine Stufe wird übersprungen, keine Stufe doppelt gebaut.
5. Genau eine Wahrheit je Wert: Zahlen leben im JSON, der Code liest sie über Getter. Eine hart codierte Zahl, die einen Wert aus einem Pool dupliziert, ist der Fehler E040 (Datenparität).
6. Eine Erweiterung ist Daten plus Asset: Ein neues Objekt, Tier, Job, Gebäude, Need, Biom oder Lagertyp entsteht als Pool-Eintrag mit `script`-Verweis und sichtbarem Asset. Maschinen und Manager bleiben dabei unberührt.
7. Szenen sind Ansichten: Dateien unter `*/scenes/` verdrahten nur und besitzen keine Simulationslogik. Die UI liest Snapshots über ihre Übersetzer und erfindet keinen Zustand und keine Fachwerte.

## 2. Datenfluss und Pyramide

```text
JSON-Pool            einzige Wahrheit der Werte (res://*/data/*.json)
  -> Datenklasse      Objekt_Basis, Resources_Wood, Tier_Baer, Job_Basis, Pop_NeedBasis, Welt_BiomBasis ...
  -> Registry         laedt genau einmal, erzeugt je Eintrag die exakte Klasse ueber das script-Feld
  -> Maschine/Manager genau eine Verantwortung, tickt ausschliesslich an Kern_Weltuhr
  -> Welt_Model       traegt den Zustand; Aenderung nur ueber eigene Mutationen
  -> Darstellung      Welt_Renderer, Welt_ObjektDarsteller, Einheit_Darsteller, HUD und Panels lesen nur
```

Spielkette der Eingabe: `Ui_EingabeSteuerung` und `Ui_KameraSteuerung` übersetzen Maus und Tasten in Aufrufe an Manager und Maschinen; der Zustand wandert ins `Welt_Model`; `Welt_Renderer`, HUD und Panels beobachten und zeigen. Die Szene `world/scenes/welt.tscn` komponiert diese Spitzen und besitzt selbst keine Fachlogik.

## 3. Domänenkarte

Jede Klasse trägt ihren Kategorie-Präfix im Namen, der Präfix bestimmt den Ordner. Der Preflight erzwingt das (E001, E003).

| Ordner | Präfix | Datenbesitzer | Erzeugung und Tick | Erweiterungsgrenze |
| --- | --- | --- | --- | --- |
| `core/` | `Kern_` | `kern_modifikatoren.json`, `modifikator_settings.json`, `kern_logik.json` | `Kern_Weltuhr` (Autoload), `Kern_ModifikatorMaschine` je State-Maschine, `Kern_SignalBus`, `Kern_Zufall`, `Kern_Timeline` | neuer Modifikator, neuer Bereich oder neue Logik nur als Pool-Eintrag |
| `world/` | `Welt_`, `Objekt_`, `Tier_`, `Orchestrator_` | `element_katalog.json`, `tier_verhalten.json`, `biome.json`, `welt_definition.json`, `generator_gewichte.json`, `ressourcen_progression.json`, `gebaeude.json`, `atmosphaere.json`, `standard_welt.json` | `Welt_Generator`, `Welt_Model`, `Welt_Renderer`, `Gebaeude_Manager`, `Tier_Manager`, `Welt_ProgressionsMaschine` | Katalog-, Gewichts-, Biom- oder Definitions-Eintrag plus Asset |
| `game/` | `Einheit_`, `Job_`, `Resource_` | `job_config.json`, `ressourcen.json`, `animationen.json`, `steuerung.json`, `progression.json`, `mutationen_ressourcen.json`, `orchestrator_config.json` | `Einheit_Manager`, `Einheit_Status`, `Einheit_ErnteMaschine`, `Job_Registry` | neue Job-Klasse plus `script`-Feld, neue Ressource als Pool-Eintrag mit Icon, neue Kontext-Aktion mit `logik_id` |
| `population/` | `Pop_` | `needs.json`, `mood_modifikatoren.json`, `rassen_schemata.json` | `Pop_NeedBaum` (Knoten), je Einheit eine `Pop_MoodMaschine` und eine `Pop_Denkblase` | Need-Klasse plus `script`-Feld, Rassen-Schema-Eintrag, neue Eskalationsstufe im Mood-Pool |
| `economy/` | `Lager_` | `lager.json` | `Lager_Registry`, `Lager_Manager`, `Lager_MutationEinlagern` und `Lager_MutationEntnehmen` | neuer Lagertyp nur als Template-Eintrag |
| `ui/` | `Ui_` | Konsument von `steuerung.json` | `Ui_EingabeSteuerung`, `Ui_KameraSteuerung`, Panels als PackedScenes, HUD-Observer | neue Kontext-Aktion mit `logik_id` plus einem Decode-Zweig; neues Panel als Szene mit Übersetzer |
| `world/terrain`, `world/settlements`, `world/resources`, `world/infrastructure`, `military/` | noch keiner | noch keines | nur `.gitkeep`-Gerüste, keine Klassen | neuer Inhalt gehört fachlich in die passende Domäne; Militär bekommt eigene Präfixe und bleibt getrennt |

## 4. Routing: Welche Frage gehört wohin

| Wenn du wissen willst ... | Dann lies zuerst |
| --- | --- |
| Wie Welten aus dem Seed entstehen | `world/logic/kategorie_generator/`, `world/data/generator_gewichte.json`, `world/data/welt_definition.json` |
| Wie die Karte gezeichnet wird und wie groß eine Kachel ist | `world/logic/kategorie_welt/welt_renderer.gd`, `world/logic/kategorie_welt/welt_model.gd`, `world/data/welt_definition.json` |
| Welche Werte ein Baum, Stein, Busch oder ein Feuer hat | `world/data/element_katalog.json`, `world/logic/kategorie_objekt/` |
| Wie Gebäude gebaut und betrieben werden | `world/data/gebaeude.json`, `world/logic/kategorie_objekt/gebaeude_manager.gd` |
| Wie der Einstieg gestuft und gesperrt ist | `game/data/progression.json`, `world/logic/kategorie_progression/welt_fortschritts_maschine.gd` |
| Wie Jobs, Ernte und Arbeitszeit laufen | `game/data/job_config.json`, `game/logic/kategorie_job/`, `game/logic/kategorie_einheit/einheit_ernte_maschine.gd` |
| Wie eine Einheit denkt, geht, arbeitet und Aufträge sammelt | `game/logic/kategorie_einheit/einheit_status.gd`, `einheit_manager.gd`, `einheit_weg_planung.gd` |
| Wie Bedürfnisse, Stimmung und Eskalationsketten entstehen | `population/data/mood_modifikatoren.json`, `population/logic/mood/` |
| Wie Tag, Nacht, Wärme und Atmosphäre laufen | `world/logic/kategorie_tageszyklus/`, `world/logic/kategorie_waerme/`, `world/data/atmosphaere.json` |
| Wie Bestände und Lager funktionieren | `economy/data/lager.json`, `economy/logic/storage/` |
| Wie Eingabe, Auswahl, Panels und Kontextmenü aufgebaut sind | `ui/logic/kategorie_ui/`, `ui/scenes/panels/`, `game/data/steuerung.json` |
| Wie die Weltkarte und der Startbereich funktionieren | `world/scenes/welt_map.gd`, `world/logic/kategorie_welt/welt_netzwerk_planer.gd` |
| Wie Zonen und der Orchestrator Jobs vergeben | `game/data/orchestrator_config.json`, `world/logic/kategorie_orchestrator/` |
| Warum ein Zustand so ist (Begründungskette) | `core/logic/kern_timeline.gd`, `kern_timeline_eintrag.gd`, Warum-Knopf im HUD |
| Wie geprüft wird und was blockiert | `tools/preflight.py`, `tools/warnungs_scan.py`, `tools/lauf_pruefung_welt.gd` |
| Was gerade als Nächstes zu tun ist | `ROADMAP.md` (Abschnitt 4: Zukünftige Checkpoints) |
| Was bereits erledigt und verifiziert ist | `ROADMAP.md` (Abschnitt 2: Abgeschlossene Checkpoints) |

## 5. Erweiterungsrezept: Neues System ohne Parallelsystem

Der Weg ist immer derselbe: Daten plus Asset in eine bestehende Registry, ein Verbraucher, der die Daten liest, und ein Beweis. Eine Maschine wird nur dann berührt, wenn eine fachlich fehlende Fähigkeit nachgewiesen ist, und dann als eigener Slice mit eigener Verifikation.

| Ziel | Datenpool | Datenklasse | Registry | Verbraucher | Beweis |
| --- | --- | --- | --- | --- | --- |
| Neues Weltobjekt (Baum, Erz, Ruine) | `world/data/element_katalog.json` plus Gewicht in `generator_gewichte.json` | `Objekt_*` in `world/logic/kategorie_objekt/` | `Objekt_RegistryBasis._objekt_klasse_fuer` über das `script`-Feld | `Welt_Generator`, `Welt_Renderer` | Preflight E022 plus Sicht auf der Karte |
| Neues Tier | `element_katalog.json`, `tier_verhalten.json`, Cluster in `generator_gewichte.json` | `Tier_*` in `kategorie_tier/` | `Tier_Registry._tier_klasse_fuer` | `Tier_Manager`, `Tier_Status` | Tier erscheint, flieht, wird gejagt |
| Neuer Job | `game/data/job_config.json` mit `script`-Feld | `Job_*` in `game/logic/kategorie_job/` | `Job_Registry._job_erzeugen` | `Einheit_Status`, `Einheit_Manager` | Einheit führt den Job sichtbar aus |
| Neue Ressource | `game/data/ressourcen.json` mit `script`-Feld und Icon | `Resource*_*` in `kategorie_ressourcen/` | `Einheit_Ressourcen._ressourcen_klasse_fuer` | Ernte- und Lagermaschinen | Bestand im HUD, Buchung in der Timeline |
| Neues Gebäude oder Rezept | `world/data/gebaeude.json` plus Katalog- und Gewichts-Eintrag | `Gebaeude_Definition` | `Gebaeude_DefinitionRegistry` | `Gebaeude_Manager`, Bau- und Produktionsmaschine | Bau sichtbar, Produktion liefert Output |
| Neues Bedürfnis | `population/data/needs.json` mit `script`-Feld | `Pop_Need*` | `Pop_NeedRegistry._need_klasse_fuer` | `Pop_NeedBaum`, `Pop_MoodMaschine` | Denkblase und Need-Wert reagieren |
| Neue Rasse | `population/data/rassen_schemata.json` | `Pop_RassenSchema` | `Pop_RassenSchemaRegistry` | `Pop_NeedBaum`, `Einheit_Status` | Spawn mit Rasse, sichtbar anderes Verhalten |
| Neue Eskalationsstufe oder Kette | `population/data/mood_modifikatoren.json` | `Pop_MoodEskalationStufe` | `Pop_MoodModifikatorRegistry` | `Pop_MoodMaschine`, `Pop_Denkblase` | Blase erzählt Grund und Wirkung, Kette greift weiter |
| Neues Biom | `world/data/biome.json` plus Gewicht in `generator_gewichte.json` | `Welt_BiomBasis` | `Welt_BiomRegistry` | `Welt_BiomManager` als Mutation | Region färbt sich, Mutation wirkt |
| Neuer Modifikator oder Bereich | `core/data/kern_modifikatoren.json`, `modifikator_settings.json` | `Kern_ModifikatorBasis` | `Kern_ModifikatorRegistry.geteilte()` | alle State-Maschinen über `Kern_ModifikatorMaschine` | Zeit und Geschwindigkeit ändern sich nachvollziehbar |
| Neuer Lagertyp | `economy/data/lager.json` | `Lager_Basis` | `Lager_Registry` | `Lager_Manager` | Bestände landen im neuen Lager |
| Neue Kontext-Aktion | `game/data/steuerung.json` mit `logik_id` | `Kern_SteuerungBasis` | `Kern_SteuerungRegistry` | `Ui_EingabeSteuerung`, `KontextMenue` | Rechtsklick zeigt und führt die Aktion aus |

## 6. Mechanisch erzwungene Regeln

Der volle Preflight (`python tools/preflight.py`) ist vor jedem Commit Pflicht. Ohne grünes Shinon Gate gilt kein Commit als fertig.

| Code | Bedeutung | Was du tust |
| --- | --- | --- |
| E001, E003 | Klasse ohne Kategorie-Präfix oder im falschen Ordner | Präfix vergeben, Datei in den Kategorie-Ordner legen |
| E004 | Logik-Skript ohne `class_name` | Namen vergeben; Ausnahme bleiben Ansichten unter `*/scenes/` |
| E006, E007 | Daten-Arrays ohne die Markierungen `## Kategorie daten` und `## Kategorie logik` | beide Bereichsmarker setzen |
| E010 | getyptes Array mit unbekanntem Elementtyp | echte Datenklasse nennen |
| E012 | verbotener Zufallsaufruf | nur `Kern_Zufall` verwenden |
| E015 | Pfad zeigt auf nichts oder ist nicht `res://` | Pfad korrigieren |
| E019, E020, E022 | Registry-Quelle fehlt, IDs kollidieren oder ein Eintrag zeigt auf kein Asset | Pool und Asset prüfen |
| E023, E024 | RT-Pyramide verletzt oder Biom wirkt nicht als Mutation | Berechnung nur zentral, Biom nur als Mutation |
| E025 | Warnungs-Scan meldet eine Editor-Warnklasse | beheben oder bewusst mit Unterstrich, `@warning_ignore` oder Kommentar dokumentieren |
| E030 bis E039 | Shinon Gate (Banner, Bullets, Nummerierung, Bildsprache, README, Steuerung, Footer, Nennung, Stil) | `shinon/commit_msg.txt` in nummerierten, bildlichen Sätzen pflegen und jede geänderte Datei namentlich nennen |
| E040 | hart codierte Zahl dupliziert einen Pool-Wert | Wert aus der Registry lesen |

## 7. Beweiskette: Wann eine Aufgabe fertig ist

1. `python -m pytest -q` läuft grün. Ein roter Test ist eine offene Baustelle, kein Nebengeräusch.
2. `python tools/preflight.py` läuft grün, inklusive Godot-Lauf, Warnungs-Scan und Shinon Gate.
3. `tools/lauf_pruefung_welt.gd` führt die Verhaltenskette headless durch und meldet grün.
4. Die Änderung ist im laufenden Spiel sichtbar verifiziert (Regel 7). Eine grüne Preflight-Zeile ohne sichtbares Ergebnis ist wertlos.
5. `Architektur.md` und der Plan sind zur Änderung nachgezogen. Jede geänderte Datei steht namentlich in `shinon/commit_msg.txt` (E038).

## 8. Verbotsliste: Diese Muster brechen das System

| Anti-Muster | Richtig stattdessen |
| --- | --- |
| Zweiter Tick oder `_process`-Fachlogik | alles an `Kern_Weltuhr` hängen |
| Zweite Formel für dieselbe Rechnung | die zentrale Berechnung in `Kern_Weltuhr` oder `Kern_ModifikatorMaschine` nutzen |
| Zahl im Code, die auch im JSON steht | Registry-Getter lesen (E040) |
| Direkter Zugriff auf `_einheiten`, `_job_queue` oder fremde Arrays | die freigegebene Leseschnittstelle des Besitzers nutzen |
| Zwei Systeme, die dasselbe steuern (zwei Schwellwert-Quellen, zwei Bauphasen-Quellen) | eine Quelle, ein Verbraucher je Frage |
| UI, die Fachwerte rechnet oder Zustand erfindet | UI liest nur Snapshots über ihren Übersetzer |
| Szene als Logikcontainer | Logik in ihre Kategorie, Szene verdrahtet nur |
| Domain-übergreifender Logikaufruf | nur über definierte Schnittstellen, Zustände oder Signale |
| Logistik in eine Bau-Zustandsmaschine kippen | Transport als eigener Job in der Job-Domäne |

## 9. Arbeitsreihenfolge eines Slices

1. Auftragskategorie aus dem Plan wählen und prüfen, ob sie schon erledigt ist (`docs/Inventur_Stand.md`).
2. Asset einbauen, damit das Ergebnis später sichtbar sein kann.
3. Datenpool und Datenklasse ergänzen, per Registry verbinden.
4. Verhalten anschließen, falls es nicht statisch ist, und Spawn-Regeln festlegen.
5. Tests und Laufbeweis schreiben, die den neuen Zustand belegen.
6. Ingame verifizieren: Das Ding muss auf der Karte erscheinen, angeklickt, bewegt, interagiert oder beobachtet werden können.
7. Preflight, Warnungs-Scan und Commit-Workflow, maximal 10 bis 15 Dateien pro Commit.

## 10. Aktueller Zustand und bekannte Baustellen

Der Bestand ist spielbar und gleichzeitig Baustelle. Diese Punkte sind am Code belegt und im Plan als Auftragskategorien verankert; sie stehen hier, damit kein Agent sie als gelöst annimmt:

1. Ein pytest ist rot: `test_einstiegs_progression.py::test_steuerung_traegt_bau_aktion_fuer_lagerfeuer_und_gesperrte` verlangt die Bau-Aktionen im Kontextmenü, während die laufende Vorarbeit das Bauen bereits aus `game/data/steuerung.json` in das Bau-Panel verschoben hat. Die Gating-Wahrheit muss an genau einer Stelle landen.
2. Die Kachelgröße hat zwei Quellen: `kachel_groesse` in `world/data/welt_definition.json` und die Konstante `KACHEL_GROESSE := 512` in `world/logic/kategorie_welt/welt_model.gd`. Der Getter der Definitions-Registry hat keinen Verbraucher.
3. Die Weltkarte (`world/scenes/welt_map.gd`) fährt den vollen lokalen Generator (`Welt_Generator.welt_erzeugen`), obwohl sie eine Makrokarte zeichnet. Das ist eine zweite Erzeugungsstelle und der Grund, warum der Startbereich riesig wirkt.
4. Objekte werden ohne Tiefensortierung gezeichnet, deshalb verdecken sich Bäume, Steine und Gebäude gegenseitig und wirken abgeschnitten.
5. `ui/logic/kategorie_ui/ui_bau_panel.gd` erfindet Stufen-Sperren im Code (`haus` ergibt 1, `werkstatt` und `raeucherei` ergeben 2), obwohl die Sperre ein Attribut der Gebäude-Definition sein sollte.
6. `ui/scenes/panels/kontext_menue.gd` filtert Ziele mit fest verdrahteten Textvergleichen (`contains("baum")` und Ähnliches), statt über Tags aus den Daten zu filtern.

## 11. Pflege dieser Datei

Dieser Index wird bei jeder Änderung an Domänen, Ordnern, Präfixen, Datenpools, Preflight-Codes oder an der Definition of Done mitgezogen. Er bleibt kurz genug zum Lesen und verweist für Tiefe auf `Architektur.md`. Wenn du einen neuen Datenpool anlegst, trage ihn in Abschnitt 3 und 5 ein; wenn du einen Preflight-Code einführst, trage ihn in Abschnitt 6 ein.
