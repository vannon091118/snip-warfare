# Architektur.md – Pflichtdokumentation

Diese Datei ist die verbindliche Pflichtdokumentation der Projektarchitektur. Sie wird aktiv gepflegt: Jede Änderung an Klassennamen, Kategorien, Datenfeldern oder Domänengrenzen wird hier sofort mitgepflegt. Vor jedem Commit wird `python tools/preflight.py` ausgeführt; nur ein fehlerfreier Preflight (Exit-Code 0) gilt als abnahmefähig.

## 1. Domänen und Kategorien

Jede Klasse trägt ihre Kategorie als Präfix im Klassennamen und liegt im passenden Kategorie-Ordner. Kategorien sind fachliche Zugehörigkeiten, keine technischen Sammelordner.

| Präfix | Kategorie | Ordner | Inhalt |
| --- | --- | --- | --- |
| `Kern_` | Zentrale Engine-Dienste | `core/` | Weltuhr (einziger globaler Tick), Asset Pflicht Gate, Zufall (Kern_Zufall), Modifikatoren, Signalbus (Kern_SignalBus) |
| `Lager_` | Lokale Speicher | `economy/logic/storage/` | Basis (Typ), Registry (Templates), Manager (Instanzen je Ort), Mutationen (Einlagern, Entnehmen) |
| `Orchestrator_` | Zonen-Orchestrator | `world/logic/kategorie_orchestrator/` | Konfiguration, Status, Manager (Bedarf -> Jobvergabe), Registry |
| `Shinon_` | Commit Gate | `shinon/` | Banner Banner Pruefer, Bullet Pruefer, Nummerierung Pruefer, Bildsprache Pruefer, Gate Orchestrator |
| `Objekt_` | Weltobjekt-Datenklassen | `world/logic/kategorie_objekt/` | Kachel, Baum, Baumstumpf, Stein, Steingruppe, Haus, Hausgross, Basis |
| `Resources_` / `Resource_` | Ressourcen-Datenklassen | `game/logic/kategorie_ressourcen/` | Wood, Stone, Meat, Basis |
| `Tier_` | Tier-Datenklassen und Tier-Verhalten | `world/logic/kategorie_tier/` | Baer, Hase, Vogel, Vogelgruppe, Basis, Verhalten, Status, Darsteller, Manager |
| `Job_` | Job-Zustandsmaschinen | `game/logic/kategorie_job/` | Holzfaeller, Steinmetz, Jaeger, Basis, Registry |
| `Einheit_` | Spielfiguren-Domäne | `game/logic/kategorie_einheit/` | Status, Darsteller, Manager, Ressourcen |
| `Welt_` | Welt-Zustandsmaschinen und Dienste | `world/logic/` | Model, Registry, Speicher, Renderer (kategorie_welt), EditorWerkzeug (kategorie_welt) |
| `Ui_` | Benutzeroberfläche | `ui/logic/kategorie_ui/` | MenueZustaende, WeltAuswahlDialog, WeltSitzung (Autoload) |

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
| `Resources_Wood` | `game/data/ressourcen.json` (holz) |
| `Resources_Stone` | `game/data/ressourcen.json` (stein) |
| `Resources_Meat` | `game/data/ressourcen.json` (fleisch) |
| `Lager_Basis` | `economy/data/lager.json` (kleines_lager, grosses_lager) |
| `Orchestrator_Konfiguration` | `game/data/orchestrator_config.json` (holzsammler_zone, jaeger_zone) |
| `Tier_Baer` | `world/data/tier_verhalten.json` (baer) |
| `Tier_Eisbaer` | `world/data/tier_verhalten.json` (eisbaer, Kombi baer_verfolgen + aggressiv x1.2) |
| `Tier_Hase` | `world/data/tier_verhalten.json` (hase) |
| `Tier_Vogel` | `world/data/tier_verhalten.json` (vogel) |
| `Tier_Vogelgruppe` | `world/data/tier_verhalten.json` (vogelgruppe) |
| `Welt_BiomBasis` | `world/data/biome.json` (gemaessigt, tundra, steppe) |

Erzeugungsorte: `Welt_Registry._objekt_klasse_fuer()`, `Einheit_Ressourcen._ressourcen_klasse_fuer()`, `Tier_Registry._tier_klasse_fuer()`, `Welt_BiomRegistry` (biome), `Lager_Registry` (lager), `Orchestrator_Registry` (orchestrator_config), `Kern_ModifikatorRegistry` (kern_modifikatoren). Neue Datenklassen werden nur an diesen Stellen registriert.

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
| `game/data/steuerung.json` | Menschenlesbare Steuerung WASD Kamera, Linksklick einzeln, Drag Masse, Rechtsklick Kontext sammeln abbauen mit Tooltip Werkzeug, faktor 1=10s | `Kern_SteuerungRegistry` + `Kern_SteuerungUebersetzer` |
| `world/data/element_katalog.json` | Platzierbare Objekte mit Kategorie | `Welt_Registry` |
| `world/data/tier_verhalten.json` | Tierwerte (Trigger, Geschwindigkeit, Ertrag, HP) | `Tier_Verhalten` |
| `world/data/biome.json` | Biome als Mutationen je Biom mit logik_id, modifikator, faktor | `Welt_BiomRegistry` + `Welt_BiomMutation` + `Welt_BiomManager` |
| `world/data/standard_welt.json` | Standard-Prototypkarte mit biom_id | `Welt_Model` über die Szenen |
| `core/data/kern_logik.json` | Generische Logiken wiederverwendbar | `Kern_LogikRegistry` |
| `core/data/kern_modifikatoren.json` | Modifikatoren mit faktor 1=10s (Verletzungen sperren Jobs) | `Kern_ModifikatorRegistry` + `Einheit_VitalStatus` |
| `economy/data/lager.json` | Lager-Templates mit Kapazität und welt_objekt_id | `Lager_Registry` -> `Lager_Manager` (lokale Instanzen, Mutationen) |
| `game/data/orchestrator_config.json` | Zonen mit Bedarf je Ressource und Job | `Orchestrator_Registry` -> `Orchestrator_Manager` |
| `shinon/shinon_init.py --readme` | Lebendige README als Pitch von Shinon, gamer orientiert, vierte Wand | `ShinonReadmeGenerator` |

## 6. RT Pyramide

Die Architektur ist eine echte Pyramide mit modularer Spitze. Basis: `Welt_Model` haelt nur Daten. Darueber: Registries halten alle exakten Datenklassen zentral und zeigen je Eintrag auf ein sichtbares Asset, Logiken und Modifikatoren sind generisch wiederverwendbar. Darueber: State Maschinen und Mutationsmaschinen mit je genau einer Verantwortung. Spitze: Endszene `world/scenes/prototyp_karte.tscn` komponiert alle Untersysteme, besitzt aber selbst keine Logik und wird durch die Untersysteme modular bestimmt.

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
3. **Game-Domäne** (`game/`): Jobs, Einheiten, Ressourcenbestände, Vitalstatus. `Einheit_Manager` verbindet Welt (Ziele), Tiere (Jagd), Lager (verortete Bestände) und Vitalstatus (Verletzungen sperren Jobs), kennt aber keine Darstellungsdetails. Jobs offfenbaren ihre Job-bedingungen ("mindest_tragekraft", "benötigtes_werkzeug") nur als Signale; die kritische Arbeit bleibt\
4. **Economy-Domäne** (`economy/`): Lokale Lager (Lager_Basis je Typ in `economy/data/lager.json`, verortete Instanzen im `Lager_Manager`). Einheiten lagern Ernte im nächsten Lager ein; globale Bestände sind nur die Summe für das HUD. Wachstum (Haus + 3 Nahrung -> neuer Stickman) entnimmt aus dem nächsten Lager.
5. **Core-Domäne** (`core/`): Weltuhr (einziger Tick), Zufall (`Kern_Zufall` als einzige Quelle), Mutationen, Modifikatoren (`Kern_ModifikatorBasis` mit Dauer und Heilbarkeit) und Signalbus (`Kern_SignalBus` als `Node`-Autoload). Zufall fließt nur in Mutationen und Vitalstatus über `Kern_Zufall.zahl_bereich()`.

Szenen (`*/scenes/`) sind Ansichten: Eingabe und Darstellung, keine Simulationslogik.

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

## 9. Pflichten bei Änderungen

1. Neue Klasse: Präfix vergeben, in den Kategorie-Ordner legen, ggf. Datenklassen-Erzeugung registrieren, Architektur.md in Abschnitt 1 und 3 ergänzen.
2. Neues Datenobjekt: eigene Klasse in `kategorie_*` anlegen, Registry-Erzeugung ergänzen, Tabelle Abschnitt 3 pflegen.
3. Neue zentrale Config: Datei in Abschnitt 4 eintragen.
4. Umbenennung: alle Referenzen (`.gd`, `.tscn`, Autoloads in `project.godot`) anpassen, Preflight und `godot --headless` laufen lassen, Architektur.md mitpflegen.
5. Vor jedem Commit: `python tools/preflight.py` muss fehlerfrei enden. Dazu gehört das Shinon Gate. Erst shinon/commit_msg.txt in nummerierten bildlichen Sätzen ohne Banner und ohne Bullet füllen, README via shinon/shinon_init.py --readme frisch halten, dann Preflight laufen lassen. Ohne grünes Shinon Gate ist kein Commit erlaubt.
6. Init nur über `python shinon/shinon_init.py --init`, Prüfung nur über `--check`, GitHub nur über `--github`. Niemals Zustand aus anderen lokalen Projekten kopieren, nur gh Token verwenden.
