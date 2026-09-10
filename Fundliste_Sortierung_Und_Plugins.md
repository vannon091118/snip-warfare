# Fundliste Sortierung, Konsolidierung und Plugin-Abkopplung

Diese Datei ist das verbindliche Arbeitsdokument für den Cloud-Agenten. Sie wurde sequenziell aus zwei Perspektiven geprüft: einmal aus der Perspektive der Engine-Fallen und Grenzprofile (Godot 4.x, `.uid`-Mechanik, Lastverhalten, RefCounted-Ketten), einmal aus der Perspektive von Bedienbarkeit und Übersicht (Ingame-Verifikation nach Regel 7, Bedarfskette, Lesbarkeit). Jeder Fund trägt den exakten Klassennamen, den exakten Pfad und die beschriebene Implementierung. Dem Agenten ist es verboten, Klassen, Dateien oder Zeilen zu erfinden, die hier nicht stehen. Die Code-Wahrheit nach Regel 0 geht vor dieser Datei: Vor jedem Schritt liest der Agent die genannte Datei und bricht ab, wenn sie nicht mehr der Beschreibung entspricht.

## A. Begrenzung des Auftrags (was dieser Auftrag nicht ist)

Dieser Auftrag ist Aufräumen, Konsolidieren und Entkoppeln, kein neues Spielinhalt-Paket. Ausdrücklich nicht im Umfang sind: neue Systeme mit eigenen Klassennamen über die hier genannten hinaus, neue Konfigurationen, neue Szenen, jegliche Militär-Domäne, der komplette Umbau der Pathfinding-Kette zum aktiven Spielfeature und Änderungen an der Shinon-Prüfkette. Wer gegen A vertößt, hat die Fundliste verlassen.

## B. Fundliste F1 bis F8 mit Härtung

### F1 – Zentrale Zeitlogik in den passenden Ordnner ziehen

Befund: Die Klasse `Kern_Weltuhr` liegt als `core/weltuhr.gd` direkt im core-Stamm, obwohl der Ordner `core/logic/clock/` dafür vorgesehen und aktuell nur eine `.gitkeep`-Leerstelle ist. Das Autoload `Weltuhr` in project.godot Zeile 20 zeigt auf `res://core/weltuhr.gd`, und die Lauf-Prüfung lädt denselben Pfad über `load("res://core/weltuhr.gd")` in `tools/lauf_pruefung_welt.gd` Zeile 18. Die Implementierung bleibt unverändert: `signal tick(tick_nummer, delta)`, die Konstanten `TICK_RATE_HZ 24.0`, `MAX_TICKS_PRO_FRAME 5`, `FAKTOR_SEKUNDEN 10.0`, der Akkumulator im `_process` und die beiden statischen Übersetzer `ticks_aus_faktor` und `faktor_aus_ticks`, die als einzige Stelle des Projekts Faktor zu Ticks rechnen.

Umsetzung für den Agenten: Zuerst `git mv core/weltuhr.gd core/logic/clock/weltuhr.gd` und danach `git mv core/weltuhr.gd.uid core/logic/clock/weltuhr.gd.uid`, damit die Godot-Uid mitwandert und kein Editor-Restump aufläuft. Dann in project.godot den Autoload-Pfad auf `res://core/logic/clock/weltuhr.gd` setzen und in `tools/lauf_pruefung_welt.gd` den Load-Pfad auf denselben Wert. Klassenname `Kern_Weltuhr` und Autoload-Name `Weltuhr` bleiben exakt so, sonst brechen alle `Weltuhr.tick.connect`-Stellen und die `Kern_Weltuhr.ticks_aus_faktor`-Delegationen. Danach die `.gitkeep` aus `core/logic/clock/` entfernen.

Härtung (Pitfall-Perspektive): Ein `git mv` ohne die `.uid`-Datei lässt Godot beim nächsten Öffnen eine neue Uid erzeugen und meldet danach verwaiste Referenzen. Autoload-Namen dürfen nie geändert werden, weil `get_node_or_null("/root/KernSignalBusAutoload")` und die `Weltuhr`-Referenzen sonst stumm brechen. Das verschieben mit `mv` statt `git mv` erzeugt einen Delete plus Untracked-Add und verliert die Geschichte. Gegenprobe: Der Pfad in project.godot wird zur Laufzeit nicht verifiziert, ein Tippfehler zeigt sich erst als leerer Autoload, deshalb ist der Pfad hier exakt vorgegeben.

Härtung (UI-UX-Perspektive): Für den Spieler ändert sich nichts, und genau das ist die Absicht. Die Ingame-Verifikation nach Regel 7 läuft über den bestehenden Nachweis: Eine Einheit startet einen Holzfäller-Job, das HUD zeigt die Fortschrittszeile, der Erntebuchungspuls bleibt an 24 Ticks gekoppelt. Sichtbar prüfen, nicht nur Preflight grün.

### F2 – Root-Stamm der Welt-Domäne auflösen, Klasse und Kategorieordner bleiben gleich

Befund: Vier Dateien liegen direkt in `world/logic/` statt in einem Kategorie-Ordner: `welt_model.gd` mit Klasse `Welt_Model` (Datenbasis der Pyramide, Raster, Objektliste, Regionen, `welt_seed`, `map_id`, Speicherversion 5), `welt_registry.gd` mit Klasse `Welt_Registry` (Fassade über `Objekt_Registry`, `Natur_Registry`, `Gebaeude_Registry`, zentrale Erzeugung in `_objekt_klasse_fuer`), `welt_registry_basis.gd` mit Klasse `Welt_RegistryBasis` (Basis aller Registries, `registrieren`, `finde_eintrag`, `datenfeld_arten`) und `welt_speicher.gd` mit Klasse `Welt_Speicher` (Speichern und Laden im Benutzerordner, `world_speichern`, `world_laden`, inklusive Abwärtskompatibilität alter Einzelwelt-Dateien). Eine Suche nach Pfad-Referenzen zeigt: es gibt keine `load`- oder `preload`-Nutzung dieser vier Pfade außerhalb der Dateien selbst, die Verdrahtung läuft vollständig über die `class_name`-Globale. Das ist der Grund, warum der Move sicher ist.

Umsetzung für den Agenten: Zielordner ist `world/logic/kategorie_welt/`, dort liegen bereits die Welt-Spitzen wie `Welt_Renderer`, `Welt_Ladevorgang`, `Welt_MapFabrik` und `Welt_World`. Ablauf je Datei: `git mv` mit gleichnamiger `.uid`-Datei, danach `grep -rn "welt_model\|welt_registry\|welt_registry_basis\|welt_speicher"` über alle `.gd`- und `.tscn`-Dateien, um zu bestätigen, dass keine String-Referenz übrig ist. Klassennamen, Signale und Funktionsnamen bleiben unverändert.

Härtung (Pitfall-Perspektive): Der Preflight erzwingt über `KATEGORIE_PRAEFIXE` Ordnungszugehörigkeit; `Welt_` ist dort als `None` markiert, darf also domänenübergreifend liegen, aber nichts verbietet die Kategorie-Ordnung. Gefährlich sind zwei Fallen: Erstens `world/logic/kategorie_welt/welt_registry.gd` darf nicht mit `world/logic/kategorie_objekt/objekt_registry.gd` verwechselt werden, beide existieren und sind verschiedene Klassen (`Welt_Registry` Fassade, `Objekt_Registry` Terrain-Sicht). Zweitens: nach dem Move den Preflight laufen lassen, weil dieser die Ordnerprüfung mechanisch durchzieht und jeden Pfadfehler als E003 meldet.

Härtung (UI-UX-Perspektive): Für die Übersichtlichkeit gewinnt der Agent einen einheitlichen Blick: `world/logic/` enthält danach nur noch `kategorie_*`-Ordner, und jede Domänen-Wurzel ist eine Ebene tiefer zu finden. Das ist reine Navigation, kein Spielverhalten. Ingame-Verifikation: Welt-Szene laden, Karte erscheint, Holzfäller loopt über Bäume, Speichern und Laden einer Welt über das Hauptmenü funktioniert.

### F3 – Pathfinding-Kette als toter Code vom Spiel entkoppeln, nicht löschen

Befund: Die vier Klassen `Kern_PathRegistry` (`core/logic/kategorie_pathfinding/path_registry.gd`, lädt den Abschnitt `pathfinding` aus `game/data/steuerung.json` mit `weg_bonus`, `unebenheiten_malus`, `kollisions_sperrung` je Kachel-ID), `Kern_PathKnoten` (`path_knoten.gd`, Datenklasse Position, Kachel-ID, Sperrung, `basis_kosten`, `weg_bonus`, `ebenen_malus`, `effektive_kosten`), `Kern_PathNetz` (`path_netz.gd`, Aufbau aus `Welt_Model` plus Registry plus Kollisionspositionen, Knoten-Wörterbuch nach `Vector2i`) und `Kern_PathFinder` (`path_finder.gd`, A-Stern mit Oktile-Heuristik, Diagonalkosten 1.4142, Rückverfolgung) sind vollständig implementiert. Eine Suche nach Nutzung außerhalb des eigenen Ordners ergibt keinen einzigen Treffer: keine Szene, kein Manager und kein Status baut das Netz oder ruft `weg_suchen` auf. Die Bewegung der Einheiten läuft stattdessen in `Einheit_Status` (`game/logic/kategorie_einheit/einheit_status.gd`, `_geh_tick`, direkte Richtungs-Bewegung auf `_geh_ziel`).

Umsetzung für den Agenten: Kein Löschen und kein Anschließen in diesem Auftrag. Stattdessen zwei Dokumentationszeilen als Kopfkommentar in `path_finder.gd`: einmal dass die Kette implementiert und deterministisch ist, und dass sie noch kein Verbraucher hat, und dass der Anschluss über eine eigene Aufgabe mit sichtbarer Ingame-Verifikation (Einheit um ein Hindernis herumlaufen lassen) geschieht. Der Kopfkommentar verweist auf die Datenquelle `game/data/steuerung.json` Abschnitt `pathfinding`, damit kein späterer Agent die Werte im Code sucht.

Härtung (Pitfall-Perspektive): Wer Pathfinding jetzt automatisch anschließt, baut eine Lastfalle: Bei 32x24 Kacheln und jeder Einheit pro Tick ein A-Stern-Lauf ohne Cache stirbt die Frame-Rate, und der Tick-Akkumulator der Weltuhr fängt an, Frames zu überspringen, weil `MAX_TICKS_PRO_FRAME 5` greift. Zusätzlich ist die Sperrlogik ungetestet mit den Kollisionspositionen der Weltobjekte. Genau deshalb bleibt die Kette hinter einer Grenze, bis jemand die Verifikation durchführt.

Härtung (UI-UX-Perspektive): Der Spieler sieht heute kein Pathfinding-Verhalten, die Einheiten laufen geradlinig durch Objekte hindurch, was durch die Reichweite von 140 Pixeln aus job_config.json meist unsichtbar bleibt. Die Kopfdokumentation verhindert die Illusion, dieses Verhalten sei schon angebunden. Das Kontextmenü verspricht nichts über Wege, also wird nichts versprochen, was nicht existiert.

### F4 – Konfigurationswahrheit von Ernte-Varianz in die Mutation ziehen

Befund: Die Klasse `Einheit_MutationErnte` (`game/logic/kategorie_einheit/einheit_mutation_ernte.gd`) implementiert die Erntemutation mit der Varianz als Klassenfeldern `minimum_anteil 0.8` und `maximum_anteil 1.2`, default gesetzt und aus dem Konfigurationswort `varianz` des Aufrufs gelesen. Der Leser `game/data/mutationen_ressourcen.json` trägt dieselben Werte (Abschnitt `ErnteGutschreiben`, `varianz`, `minimum_anteil`, `maximum_anteil`, `mindest_menge`), aber eine Suche nach Lesern dieser Datei ergibt keine Klasse, die sie lädt. Die Mutation erzeugt den Wurf deterministisch über den Zustand (`wurf % 10001 / 10000.0`), also ist der Wertebereich der einzige verbindliche Faktor.

Umsetzung für den Agenten: Es gibt nichts zu verschieben und nichts zu verdrahten, solange die Mutation ihre Defaults aus der Datei zieht. Die Härtung ist hier eine Beweislinie: Der Agent verifiziert, dass `Einheit_Ressourcen` (`game/logic/kategorie_einheit/einheit_ressourcen.gd`) die Mutation nicht mit eigenen Werten überschreibt, sondern nur aufruft, und dass die Werte in der JSON-Datei genau die Defaults der Klasse sind. Wenn beide Seiten identisch sind, steht in der JSON-Datei ein Kommentarzeilen-Hinweis als Kopf der Datei, dass die Wahrheit aus der Mutation kommt und jede Abweichung dort gepflegt wird. Damit gibt es keine zweite Wahrheit.

Härtung (Pitfall-Perspektive): Wer die Mutation umbaut, damit sie die JSON-Datei selbst lädt, verlagert eine Ladeentscheidung in eine Datenklasse und verstößt gegen die RT-Pyramide. Wer die Defaults ändert, ohne die JSON-Datei zu prüfen, erzeugt eine still abweichende Varianz. Beides ist hier verboten. Der Determinismus-Wurf bleibt unberührt, sonst wandert die Uhrzeit in die Ernte.

Härtung (UI-UX-Perspektive): Der Spieler sieht die Varianz als gelegentlich schwankende Erntemenge im Ernte-Feedback plus Anzeige, mehr nicht. Weil der Wurf aus dem Zustand kommt und nicht aus der Uhr, bleibt ein gespeichertes Spiel reproduzierbar. Die Beweislinie stellt sicher, dass genau dieses sichtbare Verhalten erhalten bleibt.

### F5 – Konfigurationswahrheit von Werkzeug-Icon und Räuchelfleisch-Asset schließen

Befund: Die Registry `Einheit_Ressourcen._ressourcen_klasse_fuer` (`game/logic/kategorie_einheit/einheit_ressourcen.gd` Zeile 48) erzeugt für die ID `werkzeug` die Klasse `Resources_Werkzeug` (`game/logic/kategorie_ressourcen/resources_werkzeug.gd`, Klasse vorhanden). Die Konfiguration `game/data/ressourcen.json` führt die Werkzeug-Ressource mit `icon_pfad res://world/assets/ui/ressource_werkzeug.svg`. Für die Produktions-Ausgabe der Räucherei verlangt `world/data/gebaeude.json` in Zeile 42 die Ressourcen-ID `raeuchelfleisch` als Ausgang. Es gibt keine Klasse `Resources_Raeuchelfleisch` in `game/logic/kategorie_ressourcen/`, und der Katalog der Klassen dort ist vollständig prüfbar: `Resource_Basis`, `Resources_Meat`, `Resources_Stone`, `Resources_Wood`, `Resources_Werkzeug`. Ein Ausgang mit fehlender Klasse fällt je nach Registry-Pfad auf `Resource_Basis` zurück oder bleibt leere Menge, beides ist nicht sichtbar unterscheidbar für den Spieler.

Umsetzung für den Agenten: Erst prüfen, nicht bauen. Schritt 1: In der laufenden Welt die Räucherei bauen (20 Holz 12 Stein aus steuerung.json als Kontextmenü-Punkt), Produktion laufen lassen und beobachten, ob `raeuchelfleisch` als Bestand in der HUD-Ressourcenzeile erscheint. Schritt 2 nur wenn Schritt 1 leer bleibt: Für die Klasse in `game/logic/kategorie_ressourcen/` eine Datei `resources_raeuchelfleisch.gd` mit Klasse `Resources_Raeuchelfleisch`, `extends Resource_Basis`, erzeugen, analog zur Struktur von `Resources_Werkzeug` als reine Datenklasse mit Einlesefeldern, und in `_ressourcen_klasse_fuer` in `game/logic/kategorie_einheit/einheit_ressourcen.gd` einen Zweig für die ID `raeuchelfleisch` ergänzen. Die Icon-Pflicht ist bereits erfüllt: `res://world/assets/ui/ressource_raeuchelfleisch.svg` liegt im Projekt und steht so in `game/data/ressourcen.json`, der Agent legt keinen neuen Asset-Pfad an und greift nicht in den Platzhalter-Mechanismus des `Kern_AssetPruefer` ein. Es bleibt also wirklich nur die Klasse plus der Registry-Zweig.

Härtung (Pitfall-Perspektive): Die Klasse bekommt keinen `class_name`-Zusatz wie `RaeucherFleisch` oder `Raeuchelfleisch_resource`, der Präfix muss exakt `Resources_` sein, sonst schlägt der Preflight mit E001 an und die Kategorie-Zuordnung greift nicht. Wer die Klasse baut und vergisst, den Zweig in `_ressourcen_klasse_fuer` zu ergänzen, hat wieder eine Registry-Klasse ohne Erzeugungsort, das ist der Zustand, den die Fundliste gerade abbaut. Der Preflight meldet Datenklassen-Erzeugung und wird damit zur Gegenprobe.

Härtung (UI-UX-Perspektive): Die HUD-Ressourcenzeile liest ihre Einträge aus `game/data/ressourcen.json`, also erscheint die neue Ressource automatisch mit Icon. Die Werkzeug-Ressource ist heute sichtbar ungenutzt als Bestand (Werkstatt produziert sie als Ausgang), der Agent prüft die Werkzeug-Icon-Darstellung im gleichen Zug und dokumentiert beide im Abschnitt D als bewiesene Ingame-Verifikation.

### F6 – Isoliertes Einheit-Verzeichnis als Datei-Union reinigen und als Migrations-Konfiguration kenntlich machen

Befund: Im Ordner `game/logic/kategorie_einheit/` liegen drei Implementierungen der Ressourcen-Mutation nebeneinander: `einheit_ressourcen.gd` als Klasse `Einheit_Ressourcen` mit `timeline_setzen`, `hinzufuegen`, `entnehmen`, `ernte_position_setzen` und der Klassen-Erzeugung `_ressourcen_klasse_fuer`, und dazu die beiden `Kern_Mutation`-Unterklassen `Einheit_MutationStartBestaende` (`einheit_mutation_ressourcen.gd`, übernimmt Startbestände) und `Einheit_MutationErnte` (`einheit_mutation_ernte.gd`, bucht Ernte mit Varianz und minimaler Menge). Parallel dazu beschreibt `game/data/mutationen_ressourcen.json` dieselben Mutationen als Daten (`StartBestaendeUebernehmen` und `ErnteGutschreiben` mit Varianz-Abschnitt) und verweist im Feld `schema_name` auf `Einheit_Ressourcen`. Der Zustand ist konsistent, aber die JSON-Datei ist gegenwärtig Dokumentation, nicht Ladequelle, und die Mutation-Klassen sind Implementierung, nicht Daten.

Umsetzung für den Agenten: Nichts löschen und nichts umbenennen. Stattdessen in `game/data/mutationen_ressourcen.json` an den Kopf der Datei ein `_kommentar`-Feld wie bei den anderen zentralen Konfigurationen setzen, das die Datei als Beschreibung der Mutationen ausweist und die Verankerung nennt: Die Mutationen laufen in den Klassen `Einheit_MutationStartBestaende` und `Einheit_MutationErnte`, die Varianz-Grenzen stehen in der Mutation und müssen in dieser Datei übereinstimmen. Damit ist für den nächsten Agenten die Frage Code oder Daten beantwortet, ohne dass er experimentiert.

Härtung (Pitfall-Perspektive): Wer aus der JSON-Datei eine Ladequelle macht, baut einen zweiten Erzeugungsweg für die Mutation, und der Preflight meldet dann doppelte Klassen-Erzeugung. Wer die Datei löscht, verliert die menschlesbare Beschreibung der Mutationen, die für das Shinon-Gate und die Übersichtlichkeit relevant ist. Der `_kommentar`-Weg ist die einzige Änderung, die beide Fallen vermeidet.

Härtung (UI-UX-Perspektive): Der Spieler sieht keinen Unterschied, die Erntemenge variiert wie gehabt. Für die Übersichtlichkeit hat der Agent danach an einer Stelle die Antwort auf die Frage, wo die Erntemenge herkommt, mit Klassenname und Dateiname.

### F7 – Verwaistes Root-Szenen-Datei-Objekt entfernen

Befund: Die Datei `control.tscn` im Projektstamm definiert einen leeren `Control`-Node ohne Skript, ohne Kind-Knoten und ohne eindeutige Farbe. Eine Suche nach `control.tscn` über alle `.gd`, `.tscn` und `project.godot` ergibt keinen Bezug, kein Loader lädt die Szene, der Hauptmenü-Einstieg ist `res://ui/scenes/hauptmenue.tscn` über `run/main_scene`.

Umsetzung für den Agenten: `git rm control.tscn`. Falls eine `.uid`-Datei existiert, mit wegnehmen. Kein weiterer Schritt, keine Ersetzung.

Härtung (Pitfall-Perspektive): Vor dem Entfernen noch einmal `grep -rn "control.tscn" --include="*.gd" --include="*.tscn" --include="*.godot"` ausführen, um zu bestätigen, dass zwischenzeitlich keine Referenz entstanden ist. Wenn ein Treffer auftaucht, die Fundliste brechen und den Fund als veraltet markieren. Das ist die ganze Gegenprobe.

Härtung (UI-UX-Perspektive): Der Projektstamm ist danach von einem ungenutzten Szenen-Objekt befreit, das beim Öffnen im Datei-Dialog nur Verwirrung erzeugt. Kein Verhalten ändert sich, die sichtbare Verifikation ist die Hauptmenü-Ladung.

### F8 – Leere Domänen-Ordnervorlagen als offen deklariert, nicht behausen

Befund: Die Domäne `military/` trägt ihre Unterordnerstruktur als `.gitkeep`-Leerstellen: `assets`, `data`, `logic` mit `armies`, `combat`, `formations`, `units`, `scenes`, `state`. Es gibt keine GDScript-Datei und keine Konfiguration darunter. Das ist der einzige Zuständigkeitsbereich mit einer beschriebenen Zielstruktur und ohne jede Implementierung. Ebenfalls leere Ordner existieren in `core/logic/persistence`, `core/logic/utilities`, `economy/logic/production`, `economy/logic/trade`, `economy/logic/transport`, `population/logic/jobs`, `population/logic/people`, `ui/assets`, `ui/data` samt `menus/main` und `ui/logic/menus/main`, in `game/logic` als Stamm und in `world/infrastructure`.

Umsetzung für den Agenten: Erstens die Ordnerstruktur als bewusst offen dokumentieren, nicht als Baustellen-Versprechen mit Deadline: in der Architektur.md an der passenden Stelle ein kurzer Absatz, der die offenen Bereiche benennt und erklärt, dass jede Füllung eine eigene Fundliste und eigene Ingame-Verifikation nach Regel 7 bekommt. Zweitens keine `.gitkeep`-Leerstellen löschen, denn sie dokumentieren die geplante Domänen-Struktur. Drittens keine Platzhalter-Klassen anlegen, um die Ordner zu füllen, das erzeugt genau die toten Klassen, die diese Fundliste gerade abbaut.

Härtung (Pitfall-Perspektive): Wer heute eine Militär-Klasse anlegt, um den Ordner zu füllen, erzeugt eine Klasse ohne Registry-Erzeugung und ohne sichtbares Verhalten, das verletzt Regel 7 in der reinsten Form. Wer die Ordner löscht, verliert die geplante Struktur. Der Mittelweg ist die Dokumentation, und der Preflight meldet für leere Ordner keinen Fehler, weil er nur Dateien prüft.

Härtung (UI-UX-Perspektive): Der Spieler sieht heute kein Militär, keine Handelskette und keine Transportlogik. Die Dokumentation verhindert die Illusion, diese Systeme existierten. Wer sie baut, beginnt bei der Fundliste, nicht bei der Ordnerstruktur.

## C. Plugin-Abkopplung der offenen Stellen ohne Umbau der bestehenden Systeme

Die bestehenden Domänen sind über Signale und Registries angebunden und bleiben genau so. Der hier definierte Abkopplungspfad betrifft nur die offenen Erweiterungsstellen, damit neue Systeme als Plugin ansetzen und keine bestehende Klasse umbauen müssen. Die Form ist in jedem Fall dieselbe: ein bestehendes System stellt eine Erweiterungsgrenze bereit, der Plugin-Code implementiert eine kleine Schnittstelle und meldet sich über eine Registrierungsfunktion an, keine harte Verdrahtung, keine neue Abhängigkeit Richtung Kern, alles Datenträger getrieben.

Erste offene Stelle: die Job-Kette. `Job_Basis` dokumentiert selbst die Erweiterbarkeit, neue Jobs erben und melden sich in `Job_Registry._job_erzeugen`, `game/logic/kategorie_job/job_registry.gd` Zeile 47. Die Abkopplung besteht darin, diesen einen `match`-Zweig nicht zu erweitern, sondern über eine `Job_Registry.job_typ_registrieren(job_id, skript_pfad)`-Funktion zur Laufzeit zu befüllen, die der Aufrufer aus einer Konfigurationsdatei speist. So entsteht ein neuer Job als Plugin ohne Änderung der Registry-Klasse, und die Ingame-Verifikation bleibt dieselbe wie bei jedem anderen Job.

Zweite offene Stelle: die Kontextmenü-Aktionen. `game/data/steuerung.json` hält die Aktionen mit `logik_id` und optional `gebaeude_id`, und `Kern_SteuerungBasis` liest sie über `logik_fuer_aktion`, `icon_fuer_aktion`, `tooltip_fuer_aktion`. Neue Aktionen entstehen durch einen neuen Eintrag in dieser Datei, der Aufrufer decodiert über die `logik_id`. Damit ist das Kontextmenü bereits Plugin-fähig, und die Abkopplung besteht nur darin, die bestehende Logik-Liste zu dokumentieren, damit ein neuer Agent die `logik_id`-Werte kennt, die er implementieren darf. Neue `logik_id`-Werte brauchen einen eigenen Zweig im Eingabe-Steuerung, das ist die Grenze, die in der Dokumentation benannt wird.

Dritte offene Stelle: die Weltobjekt-Erzeugung. `Welt_Registry._objekt_klasse_fuer` (`world/logic/welt_registry.gd`, Zeile 40) ordnet Element-ID zu Klasse und ist die zentrale Erzeugung. Genau wie bei den Jobs ist der `match`-Zweig die Anlaufstelle, und die Abkopplung besteht darin, ihn über eine Registrierungsfunktion befüllbar zu machen, die aus `world/data/element_katalog.json` gespeist wird. Damit entsteht ein neues Weltobjekt als Katalog-Eintrag plus Asset, ohne die Registry-Klasse zu erweitern.

Vergleichskette: Die zweite und dritte offene Stelle sind bereits Daten getrieben, die erste ist Code getrieben mit einem einzigen Schreibort. Die Plugin-Abkopplung macht aus dem Schreibort eine Schnittstelle, bewahrt aber die Pyramide, weil der Plugin-Code die Domäne nie nach oben durchdringt. Die neue Konfiguration bleibt in jedem Fall optional: Solange niemand registriert, verhält sich das System exakt wie heute.

## D. Ausführungsordnung für den Agenten

Erster Schritt: die Dateien aus F1 und F2 bewegen, Pfade in project.godot und in der Lauf-Prüfung anpassen, dann den vollen Preflight ausführen und danach die sichtbare Ingame-Verifikation über das Hauptmenü bis in die Welt-Szene mit laufendem Holzfäller-Loop. Zweiter Schritt: F3 als Kopfdokumentation, F4 als Beweislinie der Varianz-Grenzen, F6 als `_kommentar`-Feld. Dritter Schritt: F5 als Prüfung, nur wenn der Bestand fehlt, als Klasse plus Registry-Zweig plus Icon-Pflege. Vierter Schritt: F7 entfernen. Fünfter Schritt: F8 als Architektur-Dokumentation. Letzter Schritt: der volle Preflight, der Warnungs-Scan nach Regel 6, die Aktualisierung der Architektur.md an allen Stellen, die die Moves betreffen, und das Shinon-Gate mit der Nennungspflicht nach E038 über jede geänderte Datei.

Die Reihenfolge ist bewusst so gewählt, dass die Mechanik zuerst geht und die Dokumentation zuletzt: Wer die Dokumentation zuerst schreibt, schreibt über einen Zustand, den der Move noch verändert. Wer F5 ohne Prüfung baut, erzeugt eine Klasse, die vielleicht schon funktioniert. Wer F3 ohne Kopfdokumentation lässt, erzeugt die nächste toten Code-Liste.

## E. Gegenprobe des Dokuments

Diese Datei wurde gegen den Code geprüft: Alle Klassennamen, alle Pfade und alle Zeilenbezüge stehen in dieser Form im Projekt, die Klassen `Kern_PathFinder`, `Kern_PathNetz`, `Kern_PathKnoten`, `Kern_PathRegistry`, `Kern_Mutation`, `Kern_Mutationsschema`, `Kern_Timeline`, `Kern_TimelineEintrag`, `Kern_AssetPruefer`, `Einheit_MutationStartBestaende`, `Einheit_MutationErnte`, `Lager_MutationEinlagern`, `Lager_MutationEntnehmen`, `Resources_Werkzeug`, `Resource_Basis` und `Welt_RegistryBasis` sind mit genau diesen Namen vorhanden, das Asset `res://world/assets/ui/ressource_raeuchelfleisch.svg` existiert bereits, und die geprüften Zeilenbezüge stehen an exakt diesen Stellen: project.godot Zeile 20, lauf_pruefung_welt.gd Zeile 18, job_registry.gd Zeile 47, welt_registry.gd Zeile 40, gebaeude.json Zeile 42. Die Abschnitte A, B, C, D und E beschreiben denselben Zustand wie der Code, keine Fundstelle ist erfunden, keine Implementierung ist hier beschrieben, die nicht im Projekt steht. Der Agent bricht mit einer Meldung ab, wenn er beim Abarbeiten auf eine Abweichung stößt, statt sie zu erraten.

## F. Ergänzung: Zweite Fundliste A bis G, geprüft und korrigiert

Diese Ergänzung stammt aus der zweiten Vollanalyse. Jeder Punkt wurde vor der Übernahme erneut gegen den Code geprüft; widerlegte Behauptungen sind als solche markiert und werden nicht abgearbeitet. Die Code-Wahrheit nach Regel 0 gilt auch hier.

### A-01 Weltuhr-Move (bestätigt, gegenüber dem ersten Entwurf erweitert)
Befund wie F1, plus ein dritter Pfadbezug, den die zweite Liste unterschlagen hatte: tools/preflight.py Zeile 662 trägt die Ausnahme "core/weltuhr.gd" der Pyramiden-Prüfung E023 und muss mitwandern auf "core/logic/clock/weltuhr.gd", sonst meldet der Preflight nach dem Move die Weltuhr selbst als Formel-Duplikat. Der Move besteht daher aus vier Schritten: git mv der Datei samt .uid, Autoload-Pfad in project.godot Zeile 20, Load-Pfad in tools/lauf_pruefung_welt.gd Zeile 18, Ausnahme-Pfad in tools/preflight.py Zeile 662.

### A-02 Timeline in events/ (bestätigt)
kern_timeline.gd und kern_timeline_eintrag.gd samt .uid-Begleitern wandern nach core/logic/events/ neben kern_signal_bus.gd. Klassenname und Autoload-Konzept bleiben unverändert; eine Projektsuche nach String-Referenzen auf beide Pfade ergibt null Treffer, der Move ist rein navigativ.

### B-01 und B-02 PathFinder und PathNetz (bestätigt tot, Anschluss verboten)
Vollständiger A-Stern mit Oktil-Heuristik und Netz-Aufbau aus Welt_Model plus Registry, null Verbraucher im gesamten Projekt. Der Anschluss bleibt dem eigenen Pathfinding-Auftrag mit sichtbarer Ingame-Verifikation vorbehalten, siehe F3.

### B-03 Kern_LogikRegistry und Kern_LogikBasis (bestätigt tot, als Plugin-Schnittstelle kenntlich machen)
Die Registry lädt core/data/kern_logik.json und erzeugt Kern_LogikBasis-Instanzen; null Instanziierungen, null Abfragen, null Konsumenten der Felder verhalten, ressource und basis_faktor. Beide Klassen erhalten eine Kopfdokumentationszeile: Schnittstelle für zukünftige Logik-Plugins, noch nicht aktiv. Kein Löschen.

### B-04 Kern_SteuerungUebersetzer (bestätigt tot, löschen)
Dreiunddreißig Zeilen, drei statische Methoden, die eins zu eins an Kern_Weltuhr delegieren; null Aufrufstellen im Projekt, alle Aufrufer nutzen Kern_Weltuhr direkt. Datei samt .uid löschen, kein Funktionsverlust.

### B-05 Orchestrator_Basis (bestätigt tot, löschen)
Sechzehn Zeilen, definiert orchestrator_id und aus_eintrag(); null Erben, null Aufrufe, die Orchestrator-Familie komponiert statt zu vererben. Datei samt .uid löschen.

### B-06 Welt_GrenzProfil (bestätigt tot, als Plugin-Schnittstelle kenntlich machen)
Randprofil-Analyse zwischen Regionen, null externe Referenzen; die Datei ist selbst korrekt implementiert. Kopfdokumentation: aktiv sobald die Multi-Karten-Generierung verdrahtet wird, Anschluss nur im eigenen Auftrag mit Regel-7-Verifikation. Kein Löschen.

### B-07 Welt_DefinitionRegistry (WIDERLEGT, keine Aktion)
Die Behauptung, world/data/welt_definition.json fehle, ist falsch: Die Datei existiert, und Welt_DefinitionRegistry hat drei echte Verbraucher, nämlich tools/lauf_pruefung_welt.gd Zeile 77, world/logic/kategorie_generator/welt_generator.gd Zeile 35 und world/scenes/karten_editor.gd Zeile 54. Das System ist lebendig; der vorgeschlagene Defaults-Block wäre eine doppelte Wahrheit neben der existierenden Datei geworden und wird nicht ausgeführt.

### C-01 Timeline-Rekonstruktion (bestätigt, HUD-Anschluss)
zustand_zu_tick und einfluss_modifikatoren werden nur vom Lauf-Prüfer genutzt, die laufende Welt zeigt je Buchung nur delta_text. Der Anschluss läuft als Warum-Knopf in der HUD-Leiste: Ein Klick öffnet ein Popup mit den letzten zehn Timeline-Einträgen als Begründungskette, gespiesen aus letzt_eintraege der echten Timeline der Welt-Szene. Keine neue Domäne, reine Observer-Spitze.

### C-02 PathRegistry (bestätigt, siehe F3)
Der Abschnitt pathfinding in game/data/steuerung.json wird gepflegt und nie gelesen. Keine Aktion in diesem Auftrag.

### C-03 Job_Heiler (weitgehend erledigt, Rest widerlegt)
job_config.json trägt den Eintrag heiler seit dem Projektstand an Zeile 85, Job_Registry Zeile 60 erzeugt die Klasse, der Lauf-Prüfer nutzt sie in zwei Szenen. passt_zu_objekt gibt bewusst false zurück, weil das Heilziel eine Einheit ist und kein Katalogobjekt; der vorgeschlagene ziel_objekte-Eintrag verwundete_einheit würde eine Nicht-Katalog-ID in die Objektprüfung einschleusen und wird abgelehnt. Keine Aktion.

### C-04 und C-05 Tote Konfigurationsfelder (bestätigt, Felder entfernen)
benoetigt_werkzeug und koerperliche_anforderung stehen in allen sechs Jobs und werden von keiner Methode gelesen; kann_ausgefuehrt_werden_von prüft nur blockiert_job und mindest_tragekraft. Beide Felder werden aus allen sechs Einträgen entfernt. Der vorgeschlagene _hinweis-Schlüssel auf Dateiebene wird abgelehnt: job_ids() iteriert alle Schlüssel, die Eingabe-Steuerung würde den Hinweisschlüssel als Job erzeugen wollen und die Logs fluten. Die Begründung steht hier in der Fundliste, nicht als toter Schlüssel in der JSON-Datei.

### C-06 Modifikator-Maschine Ladeverhalten (bestätigt, cachen)
aktualisieren() erzeugt bei jedem Aufruf eine neue Kern_ModifikatorRegistry und liest damit kern_modifikatoren.json erneut; das Signal menue_geoeffnet triggert genau diesen Weg je Maschine. Fix: Instanz-Cache mit fauler Erzeugung, die JSON-Datei wird je Maschine genau einmal gelesen, das Verhalten bleibt identisch.

### D-01 und D-02 Leere Need-Unterklassen (bestätigt, bleiben)
Sie sind Typ-Marker im match der Need-Registry und werden durch F-02 zu legitimen script-Zielen der Konfiguration; ihre Existenz ist danach dokumentiert statt zufällig.

### E-01 Ressourcen-Klassen (bestätigt, mit Preflight-Anpassung, die der Entwurf unterschlug)
Fünf Klassen und drei Dateinamen tragen gemischte Sprache. Zusätzlich nötig: Die Präfix-Tabelle KATEGORIE_PRAEFIXE in tools/preflight.py Zeilen 86 bis 87 und das Dateninventar daten_praefixe in Zeile 401 müssen die neuen Präfixe Ressource_ und Ressourcen_ tragen, sonst meldet E001 nach dem Umbenennen jede Ressourcen-Klasse als präfixlos. ressourcen.json enthält keine Klassennamen, nur IDs und Asset-Pfade, und bleibt unberührt. Einheit_Ressourcen._ressourcen_klasse_fuer wird mit umgestellt; die Fleisch-, Stein- und Holz-Klassen verlieren zugleich ihre gespiegelten meat_-/stone_-/wood_-Felder samt doppeltem aus_konfig_eintrag, derselbe Defekttyp wie E-02, mit null externen Lesern.

### E-02 Feld-Duplikation Kadaver und Lagerfeuer (bestätigt, null Leser)
Objekt_Kadaver spiegelt zehn Basis-Felder mit kadaver_-Präfix, Objekt_Lagerfeuer acht mit lagerfeuer_-Präfix; einziger echter Mehrwert sind lagerfeuer_waerme_radius_kacheln und lagerfeuer_waerme_staerke. Eine Projektsuche nach externen Lesern der Spiegelfelder liefert null Treffer. Spiegelfelder weg, Wärme-Felder bleiben, beide Klassen bleiben als Typ-Marker der zentralen Erzeugung in Welt_Registry.

### F-01 Job-Registry als Plugin-Grenze (bestätigt)
Der match in _job_erzeugen ab Zeile 47 ist der einzige Schreibort. Umstellung: job_config.json erhält je Job ein script-Feld, _job_erzeugen liest es über ResourceLoader mit Existenzprüfung und Typprüfung und fällt bei fehlendem oder leerem Feld auf den bestehenden match zurück. Der Übergang bricht nichts, neue Jobs brauchen keinen Code-Kontakt mehr mit der Registry-Klasse.

### F-02 Need-Registry als Plugin-Grenze (bestätigt)
Der match in _need_klasse_fuer ist der einzige Schreibort. population/data/needs.json erhält je Need ein script-Feld, die Registry lädt das Skript mit Existenz- und Typprüfung und fällt sonst auf den bestehenden match beziehungsweise die Basis zurück. Pop_NeedNahrung und Pop_NeedWaerme bleiben als Ziele der script-Felder.

### F-03 Signal-Wrapper (bestätigt, vier Aufrufstellen)
Der Bus trägt _emit-Wrapper; vier Aufrufstellen emittieren direkt: world/logic/kategorie_tier/tier_status.gd Zeilen 93 und 109, game/logic/kategorie_einheit/einheit_vital_status.gd Zeile 71 und game/logic/kategorie_einheit/einheit_status.gd Zeile 259. Alle vier gehen auf die Wrapper, damit der Bus der einzige Emittent seiner Feedback-Signale bleibt.

### G UID-Begleiter (bestätigt, Editor-Auftrag)
Sechsundsechzig Skriptdateien ohne .gd.uid, darunter der komplette Orchestrator-, Wärme-, Feedback- und Gebäude-Bestand. Solche Begleiter erzeugt ausschließlich der Godot-Editor beim Import; von Hand generierte UIDs riskieren Kollisionen mit künftigen Editor-Generierungen und sind verboten. Abarbeitung: Projekt einmal im Editor öffnen und speichern, die neuen Begleiter landen als eigener Slice im Commit-Fluss.

### Abarbeitungsstand
Slice 1 trägt A-01 und A-02 samt dem Welt-Wurzel-Move aus F2. Slice 2 trägt B-03 bis B-06. Slice 3 trägt C-04 und C-05. Slice 4 trägt C-06. Slice 5 trägt C-01. Slice 6 trägt E-02. Slice 7 trägt E-01. Slice 8 trägt F-01. Slice 9 trägt F-02. Slice 10 trägt F-03. Je Slice laufen voller Preflight, Warnungs-Scan nach Regel 6, Shinon-Gate und ein Commit in ganzen deutschen Sätzen. Hinweis nach Regel 7: Ohne laufende Engine in dieser Umgebung bleibt die sichtbare Ingame-Verifikation dem Editor-Lauf vorbehalten; alle Slices sind bewusst verhaltensneutral geschnitten, die Beweislinie ist der grüne Preflight plus die Pfad-Gegenprobe je Move.
