# Inventur SnipWarfare (TASK 01)

Dieses Dokument ist die belastbare Arbeitsgrundlage für die nachfolgenden Tasks. Jeder Befund wurde am heutigen Code geprüft (Stand Commit 478ff72, 2026-09-10, 75 Commits seit der Initialisierung cf6736b). Nicht dokumentiert ist, was nicht am Code bestätigt wurde. Historische Fundlisten bleiben als Zeitdokumente stehen; ihre Aussagen gelten nur, wo dieser Text sie als heutig bestätigt.

## 1. Geprüfter Bestand

Klassen: 137 auf 154 GDScript-Dateien (Preflight-Ausgabe des letzten Laufs). JSON-Datenpools: 14 (core 3, game 6, world 5, population 3, economy 1; world zählt gebaeude.json, generator_gewichte.json, element_katalog.json, tier_verhalten.json, biome.json, welt_definition.json). SVG-Assets: 38. Szenen: 8 tscn. Autoloads: Weltuhr (Kern_Weltuhr), WeltSitzung (Ui_WeltSitzung), KernSignalBusAutoload (Kern_SignalBus). Laufbeweis: tools/lauf_pruefung_welt.gd mit 42 grünen Prüfungen. Preflight: 16 Prüfkategorien, Codes E001 bis E039, Voll-Lauf grün inklusive Headless-Godot und Warnungs-Scan.

## 2. Domänen und deren Zustand (heute bestätigt)

Kern (core/): Weltuhr als einziger Tick und einzige Faktor-Übersetzung, Kern_Zufall als einzige Zufallsquelle, Kern_Mutation und Kern_Mutationsschema als Mutationsprotokoll, Kern_ModifikatorBasis/Registry/Maschine mit genau einer geteilten Registry-Instanz (Konsolidierung 478ff72), Kern_LogikBasis/Registry als markierte Plugin-Grenze ohne Verbraucher, Kern_SteuerungBasis/Registry als Steuerungsquelle, Pathfinding-Kette als nutzloses aber korrektes Modul ohne Verbraucher (bewusst nicht angeschlossen, Fundliste F3), Kern_Timeline als Beobachtungs-Spitze mit HUD-Anschluss (warum-Knopf).

Welt (world/): Welt_Model als Datenbasis mit Regionen, Chunks und autoritativem Weltseed, Welt_Registry als Fassade über Terrain-, Natur- und Gebäude-Sichten mit genau einer Katalog-Ladung, Welt_Generator mit ortsfester Seed-Ableitung je Region und Chunk, Welt_DefinitionRegistry als Größen-Quelle, Welt_Speicher mit World- und Einzelwelt-Kompatibilität, Welt_World als Map-Anker, Welt_MapFabrik als einzige Kartenerzeugungsstelle (Expansion), Welt_Ladevorgang als einzige Laden-und-Erzeugen-Stelle, Tier-System (Registry, Status, Manager, Darsteller), Wärmefeld, Tageszyklus, Biom als Mutation, Objekt- und Gebäude-System (Bau- und Produktionsmaschine, Manager, DefinitionRegistry), Orchestrator (Registry, Konfiguration, Status, Manager, Darsteller, Verdrahtung), Renderer mit Objekt-Darstellungs-Spitze, Feedback-Anzeigen. Die Welt-Szene welt.gd ist reine Verdrahtung.

Game (game/): Einheit_Status als Arbeitsloop-Maschine mit eigener Queue und Wegplanung, Einheit_VitalStatus als Vital-Maschine, Einheit_Manager als Verbindungs- und Tick-Organisator, Ernte- und Versorgungs-Maschine als eigene Dateien, Ressourcen über Einheit_RessourcenSchema (Startbestände, Ernte mit Varianz) und Lager-Anbindung, Job_Registry mit script-Feld als Plugin-Grenze und sechs Jobs in job_config.json.

Population (population/): Pop_NeedBaum als struktureller Besitzer, Pop_NeedRegistry und Pop_RassenSchemaRegistry mit script-Feld-Plugin-Grenze, Pop_MoodMaschine je Einheit, Pop_MoodModifikatorRegistry als einzige Schwellwert-Quelle (Konsolidierung 478ff72), Pop_Denkblase als reine Beobachterin, Verteilungs-Dialog als isoliertes Fenster.

Economy (economy/): Lager_Registry, Lager_Manager, Lager_MutationEinlagern und Lager_MutationEntnehmen als Mutationen, verortete Bestände, globale Summe nur für HUD.

UI (ui/): Eingabe- und Kamera-Steuerung als Übersetzer, Panels als PackedScenes über Uebersetzer-Schnittpunkte, HUD-Beobachter, Kontextmenü aus steuerung.json, Hauptmenü mit World-Sitzung, Übergangsszene.

## 3. Klassifizierte Befunde

Bereits erledigt und am Code bestätigt: Weltuhr liegt in core/logic/clock/, Timeline in core/logic/events/, Weltwurzel-Dateien in kategorie_welt/, Ernte-Kette mit Absender-Bindung, Wärme-Gates lesen nur die Registry, Modifikator-Registry genau eine Ladung, tagezyklus hängt direkt an der Weltuhr, Räucherei als zweiter Datenpool-Beweis, World-Ebene und Expansion als Fabrik, Loop-Jobs für alle drei Ernte-Jobs, Wegplanung angeschlossen mit Cache.

Funktionierend und unverändert zu lassen: die gesamte Tick-Kette mit Wächtern und Disconnects, die Mutationssysteme (Ressourcen, Lager, Biom), die Gebäudekette über dieselbe Maschine, das Feedback über den Signalbus, die Renderer-Trennung von Tier-Darstellung.

Offen und bewusst dokumentiert: Kern_LogikRegistry und Kern_LogikBasis ohne Verbraucher (Plugin-Grenze, Fundliste B-03, Kopfkommentar steht), Pathfinding-Kette ohne Verbraucher (bewusst, Fundliste F3), Pathfinding-Abschnitt in steuerung.json wird gepflegt aber nur von der stillen Kette gelesen, needs.json trägt kaelte_schwellwert, hitze_schwellwert und hp_abzug_je_tick als lesende Beschreibung ohne Code-Leser (die Wahrheit liegt in mood_modifikatoren.json), tageszyklus-Werte 6/4/2 stehen in needs.json als Beschreibung, werden aber an welt.gd und Einheit_Manager hart übergeben, verbrauch_je_takt 0.8 liegt als Daten vor, wird aber in Einheit_Versorgung als Default geführt.

Veraltet und nicht mehr im Code vorhanden: Kern_SteuerungUebersetzer (gelöscht, Fundliste B-04), Orchestrator_Basis (gelöscht, Fundliste B-05), control.tscn (entfernt, Fundliste F7), prototyp_karte (restlos entfernt), die früheren parallelen Erntepfade und die hart codierten Schwellwerte (Konsolidierung 478ff72).

Doppelt, aber bewusst toleriert: Tier_Registry wird je Tier_Manager-Instanz geladen (Headless-Fähigkeit, nur lesend), Pop_NeedRegistry existiert im Need-Baum und im Manager (beide nur lesend, Wahrheit bleibt die Datei), mehrere Feedback-Anzeigen abonnieren die Weltuhr je Instanz (kurzlebig, sauber getrennt).

Echte Architekturverletzung: keine gefunden. Die Registry- und Maschinenkette folgt dem Muster Daten, Registry, Maschine, Zustand, Darstellung an allen geprüften Stellen.

Echter Funktionsfehler am heutigen Code: keiner nachgewiesen. Die Pause-Menü-Rückkehr setzt get_tree().paused selbst zurück (Fundstelle F-I04 der Ingame-Liste ist damit am Code nicht mehr reproduzierbar), die MCP-Befunde F-I01 bis F-I03 liegen im Addon godot-acp, nicht im Spielcode.

Historisches Erbe ohne heutige Funktion: tools/kompilier_sweep.gd.uid ist ein verwaistes UID-Begleitfile ohne Skript (das Skript existiert nicht mehr). Es wird in diesem Task nicht entfernt, sondern nur dokumentiert; die Entfernung gehört in den Orphan-Sweep eines Folge-Tasks.

## 4. Historienzuordnung

Die 75 Commits seit cf6736b zeigen eine klare Linie: Aufbau Kern und Registries, Pathfinding und Generator, Lager und Orchestrator, Vital-Trennung und Signalbus, Wärme und Tageszyklus, Warnungs-Scan und Preflight-Härtung, Welt-Hierarchie mit Seed-Besitz, Produktionsökonomie mit zwei Datenpool-Ketten, World-Ebene und Expansion, Job-Queues, Manager-Verschmelzung zu Maschinen, Panel-Szenen, Verbindungs-Audit. Kein Commit widerspricht dem heutigen Stand; die Fundlisten F1 bis F8 und A-01 bis G sind abgearbeitet oder bewusst als offen dokumentiert.

## 5. Arbeitsgrundlage für die Folge-Tasks

TASK 02 festigt die Datenkette und dokumentiert Besitz und Erweiterungsgrenze je Domäne. TASK 03 schließt das config-driven Inhaltsmodell (Tier- und Objekt-Zugänge sind bereits als script-Feld beziehungsweise zentrale Zuordnung vorhanden; Objekt-Seite hat noch keine Registrierungsschnittstelle, nur das match in Welt_Registry._objekt_klasse_fuer). TASK 04 prüft die sieben Stabilitätskandidaten am heutigen Code; mehrere sind durch frühere Slices bereits behoben (Indexverschiebung durch stabile Tier-IDs und Nachrücken, Signal-Matching durch Absender-Bindung, Akkumulator durch Rahmen-Budget). TASK 05 hält den Generator datengetrieben; Cluster existieren bereits in generator_gewichte.json. TASK 06 bis TASK 13 bauen entlang der bestehenden Domänen ohne Parallelen. TASK 14 erweitert den Laufbeweis um Verhaltensnachweise. TASK 15 räumt den Rest auf, inklusive des dokumentierten verwaisten UID-Begleitfiles.
