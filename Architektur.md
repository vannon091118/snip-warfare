# Architektur.md – Pflichtdokumentation

Diese Datei ist die verbindliche Pflichtdokumentation der Projektarchitektur. Sie wird aktiv gepflegt: Jede Änderung an Klassennamen, Kategorien, Datenfeldern oder Domänengrenzen wird hier sofort mitgepflegt. Vor jedem Commit wird `python tools/preflight.py` ausgeführt; nur ein fehlerfreier Preflight (Exit-Code 0) gilt als abnahmefähig.

## 1. Domänen und Kategorien

Jede Klasse trägt ihre Kategorie als Präfix im Klassennamen und liegt im passenden Kategorie-Ordner. Kategorien sind fachliche Zugehörigkeiten, keine technischen Sammelordner.

| Präfix | Kategorie | Ordner | Inhalt |
| --- | --- | --- | --- |
| `Pop_` | Bevölkerung Bedürfnisse und Stimmungen | `population/` | Needs (Pop_NeedBasis/Nahrung/Waerme + Pop_NeedRegistry aus needs.json), Rassen (Pop_RassenSchema + Pop_RassenSchemaRegistry aus rassen_schemata.json), Mood (Pop_Mood + Pop_MoodMaschine als Node-Kind des Pop_NeedBaum + Pop_MoodModifikator/Registry aus mood_modifikatoren.json), Denkblase (Pop_Denkblase als Observer) |
| `Kern_` | Zentrale Engine-Dienste | `core/` | Weltuhr (einziger globaler Tick), Asset Pflicht Gate, Zufall (Kern_Zufall), Modifikatoren, Signalbus (Autoload `Kern_SignalBus`, Klasse in `core/logic/events/`) |
| `Lager_` | Lokale Speicher | `economy/logic/storage/` | Basis (Typ), Registry (Templates), Manager (Instanzen je Ort), Mutationen (Einlagern, Entnehmen) |
| `Orchestrator_` | Zonen-Orchestrator | `world/logic/kategorie_orchestrator/` | Basis, Konfiguration, Status, Manager (Bedarf -> Jobvergabe), Registry, Darsteller |
| `Shinon_` | Commit Gate | `shinon/` | Banner Banner Pruefer, Bullet Pruefer, Nummerierung Pruefer, Bildsprache Pruefer, Gate Orchestrator |
| `Objekt_` | Weltobjekt-Datenklassen | `world/logic/kategorie_objekt/` | Kachel, Baum, Baumstumpf, Stein, Steingruppe, Haus, Hausgross, Kadaver, Lagerfeuer, Basis |
| `Resources_` / `Resource_` | Ressourcen-Datenklassen | `game/logic/kategorie_ressourcen/` | Wood, Stone, Meat, Basis |
| `Tier_` | Tier-Datenklassen und Tier-Verhalten | `world/logic/kategorie_tier/` | Baer, Hase, Vogel, Vogelgruppe, Basis, Verhalten, Status, Darsteller, Manager |
| `Job_` | Job-Zustandsmaschinen | `game/logic/kategorie_job/` | Holzfaeller, Steinmetz, Jaeger, HolzfaellerStumpf, JaegerKadaver, Heiler, Basis, Registry |
| `Einheit_` | Spielfiguren-Domäne | `game/logic/kategorie_einheit/` | Status, VitalStatus (Leben und Modifikatoren), Darsteller, Manager, Ressourcen |
| `Welt_` | Welt-Zustandsmaschinen und Dienste | `world/logic/` | Model, Registry, Speicher, Renderer (kategorie_welt), ObjektDarsteller (kategorie_welt), EditorWerkzeug (kategorie_welt), WaermeFeld (kategorie_waerme), TageszyklusMaschine (kategorie_tageszyklus), DefinitionRegistry + GrenzProfil (kategorie_welt) |
| `Ui_` | Benutzeroberfläche | `ui/logic/kategorie_ui/` | Uebersetzer (Ui_EinheitPanel/Ui_TierPanel) lesen nur Snapshots, Fenster lesen nur Uebersetzer |
| `Ui_` | Fenster-Szenen | `ui/scenes/panels/` | EinheitPanel, TierPanel als PackedScene (VBoxContainer, nur Observer), KontextMenue, Auswahl — jede als eigene Szene komponiert |

Regeln:

1. Es gibt keine doppelten und keine ähnlich klingenden Klassennamen; der Präfix ist Teil des Namens und damit der Zugehörigkeit (`Objekt_Stein` ist ein Weltobjekt, `Resources_Stone` ist eine Ressource – sie klingen nicht ähnlich und dürfen nicht verwechselt werden).
2. Jede Klasse erhält genau einen Präfix; der Präfix bestimmt den Ordner. Der Preflight erzwingt dies (E001, E003).
3. Ansichten in `*/scenes/` werden über die `.tscn` geladen und tragen bewusst keinen globalen `class_name`; Autoloads behalten ihren Kurz-Globalnamen (`Weltuhr`, `WeltSitzung`), ihre Klasse trägt den Kategorie-Präfix (`Kern_Weltuhr`, `Ui_WeltSitzung`).

## 2. Strikte Trennung: Daten und Arrays vs. Funktionen

Jede Klassendatei trennt zwei Bereiche durch Kommentar-Markierungen. Diese Trennung ist Pflicht und wird vom Preflight geprüft (E006, E007):

```gdscript
## Kategorie daten: Arrays und Felder, die die Klasse hält.
var katalog_objekte: Array[Objekt_Basis] = []

## Kategorie logik: Funktionen, die diese Daten lesen oder ändern.
func finde_objekt(id: String) -> Objekt_Basis: ...
```

Regeln:

1. Daten-Arrays der Klasse stehen nur im Datenbereich; sie werden ausschließlich über eigene Funktionen der Klasse geändert.
2. Funktionen ändern nie fremde Arrays direkt; sie rufen die Funktionen der besitzenden Klasse auf.
3. Lokale Arrays in Funktionen sind keine Klassendaten und unterliegen der Markierung nicht.
4. Datenklassen (`Objekt_Basis`, `Resource_Basis`, `Tier_Basis` und Unterklassen) enthalten nur Felder und reine Einlesefunktionen; sie rufen nichts auf und berechnen nichts.

## 3. Datenklassen mit exakten Namen

Jedes Datenobjekt hat eine eigene Klasse mit exaktem, eindeutigem Namen. Die Registry erzeugt sie zentral; der Preflight gibt pro Datei aus, welche Datenobjekte wo entstehen (Abschnitt „DATENKLASSEN" in der Ausgabe von `tools/preflight.py`).

| Exakter Klassenname | Quelle (relativer Pfad) |
| --- | --- |
| `Objekt_Kachel` | `world/data/element_katalog.json` (boden, wiese) |
| `Objekt_Baum` | `world/data/element_katalog.json` (baum) |
| `Objekt_Baumstumpf` | `world/data/element_katalog.json` (baum_stumpf) |
| `Objekt_Stein` | `world/data/element_katalog.json` (stein) |
| `Objekt_Steingruppe` | `world/data/element_katalog.json` (steine_gruppe) |
| `Objekt_Haus` | `world/data/element_katalog.json` (haus) |
| `Objekt_Hausgross` | `world/data/element_katalog.json` (haus_gross) |
| `Objekt_Lagerfeuer` | `world/data/element_katalog.json` (lagerfeuer, waerme_quelle wie Hausgross aber Feuer) |
| `Resources_Wood` | `game/data/ressourcen.json` (holz) |
| `Resources_Stone` | `game/data/ressourcen.json` (stein) |
| `Resources_Meat` | `game/data/ressourcen.json` (fleisch) |
| `Pop_NeedNahrung` | `population/data/needs.json` (nahrung) |
| `Pop_NeedWaerme` | `population/data/needs.json` (waerme) |
| `Pop_MoodModifikator` | `population/data/mood_modifikatoren.json` (kaelte/hitze/hunger/kannibalismus, je Eintrag eine Eskalationskette aus Pop_MoodEskalationStufe-Stufen mit Grund, Wirkung und folge_mod_id) |
| `Pop_MoodEskalationStufe` | `population/data/mood_modifikatoren.json` (eskalation-Array je Mod: stufe, schwelle, emoji, grund, wirkung, verhalten, folge_mod_id) |
| `Job_Kannibale` | `game/data/job_config.json` (kannibale, OWN-Ziel, schnelle Schläge) |
| `Welt_WaermeFeld` | `world/data/element_katalog.json` (lagerfeuer Quellen, Radius 5) + Tageszyklus |
| `Welt_TageszyklusMaschine` | `population/data/needs.json` (6 Min Takt 4 Tag/2 Nacht) + `Welt_WaermeFeld` |
| `Lager_Basis` | `economy/data/lager.json` (kleines_lager, grosses_lager) |
| `Orchestrator_Konfiguration` | `game/data/orchestrator_config.json` (holzsammler_zone, jaeger_zone) |
| `Tier_Baer` | `world/data/tier_verhalten.json` (baer) |
| `Tier_Eisbaer` | `world/data/tier_verhalten.json` (eisbaer, Kombi baer_verfolgen + aggressiv x1.2) |
| `Tier_Hase` | `world/data/tier_verhalten.json` (hase) |
| `Tier_Vogel` | `world/data/tier_verhalten.json` (vogel) |
| `Tier_Vogelgruppe` | `world/data/tier_verhalten.json` (vogelgruppe) |
| `Welt_BiomBasis` | `world/data/biome.json` (gemaessigt, tundra, steppe) |

Erzeugungsorte: `Objekt_RegistryBasis._objekt_klasse_fuer()` (Plugin-Naht: script-Feld aus `element_katalog.json`, Fallback `_zentrale_klasse_fuer` in `Welt_Registry`), `Einheit_Ressourcen._ressourcen_klasse_fuer()`, `Tier_Registry._tier_klasse_fuer()`, `Welt_BiomRegistry` (biome), `Lager_Registry` (lager), `Orchestrator_Registry` (orchestrator_config), `Kern_ModifikatorRegistry` (kern_modifikatoren), `Pop_NeedRegistry._need_klasse_fuer()` (needs waerme), `Pop_MoodModifikatorRegistry` (mood_modifikatoren). Neue Datenklassen werden nur an diesen Stellen registriert.

Neue Datensätze entstehen nur über Datenpool → Registry → Maschine. `Ui_EinheitPanel` liest Einheiten nur über `Einheit_Manager.einheit_beschreibung()` / `einheit_position()`, `Ui_TierPanel` nur über `Tier_Manager.tier_bestand()`. Kein Panel greift auf `_einheiten` oder `_tiere`. Fenster sind PackedScenes, die Szene stempelt per `PackedScene.instantiate()` + `add_child()` unter den HUD-CanvasLayer, setzt danach `einrichten()`; `_ready()` der Szene läuft garantiert, `get_node_or_null()` schützt jeden Zugriff.

## 4. Commit Gate Shinon im Root

Der Ordner shinon im Projektstamm ist das verbindliche Commit Gate und Init nach AGENTS.md Regel 5. Er ist granular gebaut damit jede Mechanik eine eigene Klasse mit klarer Verantwortung hat. Das Gate wird mechanisch vor jedem Commit durchlaufen und ist im Preflight als Kategorie shinon mit den Codes E030 bis E036 verankert. Ohne grünes Gate gilt kein Commit als fertig. Das Init läuft ausschließlich über python shinon/shinon_init.py und nimmt niemals Zustand aus einem anderen lokalen Projekt, nur den gh Token.

| Datei | Rolle | Code |
| --- | --- | --- |
| `shinon/commit_msg.txt` | Einzige erlaubte Erzählung des Commits in ganzen nummerierten bildlichen Sätzen ohne Banner und ohne Bullet | E032 E034 |
| `shinon/shinon_gate.py` | Orchestrator der die vier Teilprüfer zusammenführt und die Datei prüft | E030 E034 |
| `shinon/shinon_banner_pruefer.py` | Erkennt Banner Zeilen mit mehr als zehn gleichen Sonderzeichen oder dem Wort Tralal | E030 |
| `shinon/shinon_bullet_pruefer.py` | Erkennt Bullet Zeilen die mit Bindestrich Stern Mittelpunkt oder Plus beginnen | E031 |
| `shinon/shinon_nummerierung_pruefer.py` | Prüft dass jede inhaltstragende Zeile 1. Satz. 2. Satz. ist und lückenlos steigt | E032 |
| `shinon/shinon_bildsprache_pruefer.py` | Prüft dass nicht nur technische Pfade aneinandergereiht werden und jeder Satz mindestens fünf Wörter trägt | E033 |
| `shinon/shinon_footer_pruefer.py` | Blockiert fremde Agent-Footer in commit_msg.txt: Generated with, Co-Authored-By, Werkzeug-Signaturen, Agent-Emojis | E037 |
| `shinon/shinon_nennung_pruefer.py` | Verlangt dass jede geänderte Datei in commit_msg.txt namentlich mit Dateinamen genannt wird, liest die Änderungen aus Git | E038 |
| `shinon/shinon_commit_komponist.py` | Baut die Commit-Nachricht ausschließlich 1:1 aus commit_msg.txt, ohne Zusatz, ohne Footer, ohne Zeilenerzeugung | - |
| `shinon/shinon_readme_pruefer.py` | Prüft dass README.md aus Sicht von Shinon lebt, Zustand und Vision gamer orientiert in universe und mit gebrochener vierter Wand erzaehlt | E035 |
| `shinon/shinon_steuerung_pruefer.py` | Prüft dass game/data/steuerung.json menschenlesbar WASD Kamera, Linksklick einzeln, Drag Masse und Rechtsklick Kontext sammeln abbauen mit Tooltip Werkzeug beschreibt | E036 |
| `shinon/shinon_projekt_status_leser.py` | Liest den echten Zustand direkt aus project.godot, Registries und JSONs, ohne fremden Zustand | - |
| `shinon/shinon_readme_generator.py` | Baut die README als In Universe Pitch von Shinon aus echten Daten, zynisch humorvoll style agnostisch | E035 |
| `shinon/shinon_git_helfer.py` | Bedient nur git und gh des aktuellen Projekts, prueft Auth und legt Repo an | - |
| `shinon/shinon_starter.py` | Ruft vor dem Commit Status und Generator und danach das Gate | - |
| `shinon/shinon_init.py` | Einzige Pflicht Init mit --init --check --github --readme, orchestriert alles | E035 E036 |
Regeln des Gates und des Inits:

1. Banner sind verboten. Jede Zeile mit Kette aus mehr als zehn gleichen Sonderzeichen wie Gleich Zeichen oder Raute oder Stern oder Strich oder Tilde und jede Zeile mit dem Wort Tralal meldet E030.
2. Bullet Listen sind verboten. Jede Zeile die mit Bindestrich Leerzeichen oder Stern Leerzeichen oder Mittelpunkt Leerzeichen oder Plus Leerzeichen beginnt meldet E031.
3. Nummerierte bildliche Sätze sind Pflicht. Jede inhaltstragende Zeile beginnt mit fortlaufender Nummer Punkt Leerzeichen und endet mit Punkt. Leere Zeilen sind nur als Trenner erlaubt. Verstöße melden E032.
4. Bildliche Sprache ist Pflicht. Rein technische Aufzählungen gelten als E033 und zu kurze Sätze unter fünf Wörtern ebenfalls.
5. Fehlt die Datei oder ist sie leer oder nicht als UTF-8 lesbar meldet das Gate E034.
6. Fehlt die README, ist sie zu kurz, ohne Shinon Stimme, ohne vierte Wand, ohne Zustand und Vision oder ohne Bezug zu Preflight Weltuhr oder Registry meldet E035. Die README wird nur ueber shinon/shinon_init.py --readme aus echten Daten erneuert.
7. Fehlt game/data/steuerung.json, ist sie kein gueltiges JSON ohne kamera auswahl und kontextmenue, ohne WASD Linksklick Drag und Rechtsklick sammeln abbauen mit Icon und Tooltip Werkzeug oder zeigt ein Icon auf kein res Asset meldet E036.
8. Voller Preflight enthält die Kategorie shinon immer. Gezielte Läufe wie --kategorie klassen umgehen das Gate nur wenn shinon nicht gewählt ist. Das Init nimmt niemals Dateien aus anderen lokalen Repos, nur den gh Token des eingeloggten Accounts.

## 5. Zentrale Konfigurationen (keine hart codierten Werte)

| Datei | Inhalt | Leser |
| --- | --- | --- |
| `game/data/animationen.json` | Sprite-Sheets, Frame-Maße, Ticks pro Frame | `Einheit_Darsteller` |
| `game/data/job_config.json` | Harvest-Zeit, Menge, Reichweite, Zielressource je Job | `Job_Registry`, `Job_Basis` |
| `game/data/ressourcen.json` | Ressourcen mit Icon-Pfaden | `Einheit_Ressourcen` |
| `game/data/steuerung.json` | Menschenlesbare Steuerung WASD Kamera, Linksklick einzeln, Drag Masse, Rechtsklick Kontext sammeln abbauen mit Tooltip Werkzeug, faktor 1=10s; je Bau-Aktion die Sperre `gesperrt_ab_stufe` als einzige Stufen-Wahrheit | `Kern_SteuerungRegistry` -> `Ui_EingabeSteuerung` (Kamera, Auswahl, Kontext) + `Ui_KameraSteuerung` + `KontextMenue` (ausgegraute Sperren) |
| `game/data/progression.json` | Einstiegs-Kette als einzige Stufen-Wahrheit: Zieltyp (gebaeude_bauen oder einwanderung), Menge, Beschreibung und `schaltet_frei` je Stufe | `Welt_FortschrittsRegistry` -> `Welt_FortschrittsMaschine` (Stufen-Zustand, Gating, Signale) -> `Gebaeude_Manager` (Bauabschluss), `Einheit_Manager` (Einwanderung), `Welt` (HUD-Zielzeile) |
| `world/data/element_katalog.json` | Platzierbare Objekte mit Kategorie | `Welt_Registry` |
| `world/data/tier_verhalten.json` | Tierwerte (Trigger, Geschwindigkeit, Ertrag, HP) | `Tier_Verhalten` |
| `world/data/biome.json` | Biome als Mutationen je Biom mit logik_id, modifikator, faktor | `Welt_BiomRegistry` + `Welt_BiomMutation` + `Welt_BiomManager` |
| `world/data/standard_welt.json` | Nur Legacy-Editor-/Demo-Raster; niemals Generator- oder Produktionswahrheit, wird ausschließlich vom Karten-Editor im Kreativmodus geladen | `karten_editor.gd` (Editor-Demo) |
| `world/data/welt_definition.json` | Zentrale Weltdefinition: max/min Kartengröße, Kachelgröße, Chunkgröße, Regionkante als Daten | `Welt_DefinitionRegistry` -> `Welt_Generator` (Kartengröße aus Seed deterministisch) |
| `core/data/kern_logik.json` | Generische Logiken wiederverwendbar | `Kern_LogikRegistry.geteilte()`; Verbraucher sind `Objekt_Basis.effektiver_faktor`, `Tier_Basis.effektiver_faktor` und die Arbeitszeit des Jobs |
| `core/data/kern_modifikatoren.json` | Modifikatoren mit faktor 1=10s (Verletzungen sperren Jobs) | `Kern_ModifikatorRegistry` + `Kern_ModifikatorMaschine` + `Einheit_VitalStatus` |
| `core/data/modifikator_settings.json` | Globale Modifikator-Settings je Bereich (bau, produktion, bewegung, need): Modus, Faktor-Grenzen, Bewegungs-Basiswerte, globaler Faktor | `Kern_ModifikatorMaschine` (eine Instanz je State-Maschine, Bereich als angepasste Settings) |
| `population/data/rassen_schemata.json` | Rassen-Schemata mit Multiplikatoren für Nahrung, Dringlichkeit, Abfall, Schwellwert, Bewegung | `Pop_RassenSchemaRegistry` -> `Pop_NeedBaum` -> `Pop_MoodMaschine` (Schema × zentraler Faktor) + `Einheit_Status` (Bewegung) + `Einheit_Manager` (Nahrungsverteilung) |
| `population/data/needs.json` | Bedürfnisse mit Ressource, Schwellwert, Emoji und Sprechblase je Need (waerme als Vektor-Feld via Feuer) sowie der Abschnitt `weltrhythmus` mit `takt_minuten` 6, `tag_minuten` 4, `nacht_minuten` 2 und `verbrauch_je_takt` 0.8 als einzige Quelle des Spielrhythmus | `Pop_NeedRegistry` (Need-Typen + Rhythmus-Getter) -> `Pop_NeedBaum` (Rhythmus-Weitergabe) -> `Pop_MoodMaschine` (Need sammeln + Waerme je Kachel) + `Welt_TageszyklusMaschine` (Takt und Tag/Nacht über `welt.gd`) + `Einheit_Manager`/`Einheit_Versorgung` (Nahrungstakt und Verbrauch) + Verteilungs-Fenster (Startwert und Taktangabe) |
| `population/data/mood_modifikatoren.json` | Mood-Modifikatoren als Progression-Gates mit Eskalationsketten (kaelte/hitze/hunger/kannibalismus; je Stufe schwelle, emoji, grund, wirkung, verhalten; letzte Stufe greift per folge_mod_id in die nächste Kette) | `Pop_MoodModifikatorRegistry` -> `Pop_MoodMaschine` (wählt stufe_fuer aus der Not) -> `Pop_Denkblase` (Grund+Wirkung im Emoji-Stil) + `Einheit_VitalStatus.umgebungsschaden_anwenden()` + `_in_sicherheit_bringen()` |
| `game/data/job_config.json` (kannibale) | Autonomer Kannibalen-Job: eigener Ziel-Knoten OWN, schnelle Schläge, Fleisch wie die Tierjagd | `Einheit_Manager._pruefe_verhalten` (Auslöser aus der Hunger-Kette, schwächster Nachbar) -> `Einheit_ZielSuche` (OWN-Quelle) -> `Einheit_ErnteMaschine._kannibale_schlag` (Vital-Pfad schaden_nehmen) |
| `world/data/element_katalog.json` (lagerfeuer) | Wärmequelle je Feuer, Radius 5 Kacheln abfallend | `Welt_WaermeFeld` (quellen_setzen, waerme_an je Weltposition deterministisch) |
| `world/logic/kategorie_tageszyklus/tageszyklus_maschine.gd` | Tageszyklus an der Weltuhr: Takt, Tag- und Nachtanteil kommen aus `weltrhythmus` in needs.json (aktuell 2 Minuten mit 1,5 Tag und 0,5 Nacht), dazu Helligkeit und Schablonen-Alpha wie Pappe-Schieber | `Welt_TageszyklusMaschine` (tick an Weltuhr, phase_geaendert) -> `tageszyklus_overlay.gd` (CanvasLayer färbt Welt) + `Welt_WaermeFeld` (Grundkälte nachts) |
| `population/scenes/verteilung_dialog.gd` | Isolierte Window-Szene zur Verteilung (0.8 Nahrung je Einheit je Takt konfigurierbar) | `Einheit_Manager.verteilung_setzen()` via Strg+V, Einblend als eigenes Window |
| `economy/data/lager.json` | Lager-Templates mit Kapazität und welt_objekt_id | `Lager_Registry` -> `Lager_Manager` (lokale Instanzen, Mutationen) |
| `game/data/orchestrator_config.json` | Zonen mit Bedarf je Ressource und Job | `Orchestrator_Registry` -> `Orchestrator_Manager` |
| `shinon/shinon_init.py --readme` | Lebendige README als Pitch von Shinon, gamer orientiert, vierte Wand | `ShinonReadmeGenerator` |

## 5b. Welt-Hierarchie und Determinismus

Die Welt ist ein Makromodell. Der autoritative Weltseed liegt ausschließlich im `Welt_Model` (`welt_seed`) und wird mit dem Weltzustand persistiert (Speicherversion 5). Keine Szene, keine Region und keine Lokalkarte besitzt eine eigene Seedquelle; die aktuelle Zeit erzeugt keinen Seed. Der Seed-Wunsch einer Neuen Welt wird über `Kern_Zufall.abgeleitet_fuer` deterministisch aus bestehendem Weltbestand und Namen abgeleitet, niemals aus der Uhrzeit.

Hierarchie: `WORLD SEED -> WORLD STATE -> REGION -> REGION PROFILE (Biom) -> LOCAL MAP (Kartengröße aus Daten) -> CHUNK -> OBJECT`.

Jede Region wird aus `Kern_Zufall.abgeleitet_fuer(welt_seed, region_identitaet)` gezogen, jeder Chunk aus `Kern_Zufall.abgeleitet_fuer_chunk(welt_seed, chunk_x, chunk_y)`. Gleicher Seed plus gleiche Koordinate ergibt damit immer denselben Zustand, unabhängig von der Erzeugungsreihenfolge. `Welt_GrenzProfil` leitet Nachbarschaften aus der Koordinatenstruktur ab und liefert das Randprofil (Biom-Paarung, Abstand) ohne manuelles Nachbarschafts-Array.

Kartengrößen (max/min, Kachel, Chunk, Regionkante) kommen aus `world/data/welt_definition.json` über `Welt_DefinitionRegistry`; der Generator hat keine Sonderfälle für 25/50/75/100 Prozent, sondern leitet den Flächenanteil deterministisch aus dem Seed ab. `region_materialisieren()` und `chunk_materialisieren()` erlauben einzelne Regionen/Chunks ohne Materialisierungspflicht der ganzen Welt.

## 5c. World-Ebene (World ↔ Map)

Die World ist der Anker über allen Karten einer Partie. `Welt_World` hält die Liste der Maps (`Welt_Model`-Instanzen), markiert genau eine Map als Basis (`basis_map_id`) und verwaltet die Zuordnung über `map_id`. Sie besitzt keine eigene Zeit, keinen Zufall und keine Generierung: Der Tick bleibt bei `Kern_Weltuhr`, die Erzeugung beim `Welt_Generator`, der Zufall bei `Kern_Zufall`.

Persistenz: `Welt_Speicher.world_speichern`/`world_laden` sichern die World als eine Datei mit allen Maps; alte Einzelwelt-Dateien bleiben über die bestehenden Funktionen ladbar (Abwärtskompatibilität) und erhalten beim Laden eine Ein-Map-World als Erbe. `Ui_WeltSitzung` trägt nur den Verweis auf die World und die aktive map_id zwischen Szenenwechseln; sie besitzt keine eigene Kartenwahrheit. `Welt_Ladevorgang` übernimmt beim Laden die geladene Instanz der aktiven Map als laufende Instanz der Szene (`Welt_World.model_uebernehmen`), sodass Szene und World dasselbe `Welt_Model`-Objekt teilen (genau eine Kartenwahrheit), und erzeugt bei einem neuen Spiel eine frische World, die das Szene-Modell direkt als Basis-Karte aufnimmt. Speichern läuft über dieselbe Instanz-Übernahme im Pause-Menü; es gibt keinen Wörterbuch-Kopierpfad und keine veraltete Zweitinstanz mehr.

Erzeugung: `Welt_MapFabrik` ist die einzige Stelle, die neue Karten generiert und in die World einträgt. Die erste Karte entsteht als Basis (`basis_karte_erzeugen`); die Expansion (`neue_karte_erzeugen`) leitet den Seed deterministisch aus dem World-Bestand ab (kein Zeit-Seed), erzeugt die Karte über den Generator, trägt sie ein und markiert sie als neue Basis. Die Kontext-Aktion `Expansion: Neue Basis-Karte` in `steuerung.json` (logik_id `expansieren`) löst sie über die Eingabe-Steuerung aus; `welt.gd` übernimmt das neue Modell und stellt alle Beobachter und Manager auf die Karte um, während die alte Karte in der World gespeichert bleibt.

## 5d. Produktionsökonomie (Gebäude und Ketten)

Die Produktionsökonomie ist eine geschlossene Kette über bestehende Domänen: `Weltobjekt -> Arbeit -> Rohstoff -> Lager -> Gebäudekosten -> Gebäude -> Produktionsauftrag -> Zeit -> Output -> Lager -> neuer Bedarf`.

Datenbesitzer: `world/data/gebaeude.json` beschreibt jedes Gebäude mit ID, Name, Kategorie, Icon, Weltobjekt-ID, Baukosten, Bauzeit, Arbeitskraft, Voraussetzungen und Produktionsrezept (Eingänge mit Mengen, Ausgänge mit Mengen, Dauer in Ticks, Wiederholbarkeit, Blockierregeln). `Gebaeude_DefinitionRegistry` ist die einzige Erweiterungsgrenze: Ein neues Gebäude entsteht ausschließlich über einen Katalog-, Gewichte- und Gebäude-Eintrag plus Asset, ohne Änderung an Maschinen oder Manager. Die Bau-Aktionen des Kontextmenüs kommen aus `game/data/steuerung.json` (logik_id `bauen`, gebaeude_id), das Menü ist damit ebenfalls datengetrieben.

Maschinen: `Gebaeude_BauMaschine` verarbeitet nur den Bauzustand (nicht gebaut, Bau angefordert, Bau läuft, fertig) über die Weltuhr; `Gebaeude_ProduktionsMaschine` verarbeitet nur den Produktionszustand (deaktiviert, wartet auf Eingang, Produktion läuft, wartet auf Ausgangslager, abgeschlossen) und meldet Aktionen (`input_ziehen`, `output_legen`). Beide besitzen keinen eigenen Timer.

Koordination: `Gebaeude_Manager` tickt beide Maschinen, prüft und entnimmt Kosten über `Einheit_Ressourcen`/`Lager_Manager`, lagert Ausgänge über die bestehende Erntebuchung ins nächste Lager ein und schreibt Bau-/Produktionszustand als Objekt-Zusatzfelder ins `Welt_Model`, die mitpersistiert werden. Die HUD-Anzeige (`hud_produktion_anzeige.gd`) liest nur Statuszeilen.

Aktive Ketten: Werkstatt (15 Holz + 8 Stein, 480 Ticks Bau, verbraucht 6 Holz + 3 Stein zu 1 Werkzeug in 600 Ticks) und Räucherei (20 Holz + 12 Stein, 720 Ticks Bau, verbraucht 3 Fleisch + 2 Holz zu 1 Räucherfleisch in 900 Ticks) — beide über denselben Datenpool und dieselbe Produktionsmaschine, ohne Code-Sonderfall.

Darstellung: Die Funktions-Animationen der Objekte (Werkstatt `grind`, Räucherei `raeuchern`, Lagerfeuer `flackern`, Busch `wehen`) sind Registry-Daten: Der Element-Katalog-Eintrag nennt die Animation über `funktions_animation`, das Animations-Verzeichnis `game/data/animationen.json` hält Sheet, Frame-Größe und `ticks_pro_frame`, und der `Welt_ObjektDarsteller` in `world/logic/kategorie_welt/` schneidet die Frames und spielt sie mit 24 geteilt durch `ticks_pro_frame` Schritten pro Sekunde ab, gekoppelt an die 24 Ticks der Weltuhr. Frame 1 eines jeden Sheets ist exakt das Standbild; ein Objekt ohne Registry-Animation wird nie animiert.

## 5e. Zentrale Modifikator-Logik (Trait-Boni und Zeiten)

Trait-Boni, Modifikator-Zeiten und Bauzeiten laufen durch eine zentrale Rechenlogik: `Kern_ModifikatorMaschine`. Jede State-Maschine hält ihre eigene Instanz mit genau einem Bereich (Bau-Maschine → `bau`, Produktions-Maschine → `produktion`, Einheit-Bewegung → `bewegung`) und damit ihre eigenen angepassten Settings; die Rechenformeln sind trotzdem genau eine zentrale Logik.

Datenbesitzer: `core/data/modifikator_settings.json` (global einstellbar) definiert je Bereich den aktiven Modus, die Faktor-Grenzen und die Bewegungs-Basiswerte; der Modus verweist auf einen Modifikator aus `core/data/kern_modifikatoren.json` (normal, schnell, langsam, aggressiv). Balancing ändert nur diese Dateien, nie den Code.

Formeln (einzige Stellen im Projekt): Zeit = Basis-Ticks geteilt durch Bereichsfaktor (`zeit_berechnen`, min 1 Tick), Geschwindigkeit = Basis mal Bereichsfaktor (`geschwindigkeit_berechnen`). Die Trait-Formel `wert_berechnen` aggregiert aktive Modifikatoren (Faktor multiplikativ, Attributwerte additiv) und wird von `Einheit_VitalStatus` für Geschwindigkeit und Tragekraft delegiert statt inline gerechnet.

Keine redundanten Rechenschritte: Der Bereichsfaktor wird einmal berechnet und gecacht. Die Modifikator-Registry wird im ganzen Projekt genau einmal geladen: `Kern_ModifikatorRegistry.geteilte()` ist der einzige Bezug für die Maschinen und für `modifikator_erzeugen`, ein zweiter Ladepfad der Modifikator-Daten existiert nicht. Erst wenn ein Menü geöffnet wird, emittiert der Signalbus `menue_geoeffnet` (Kontextmenü und Hauptmenü melden sich), die Maschinen aktualisieren ihre Faktoren, und `Gebaeude_Manager` stimmt alle Gebäude-Fortschritte prozentual auf die neuen effektiven Zeiten ab (`abstimmen` in Bau- und Produktionsmaschine, `ziel_ticks` als Objekt-Zusatzfeld mitpersistiert). Die Bewegungs-Basiswerte in `einheit_status.gd` kommen aus den Settings, nicht aus Konstanten.

## 5f. Need-Baum und Rassen-Schemata

Das Need-System ist ein eigener Baum: `Pop_NeedBaum` hängt als struktureller Anker unter der Welt-Szene (`world/scenes/welt.gd`), hält die Registries der Domäne (Need-Typen aus `needs.json`, Rassen-Schemata aus `rassen_schemata.json`) und erzeugt je Einheit eine `Pop_MoodMaschine` als echtes Node-Kind mit zugewiesenem Rassen-Schema. Der Baum tickt nicht selbst: Der Tick-Fluss bleibt beim `Einheit_Manager`, der die Maschinen über Referenzen anspricht; der Baum sorgt nur für Struktur, Schema-Zuordnung und Erzeugung.

Rassen-Schemata: `population/data/rassen_schemata.json` definiert je Rasse Multiplikatoren (mensch neutral, elf genügsam/flink, ork gefräßig/zäh) für Nahrungsverbrauch, Dringlichkeit, Abfall, Schwellwert und Bewegung. `Pop_RassenSchemaRegistry` ist die einzige Erweiterungsgrenze: Neue Rassen entstehen nur über Datenpool + Registry. Jede Need-Maschine hält ihre eigene `Kern_ModifikatorMaschine` mit dem Bereich `need` (zentrale Settings) und skaliert ihre Raten über Schema-Multiplikator mal zentralen Faktor (`dringlichkeit_fuer`, `abfall_fuer`, `schwellwert_fuer`, `nahrungs_faktor`).

Vergabe: `Einheit_Manager.einheit_hinzufuegen(position, rasse)` ordnet die Rasse beim Spawn zu (Standard-Rasse aus dem Baum, sonst neutral), speichert sie an der Einheit, reicht den Rassen-Bewegungsfaktor über `Einheit_Status.rasse_faktor_setzen()` in die Zustandsmaschine (wirkt multiplikativ auf die zentrale Geh-Geschwindigkeit) und verteilt die Nahrung je Einheit über deren kombinierten Rassen-Faktor.

## 5g. Zustands-Timeline (Warum ist das so)

`Kern_Timeline` (core/logic/kern_timeline.gd) mit `Kern_TimelineEintrag` (core/logic/kern_timeline_eintrag.gd) ist die zentrale Zeitlinie aller Zustandsänderungen. Sie ist kein Dump: Sie hält einen Ursprungs-Snapshot plus jede Mutation als Delta-Eintrag (nur die betroffenen Schlüssel mit vorher/nachher, Quelle, Beschreibung, Modifikator-ID und Faktor). `zustand_zu_tick(tick)` rekonstruiert den Zustand zu jedem Zeitpunkt aus Ursprung plus Deltas, `warum(ziel_id)` liefert die Begründungskette eines Ziels in zeitlicher Reihenfolge, `einfluss_modifikatoren()` aggregiert, welche Modifikatoren wie oft mit welchem Faktor gewirkt haben. Keine Zeit, kein Zufall, keine Simulationslogik in der Timeline: Sie protokolliert nur, was andere Zuständigkeiten melden.

Anbindung: `Einheit_Ressourcen.timeline_setzen(timeline)` setzt den Ursprungs-Snapshot der Bestände und protokolliert jede Buchung (einlagern, entnehmen, mehrfach_entnehmen, Rückbuchung) als Delta. Die Welt-Szene erzeugt die Timeline als eigene Spitze, verbindet `eintrag_neu` mit dem HUD (`hud_status_anzeige.timeline_anzeigen`) und dem Signalbus (`timeline_eintrag`), sodass jede Buchung als Begründung sichtbar wird. Damit bleibt die Frage warum ist das so jederzeit intern und für den Spieler beantwortbar, und der Einfluss aller Modifikatoren ist zukünftig kombinierbar visualisierbar.

## 6. RT Pyramide

Die Architektur ist eine echte Pyramide mit modularer Spitze. Basis: `Welt_Model` haelt nur Daten. Darueber: Registries halten alle exakten Datenklassen zentral und zeigen je Eintrag auf ein sichtbares Asset, Logiken und Modifikatoren sind generisch wiederverwendbar. Darueber: State Maschinen und Mutationsmaschinen mit je genau einer Verantwortung. Spitze: Endszene `world/scenes/welt.tscn` komponiert alle Untersysteme, besitzt aber selbst keine Logik und wird durch die Untersysteme modular bestimmt. `prototyp_karte.*` wurde restlos entfernt.

Schnittstellenregel (geschlossen): Jede Manager-Interna ist privat; nur lesende Methoden freigegeben. Tests und Beobachter nutzen genau denselben Schnittpunkt wie das Spiel.

Regeln der Pyramide:

1. Objekte sind Basis: `Welt_Model` wirkt nur ueber Mutationen auf Zustand, nie direkt.
2. Registries sind getypte Tabellen: jede Datenklasse entsteht nur in ihrer Registry, nirgends doppelt.
3. State Maschinen aendern Zustaende, Mutationsmaschinen mutieren Zustaende, nie umgekehrt und nie gemischt.
4. Biome wirken nur als `Welt_BiomMutation` ueber `Welt_BiomManager` auf den Zustand, ein Biom ist nur eine Kombi aus logik_id, modifikator und faktor.
5. Logiken werden wiederverwendet, nie geteilt: dieselbe Logik laeuft fuer Eisbär und Bär, aber nie zwei verschiedene Dinge durch dasselbe System.
6. Zeit ist zentral: nur `Kern_Weltuhr.ticks_aus_faktor()` rechnet faktor -> ticks, alle anderen delegieren dorthin. Faktor 1.0 bedeutet 10 Sekunden auf 24 Hz.
7. Darstellung liest nur Daten, nie Logik direkt.

## 6b. Globale Zeit

Es gibt genau einen globalen Tick: das Autoload `Weltuhr` (Klasse `Kern_Weltuhr`, 24 Ticks/Sekunde, klassischer RTS-Standard). Jede State Machine abonniert `Weltuhr.tick`; keine Domäne besitzt eine eigene Weltzeit. Darstellung läuft über die Frames der Sprite-Sheets, deren Geschwindigkeit an die 24 Ticks gekoppelt ist.

## 7. Domänengrenzen

1. **UI-Domäne** (`ui/`): Menüführung, Weltauswahl, Sitzungszustand. Sie ruft Szenen auf und schreibt `WeltSitzung`; sie ändert keine Welt-Daten.
2. **Welt-Domäne** (`world/`): Modell, Speicher, Registry, Renderer, Editor, Tiere, Orchestrator-Zonen. Der Renderer liest nur `Objekt_Basis`-Felder; der Editor schreibt nur über `Welt_Model`-Funktionen. Zonen lesen Bedarf und vergeben Jobs nur über `Einheit_Manager`.
3. **Game-Domäne** (`game/`): Jobs, Einheiten, Ressourcenbestände, Vitalstatus. `Einheit_Manager` verbindet Welt (Ziele), Tiere (Jagd), Lager (verortete Bestände), Tageszyklus (Tick), Wärmefeld (Feuer-Quellen) und Vitalstatus (Verletzungen + Umgebung sperren/ziehen HP), kennt aber keine Darstellungsdetails. Seit dem autonomen Verhaltens-Slice prüft der Manager im eigenen Idle die Hunger-Kette: Erreicht ein Stickman das Kannibalismus-Stadium, jagt er den schwächsten Nachbarn (einheit_hp, nobody jagt sich selbst), solange weder ein jagdbares Tier in Reichweite noch Fleisch im Lager ist; der Job läuft als Ziel-Typ OWN über dieselben Maschinen (Ziel-Suche, Arbeitsschritt, Vital-Pfad schaden_nehmen), die Blase erzählt die Tat über bereich_hervorheben. Die Einheit trennt zwei Maschinen: `Einheit_Status` führt nur den Arbeitsloop, `Einheit_VitalStatus` hält Leben und physische Modifikatoren und meldet Schaden und Tod über den Signalbus (plus Umgebungsschaden aus Waerme-Gates). Pro Einheit hängt eine `Pop_MoodMaschine` (Tick + Zustand-Übergänge Job->Idle->Transport + Waerme je Kachel + Mood-Modifikatoren) und eine `Pop_Denkblase` daran – eine reine Beobachter-Spitze, die nur zeichnet. Der Manager verbraucht je Takt die im Abschnitt weltrhythmus hinterlegte Menge Nahrung je Einheit (verteilt konfigurierbar), bei Mangel HP-Abzug; dieselbe Taktlänge steuert den Tageszyklus.
3b. **Population-Domäne** (`population/`): Bedürfnisse und Stimmung. `Pop_NeedRegistry` liefert die Typen (nahrung + waerme aus Feuer-Helligkeit), `Pop_MoodMaschine` sammelt Needs je Tick, liest das Wärmefeld je Stickman-Position und Tageshelligkeit, wertet Mood-Modifikatoren (kaelte/hitze als Progression-Gates mit in_sicherheit_bringen + HP-Abzug) und leitet daraus eine `Pop_Mood` (Emoji + Sprechblase) ab; seit den Eskalationsketten wählt sie je Mod die erreichte Stufe (stufe_fuer über die Datenschwellen) und trägt Grund, Wirkung, Verhalten und Kette in die Mood ein, die `Pop_Denkblase` als zweizeilige Emoji-Erzählung zeigt; die Hunger-Kette verzahnt per folge_mod_id in die Kannibalismus-Kette (Autonomie-Schnitt für Verhalten), `Pop_Denkblase` liest nur diese Mood und schwebt über dem Stickman. `Pop_MoodModifikatorRegistry` liefert die Gates aus `mood_modifikatoren.json`, Erweiterung nur über Pool+Registry. Die Wärme-Gates lesen ihren Schwellwert ausschließlich aus dieser Registry: `Pop_MoodMaschine` entscheidet Stimmung, Wärmebedarf und Fluchtziel damit, `Einheit_VitalStatus.umgebungsschaden_anwenden` wertet denselben Schwellwert für den HP-Abzug aus; hart codierte Grenzwerte daneben sind als Doppelpfad entfernt.4. **Economy-Domäne** (`economy/`): Lokale Lager (Lager_Basis je Typ in `economy/data/lager.json`, verortete Instanzen im `Lager_Manager`). Einheiten lagern Ernte im nächsten Lager ein; globale Bestände sind nur die Summe für das HUD. Wachstum (Haus + 3 Nahrung -> neuer Stickman) entnimmt aus dem nächsten Lager.
5. **Core-Domäne** (`core/`): Weltuhr (einziger Tick), Zufall (`Kern_Zufall` als einzige Quelle), Mutationen, Modifikatoren (`Kern_ModifikatorBasis` mit Dauer und Heilbarkeit) und Signalbus (`Kern_SignalBus` als `Node`-Autoload). Zufall fließt nur in Mutationen und Vitalstatus über `Kern_Zufall.zahl_bereich()`.

Szenen (`*/scenes/`) sind Ansichten: Eingabe und Darstellung, keine Simulationslogik.

## 7c. Besitz und Erweiterungsgrenze je Domäne (TASK 02 Architektur-Lock)

Diese Tabelle ist die verbindliche Antwort auf vier Fragen je Domäne: Wer besitzt die Daten, wer erzeugt Instanzen, welche Maschine verarbeitet sie, und über welche Grenze wächst der Inhalt ohne Code-Kontakt mit der Maschine.

1. **Kern:** Datenbesitzer sind `kern_modifikatoren.json` und `modifikator_settings.json` über `Kern_ModifikatorRegistry.geteilte()` (genau eine Ladung). Erzeugung: Maschinen-Instanzen werden von ihren besitzenden State-Maschinen gehalten, die Registry-Daten fließen über `Kern_ModifikatorMaschine`. Erweiterungsgrenze: neuer Modifikator nur als Eintrag in `kern_modifikatoren.json`, neue Rechenbereiche nur als Bereich-Eintrag in `modifikator_settings.json`, nie eine zweite Formel. Die `Kern_LogikRegistry` ist als geteilte Instanz (genau eine Ladung) verdrahtet: Objekt_Basis und Tier_Basis lösen ihre logik_id über `faktor_fuer` auf, `effektiver_faktor` (eigen × Logik-Basisfaktor) fließt über den Einheiten-Manager in `Job_Basis.ziel_faktor_setzen` und skaliert `harvest_zeit_ticks`. Erweiterungsgrenze: neue Logik nur als Eintrag in `kern_logik.json`, neuer Faktor nur im Katalog- oder Tier-Eintrag, nie eine zweite Zeitformel.
2. **Welt-Objekte und Tiere:** Datenbesitzer sind `element_katalog.json` und `tier_verhalten.json`. Erzeugung: `Objekt_RegistryBasis._objekt_klasse_fuer` lädt die Datenklasse über das script-Feld des Katalog-Eintrags (Existenz- und Typprüfung wie bei Jobs und Needs); alle zehn Objekte mit eigener Klasse tragen dieses Feld, die zentrale Zuordnung in `Welt_Registry._zentrale_klasse_fuer` bleibt nur Übergangs-Fallback für Einträge ohne script. `Tier_Registry._tier_klasse_fuer` ordnet die Tierklassen zentral zu. Spawn nur über Generator-Gewichte (`generator_gewichte.json` Cluster mit Biome-Liste und Chance) beziehungsweise `Welt_TierPlatzierer` (typ `bewegt`). Erweiterungsgrenze: neues Objekt über Katalog-Eintrag mit script-Feld plus Asset (geprüft durch `Kern_AssetPruefer`), ohne Änderung an Registry oder Maschine; neues Tier über Katalog, Verhaltenswerte, Tier-Klasse und Cluster-Eintrag, ohne Änderung an Status, Manager oder Darsteller.
3. **Jobs und Einheiten:** Datenbesitzer sind `job_config.json` (script-Feld für alle sechs Jobs) und `ressourcen.json` (script-Feld für alle fünf Ressourcen inklusive Raeuchelfleisch). Erzeugung: `Job_Registry._job_erzeugen` lädt das script mit Existenz- und Typprüfung; `Einheit_Ressourcen._ressourcen_klasse_fuer` lädt ebenfalls über das script-Feld, die zentrale Zuordnung bleibt Fallback. `Einheit_Manager` besitzt die Einheiten und tickt sie. Erweiterungsgrenze: neuer Job nur als Klasse plus script-Eintrag im Pool; neue Ressource nur als Pool-Eintrag mit script-Feld plus Icon, ohne Änderung an der Verwaltungsklasse.
4. **Population:** Datenbesitzer sind `needs.json` (script-Felder) und `rassen_schemata.json`. Erzeugung: `Pop_NeedBaum` hält die Registries und erzeugt je Einheit die `Pop_MoodMaschine`; `Pop_RassenSchemaRegistry` ist die einzige Rassen-Grenze. Erweiterungsgrenze: neues Need nur als Klasse plus script-Eintrag, neue Rasse nur als Schema-Eintrag, keine Änderung an der Mood-Maschine.
5. **Gebäude und Produktion:** Datenbesitzer sind `gebaeude.json` und `generator_gewichte.json` (Cluster-Regeln). Erzeugung: `Gebaeude_DefinitionRegistry` als einzige Erweiterungsgrenze, Bau- und Produktionsmaschinen sind generisch. Erweiterungsgrenze: neues Gebäude nur als Katalog-, Gewichte- und Gebäude-Eintrag plus Asset; eine neue Produktionskette ist ein Rezept-Eintrag, kein Code-Sonderfall.
6. **Economy:** Datenbesitzer sind `lager.json`. Erzeugung: `Lager_Registry` lädt die Templates, `Lager_Manager` hält die verorteten Instanzen, Buchung läuft ausschließlich über `Lager_MutationEinlagern`/`Entnehmen`. Erweiterungsgrenze: neuer Lagertyp nur als Template-Eintrag.
7. **World- und Karten-Ebene:** Datenbesitzer sind `welt_definition.json` und `biome.json`. Erzeugung: `Welt_Ladevorgang` ist die einzige Laden-und-Erzeugen-Stelle, `Welt_MapFabrik` die einzige Karten-Erzeugung, `Welt_Speicher` die einzige Persistenz. Besitz: genau eine Kartenwahrheit, die World zeigt auf dieselbe `Welt_Model`-Instanz wie die Szene (`model_uebernehmen`), `Ui_WeltSitzung` trägt nur den Verweis. Erweiterungsgrenze: neue Karte nur über die Fabrik, nie eine zweite Erzeugungs- oder Speicherstelle.
8. **UI:** Datenbesitzer sind `steuerung.json` (Kamera, Auswahl, Kontext-Aktionen mit logik_id). Erzeugung: `Ui_EingabeSteuerung` und `Ui_KameraSteuerung` übersetzen Eingabe in Maschinen-Aufrufe; Panels sind gepackte Szenen, die nur lesen. Erweiterungsgrenze: neue Kontext-Aktion nur als Eintrag mit logik_id plus einem Decode-Zweig; die UI erfindet keinen Zustand und rechnet keine Fachwerte.

Gemeinsame Grenzregel: Eine Erweiterung wächst immer als Daten plus Asset in die Registry ihrer Domäne; eine Maschine wird nur dann berührt, wenn eine nachgewiesene, fachlich fehlende Fähigkeit vorliegt, und dann als eigener Infrastruktur-Slice mit Verifikation, nicht als versteckter Sonderfall im Inhalt.

## 7d. Verbindungswege (Einzelpfade nach Verbindungs-Audit)

Jede Beziehung besitzt genau eine verantwortliche Anbindung; diese Liste beschreibt den geprüften Ist-Zustand.

1. **Tick:** Nur `Kern_Weltuhr.tick` ist Simulationstakt. Manager und Bau-Maschinen verbinden sich je genau einmal mit Wächter (`is_connected`-Prüfung) in `_enter_tree`/`_ready` und trennen in `_exit_tree`. `Welt_TageszyklusMaschine` wird ausschließlich von `welt.gd` verbunden. Kurzlebige Feedback-Anzeigen verbinden in `_enter_tree` und trennen in `_exit_tree`. `Pop_MoodMaschine` und Jobs abonnieren nichts selbst: Ihr Takt läuft nur über den `Einheit_Manager`. Es gibt keinen zweiten Simulationstakt und keine `_process`-Fachlogik.
2. **Ernte-Kette:** `Job_Basis.arbeitsschritt_erledigt` geht an `Einheit_Status` (Weiterleitung) und von dort an `Einheit_Manager`, der mit `bind(status)` den absendenden Status festlegt; beide Pfade desselben Arbeitsschritts (Ernte-Signal und Loop-Signal) landen auf demselben Empfänger und buchen exakt einmal über `Einheit_ErnteMaschine`. Nur die arbeitende Einheit bucht, kein Sammel-Lauf über alle Einheiten.
3. **Wärme-Gates:** Eine Schwellwert-Quelle (`Pop_MoodModifikatorRegistry`), zwei Leser (`Pop_MoodMaschine`, `Einheit_VitalStatus`), keine Code-Konstante daneben.
4. **Modifikator-Daten:** Eine Ladung über `Kern_ModifikatorRegistry.geteilte()`, Verbraucher sind die Maschinen-Instanzen und `modifikator_erzeugen`.
5. **Aktivierung:** `welt.gd _ready` ist der einzige Erstaktivierer von Lager-Fabrik, Tier-Platzierer und Wärme-Sammler; die Expansion ruft dieselben Spitzen erneut über denselben Weg auf (bewusste Mehrfach-Aktivierung, jede Lager- und Tier-Platzierung erzeugt neue Instanzen, es gibt keine zweite Registrierung desselben Objekts).
6. **Maschinen-Signale** (`zustand_geaendert`, `beute_erlegt`, `mood_geaendert` und Folge-Signale) werden genau einmal an ihrer Erzeugungsstelle im besitzenden Manager verbunden; keine `_ready`-Zweitverbindung, keine Registry-Zweitverbindung.

## 8. Preflight: Ausführung und Fehlercodes

Ausführung aus dem Projektstamm vor jedem Commit:

```bash
python tools/preflight.py
```

Die Ausgabe listet zuerst alle Datenobjekt-Erzeugungen mit Datei, Klasse und Zeile (exakte Datennamen), dann die Befunde. Exit-Code 0 heißt abnahmefähig.

| Code | Bedeutung | Behebung |
| --- | --- | --- |
| E001 | Klasse ohne Kategorie-Präfix | Präfix laut Tabelle Abschnitt 1 vergeben |
| E002 | Doppelter oder ähnlich klingender Klassenname | Klasse eindeutig umbenennen |
| E003 | Klasse liegt nicht im Ordner ihrer Kategorie | Datei in den Kategorie-Ordner verschieben |
| E004 | Logik-Skript ohne `class_name` | Namen vergeben (Ausnahme: `*/scenes/`-Ansichten) |
| E006 | Daten-Arrays ohne Markierung `## Kategorie daten` | Markierung ergänzen |
| E007 | Daten-Arrays ohne Markierung `## Kategorie logik` | Markierung ergänzen |
| E008 | Unzulässiges Zeichen `:` im Klassennamen | Namen korrigieren |
| E009 | Unzulässiges Zeichen `,` im Klassennamen | Namen korrigieren |
| E010 | Getyptes Array mit unbekanntem Datenklassen-Typ | Typ auf echte Klasse ändern oder Primitive verwenden |
| E011 | Datei nicht als UTF-8 lesbar | Datei als UTF-8 speichern |
| E030 | Shinon Banner Verbot verletzt | Banner Zeile entfernen, keinen dekorativen Rahmen verwenden |
| E031 | Shinon Bullet Verbot verletzt | Bullet entfernen, stattdessen nummerierte ganze Sätze verwenden |
| E032 | Shinon Nummerierung verletzt | Jede inhaltstragende Zeile als 1. Satz. 2. Satz. lückenlos nummerieren und mit Punkt enden |
| E033 | Shinon Bildsprache verletzt | Technische Pfad Litanei durch bildliche Erzählung in ganzen Sätzen ersetzen, mindestens fünf Wörter je Satz |
| E034 | Shinon commit_msg fehlt oder leer | Datei shinon/commit_msg.txt in nummerierten bildlichen Sätzen erstellen |
| E023 | RT Pyramide: doppelte Berechnung oder System faehrt zwei Dinge | Berechnung nur in Kern_Weltuhr zentral, System nur eine Verantwortung, hart codierte Tier Weichen entfernen |
| E024 | Biom Pflicht: wirkt nicht als Mutation | Biome nur als Welt_BiomMutation ueber Welt_BiomManager an Welt_Model, world/data/biome.json pflegen |
| E035 | Shinon README Pflicht verletzt | README via python shinon/shinon_init.py --readme neu erzeugen, Pitch aus Shinon Sicht mit Zustand Vision und vierter Wand |
| E036 | Steuerung Pflicht verletzt | game/data/steuerung.json menschlich mit WASD Linksklick Drag Rechtsklick sammeln abbauen Icon Tooltip Werkzeug fuellen |
| E037 | Shinon Footer Verbot verletzt | Agent-Footer oder Werkzeug-Signatur aus shinon/commit_msg.txt entfernen, die Nachricht gehört Shinon allein |
| E038 | Shinon Nennungspflicht verletzt | Jede geänderte Datei in shinon/commit_msg.txt namentlich mit Dateinamen nennen |
| E039 | Shinon Stilpflicht verletzt | Sätze auf höchstens 400 Zeichen kürzen, Endlos-Aufzählungen mit mehrfachem und dann auflösen, die Nachricht auf höchstens 2600 Zeichen insgesamt schlank halten |

## 9. Pflichten bei Änderungen

1. Neue Klasse: Präfix vergeben, in den Kategorie-Ordner legen, ggf. Datenklassen-Erzeugung registrieren, Architektur.md in Abschnitt 1 und 3 ergänzen.
2. Neues Datenobjekt: eigene Klasse in `kategorie_*` anlegen, Registry-Erzeugung ergänzen, Tabelle Abschnitt 3 pflegen.
3. Neue zentrale Config: Datei in Abschnitt 4 eintragen.
4. Umbenennung: alle Referenzen (`.gd`, `.tscn`, Autoloads in `project.godot`) anpassen, Preflight und `godot --headless` laufen lassen, Architektur.md mitpflegen.
5. Vor jedem Commit: `python tools/preflight.py` muss fehlerfrei enden. Dazu gehört das Shinon Gate. Erst shinon/commit_msg.txt in nummerierten bildlichen Sätzen ohne Banner und ohne Bullet füllen, README via shinon/shinon_init.py --readme frisch halten, dann Preflight laufen lassen. Ohne grünes Shinon Gate ist kein Commit erlaubt.
6. Init nur über `python shinon/shinon_init.py --init`, Prüfung nur über `--check`, GitHub nur über `--github`. Niemals Zustand aus anderen lokalen Projekten kopieren, nur gh Token verwenden.
