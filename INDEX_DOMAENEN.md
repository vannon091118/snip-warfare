# INDEX_DOMAENEN.md — Domaenen-Index SnipWarfare

_Quelle: `python tools/index_generieren.py` — erzeugt aus dem Code, nie von Hand gepflegt._

Stand: V0.01 — 14 Domaenen plus Auffangkorb, 302 Klassen, 345 Dateien, 65 Signale, 32 Array-Elementtypen; 33 Klassen liegen ausserhalb der Domaenen-Ordner.

## 1. Domaenen-Uebersicht

| Domaene | Kuerzel | Prefix | Ordner | Klassen | Dateien |
| --- | --- | --- | --- | --- | --- |
| `core` | `kern` | `Kern_` | `core/` | 21 | 21 |
| `world/generator` | `gen` | `Welt_` | `world/logic/kategorie_generator/` | 12 | 12 |
| `world/welt` | `welt` | `Welt_` | `world/logic/kategorie_welt/` | 49 | 49 |
| `world/objekt` | `obj` | `Objekt_/Gebaeude_` | `world/logic/kategorie_objekt/` | 38 | 38 |
| `world/tier` | `tier` | `Tier_` | `world/logic/kategorie_tier/` | 21 | 21 |
| `world/orchestrator` | `orch` | `Orchestrator_` | `world/logic/kategorie_orchestrator/` | 11 | 11 |
| `game/einheit` | `ein` | `Einheit_` | `game/logic/kategorie_einheit/` | 31 | 31 |
| `game/job` | `job` | `Job_` | `game/logic/kategorie_job/` | 18 | 18 |
| `game/ressourcen` | `res` | `Resource_` | `game/logic/kategorie_ressourcen/` | 7 | 7 |
| `population` | `pop` | `Pop_` | `population/` | 30 | 31 |
| `economy` | `lager` | `Lager_` | `economy/` | 7 | 7 |
| `ui` | `ui` | `Ui_` | `ui/` | 24 | 36 |
| `shinon` | `shinon` | `Shinon_` | `shinon/` | 0 | 0 |
| `tools` | `tools` | `-` | `tools/` | 0 | 25 |
| `rest` | `rest` | `-` | `(kein Domaenen-Ordner)` | 33 | 38 |

## 2. Signal-Matrix (D Deklaration, S Senden, V Verbinden)

| Signal | kern | gen | welt | obj | tier | orch | ein | job | res | pop | lager | ui | shinon | tools | rest |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Einheit_ErnteMaschine.beute_erlegt` | - | - | - | - | - | - | DSV | - | - | - | - | - | - | - | - |
| `Einheit_ErnteMaschine.inventar_voll` | - | - | - | - | - | - | DSV | - | - | - | - | - | - | - | - |
| `Einheit_ErnteMaschine.schlag_objekt_gemeldet` | - | - | - | - | - | - | DSV | - | - | - | - | - | - | - | - |
| `Einheit_ErnteMaschine.schlag_ort_gemeldet` | - | - | - | - | - | - | DSV | - | - | - | - | - | - | - | - |
| `Einheit_Inventar.bestand_geaendert` | - | - | - | - | - | - | DS | - | - | - | - | V | - | - | - |
| `Einheit_Inventar.inventar_leer` | - | - | - | - | - | - | DS | - | - | - | - | - | - | - | - |
| `Einheit_Inventar.inventar_voll` | - | - | - | - | - | - | DSV | - | - | - | - | - | - | - | - |
| `Einheit_Ressourcen.bestand_geaendert` | - | - | - | - | - | - | DS | - | - | - | - | V | - | - | - |
| `Einheit_Status.arbeitsschritt_erledigt` | - | - | - | - | - | - | DSV | S | - | - | - | - | - | - | - |
| `Einheit_Status.gestorben` | S | - | - | - | - | - | DSV | - | - | V | - | - | - | - | V |
| `Einheit_Status.job_beendet` | - | - | - | - | - | - | DSV | - | - | - | - | - | - | S | - |
| `Einheit_Status.job_loop_gefragt` | - | - | - | - | - | - | DSV | - | - | - | - | - | - | - | - |
| `Einheit_Status.job_vergeben_fehlgeschlagen` | - | - | - | - | - | - | DS | - | - | - | - | - | - | - | - |
| `Einheit_Status.naechster_job_aus_queue` | - | - | - | - | - | - | DSV | - | - | - | - | - | - | V | - |
| `Einheit_Status.zustand_geaendert` | - | - | - | - | SV | SV | DSV | - | - | - | - | - | - | - | - |
| `Einheit_VitalStatus.gestorben` | S | - | - | - | - | - | DSV | - | - | V | - | - | - | - | V |
| `Einheit_VitalStatus.hp_veraendert` | - | - | - | - | - | - | DS | - | - | - | - | - | - | - | - |
| `Einheit_VitalStatus.modifikator_geandert` | - | - | - | - | - | - | DS | - | - | - | - | - | - | - | - |
| `Job_Basis.arbeitsschritt_erledigt` | - | - | - | - | - | - | SV | DS | - | - | - | - | - | - | - |
| `Job_Basis.job_beendet` | - | - | - | - | - | - | SV | D | - | - | - | - | - | S | - |
| `Kern_ModifikatorMaschine.aktualisiert` | DS | - | - | - | - | - | V | - | - | - | - | - | - | - | - |
| `Kern_SignalBus.decken_entfernt` | DS | - | V | - | - | - | - | - | - | - | - | - | - | - | - |
| `Kern_SignalBus.einheit_ausgewaehlt` | DS | - | - | - | - | - | - | - | - | - | - | V | - | - | - |
| `Kern_SignalBus.gestorben` | DS | - | - | - | - | - | SV | - | - | V | - | - | - | - | V |
| `Kern_SignalBus.kachel_geaendert` | DS | - | V | - | - | - | - | - | - | - | - | - | - | V | - |
| `Kern_SignalBus.kannibalismus_erreignis` | DS | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| `Kern_SignalBus.konflikt_erklaert` | DS | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| `Kern_SignalBus.lager_geaendert` | DS | - | - | - | - | - | - | - | - | - | V | - | - | - | - |
| `Kern_SignalBus.menue_geoeffnet` | DSV | - | - | V | - | - | - | - | - | - | - | - | - | - | - |
| `Kern_SignalBus.produktionsraum_entstanden` | DS | - | - | - | - | - | - | - | - | - | - | - | - | - | V |
| `Kern_SignalBus.schaden_erhalten` | DS | - | - | - | - | - | - | - | - | - | - | - | - | - | V |
| `Kern_SignalBus.timeline_eintrag` | DS | - | - | - | - | - | - | - | - | - | - | - | - | - | V |
| `Kern_Timeline.eintrag_neu` | DS | - | - | - | - | - | - | - | - | - | - | - | - | - | V |
| `Kern_Weltuhr.tick` | DS | - | V | V | V | V | V | - | - | - | - | V | - | - | V |
| `Gebaeude_Manager.gebaeude_fertiggestellt` | - | - | - | DS | - | - | - | - | - | - | - | - | - | V | - |
| `Gebaeude_Manager.gebaeude_meldung` | - | - | - | DS | - | - | - | - | - | - | - | - | - | - | V |
| `Gebaeude_Manager.gebaeude_platziert` | - | - | - | DS | - | - | - | - | - | - | - | - | - | - | V |
| `Gebaeude_Manager.status_geaendert` | - | - | - | DS | - | - | - | - | - | - | - | - | - | - | V |
| `Objekt_MoebelPlatzierer.moebel_platziert` | - | - | - | DS | - | - | - | - | - | - | - | - | - | - | V |
| `Orchestrator_Manager.orchestrator_platziert` | - | - | - | - | - | DS | - | - | - | - | - | - | - | - | - |
| `Orchestrator_Status.bedarf_pruefen` | - | - | - | - | - | DSV | - | - | - | - | - | - | - | - | - |
| `Orchestrator_Status.zustand_geaendert` | - | - | - | - | SV | DSV | SV | - | - | - | - | - | - | - | - |
| `Pop_MoodMaschine.mood_geaendert` | - | - | - | - | - | - | - | - | - | DSV | - | - | - | - | - |
| `verteilung_dialog.verteilung_gesetzt` | - | - | - | - | - | - | - | - | - | DS | - | V | - | - | - |
| `Welt_FortschrittsMaschine.orchestrator_gespawnt` | - | - | - | - | - | - | - | - | - | - | - | - | - | - | DS |
| `Welt_FortschrittsMaschine.stufe_erreicht` | - | - | - | - | - | - | - | - | - | - | - | - | - | - | DSV |
| `Welt_FortschrittsMaschine.ziel_erreicht` | - | - | - | - | - | - | - | - | - | - | - | - | - | - | DSV |
| `Welt_ProgressionsMaschine.folge_objekt_entstanden` | - | - | - | - | - | - | - | - | - | - | - | - | - | V | DS |
| `Welt_ProgressionsMaschine.objekt_erschoepft` | - | - | - | - | - | - | - | - | - | - | - | - | - | - | DSV |
| `Welt_ProgressionsMaschine.saemling_gespawnt` | - | - | - | - | - | - | - | - | - | - | - | - | - | - | DS |
| `Welt_ProgressionsMaschine.stadium_geaendert` | - | - | - | - | - | - | - | - | - | - | - | - | - | V | DS |
| `Welt_TageszyklusMaschine.phase_geaendert` | - | - | - | - | - | - | - | - | - | - | - | - | - | - | DSV |
| `Tier_Status.zustand_geaendert` | - | - | - | - | DSV | SV | SV | - | - | - | - | - | - | - | - |
| `Ui_BauPanelSzene.bau_gewaehlt` | - | - | V | - | - | - | - | - | - | - | - | DS | - | - | - |
| `Ui_EingabeSteuerung.debug_umgeschaltet` | - | - | - | - | - | - | - | - | - | - | - | DS | - | - | V |
| `Ui_OrchestratorPriorityPanel.panel_geschlossen` | - | - | - | - | - | - | - | - | - | - | - | DS | - | - | - |
| `Ui_WeltAuswahlDialog.welt_gewaehlt` | - | - | - | - | - | - | - | - | - | - | - | DSV | - | - | - |
| `kontext_menue.aktion_gewaehlt` | - | - | - | - | - | - | - | - | - | - | - | DS | - | - | V |
| `Welt_AsyncChunkLader.chunk_gefuellt` | - | - | DS | - | - | - | - | - | - | - | - | - | - | V | V |
| `Welt_AsyncChunkLader.fertig` | - | - | DS | - | - | - | - | - | - | - | - | - | - | - | V |
| `Welt_KarawanenManager.handels_abgeschlossen` | - | - | DS | - | - | - | - | - | - | - | - | - | - | - | - |
| `Welt_KarawanenManager.karawane_angekommen` | - | - | DS | - | - | - | - | - | - | - | - | - | - | - | - |
| `Welt_KarawanenManager.karawane_entladen` | - | - | DS | - | - | - | - | - | - | - | - | - | - | - | - |
| `Welt_KarawanenManager.karawane_gestartet` | - | - | DS | - | - | - | - | - | - | - | - | - | - | - | - |
| `Welt_PauseMenue.menue_gewuenscht` | - | - | DS | - | - | - | - | - | - | - | - | - | - | - | V |

_Zusaetzlich gesendete oder verbundene Namen ohne eigene Deklaration im Projekt: 12._
* `_progressions_maschine` wird in welt gerufen, aber im Projekt nicht deklariert.
* `about_to_popup` wird in ui gerufen, aber im Projekt nicht deklariert.
* `close_requested` wird in pop gerufen, aber im Projekt nicht deklariert.
* `confirmed` wird in rest, ui gerufen, aber im Projekt nicht deklariert.
* `draw` wird in orch, rest gerufen, aber im Projekt nicht deklariert.
* `gui_input` wird in rest gerufen, aber im Projekt nicht deklariert.
* `id_pressed` wird in ui gerufen, aber im Projekt nicht deklariert.
* `item_activated` wird in ui gerufen, aber im Projekt nicht deklariert.
* `pressed` wird in pop, rest, ui, welt gerufen, aber im Projekt nicht deklariert.
* `process_frame` wird in tools gerufen, aber im Projekt nicht deklariert.
* `timeout` wird in ui gerufen, aber im Projekt nicht deklariert.
* `value_changed` wird in pop gerufen, aber im Projekt nicht deklariert.

## 3. Array-Matrix (`Array[Typ]` je Domaene)

| Array-Elementtyp | Gesamt | kern | gen | welt | obj | tier | orch | ein | job | res | pop | lager | ui | shinon | tools | rest |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `String` | 59 | 5 | 4 | 12 | 13 | - | - | 3 | 4 | - | 4 | 1 | 7 | - | 3 | 3 |
| `Dictionary` | 39 | 3 | 1 | 7 | 1 | 4 | 3 | 9 | - | - | 1 | 1 | 5 | - | - | 4 |
| `int` | 16 | - | - | 5 | - | 1 | - | 4 | - | - | 1 | - | 3 | - | 1 | 1 |
| `Vector2i` | 9 | 1 | 4 | 3 | - | - | - | - | - | - | - | - | - | - | 1 | - |
| `Vector2` | 6 | 1 | - | 1 | - | - | - | 3 | - | - | - | - | - | - | - | 1 |
| `Objekt_Basis` | 5 | - | - | 1 | 4 | - | - | - | - | - | - | - | - | - | - | - |
| `float` | 5 | - | 2 | 2 | - | - | - | - | - | - | 1 | - | - | - | - | - |
| `Kern_ModifikatorBasis` | 4 | 2 | - | - | - | - | - | 1 | - | - | - | - | - | - | 1 | - |
| `Welt_Karawane` | 3 | - | - | 3 | - | - | - | - | - | - | - | - | - | - | - | - |
| `Orchestrator_Darsteller` | 2 | - | - | - | - | - | 1 | - | - | - | - | - | - | - | - | 1 |
| `Ressource_Basis` | 2 | - | - | - | - | - | - | 2 | - | - | - | - | - | - | - | - |
| `Sprite2D` | 2 | - | - | - | - | - | - | - | - | - | - | 1 | - | - | - | 1 |
| `Welt_Fraktion` | 2 | - | 1 | 1 | - | - | - | - | - | - | - | - | - | - | - | - |
| `AnimatedSprite2D` | 1 | - | - | - | - | - | - | - | - | - | - | - | 1 | - | - | - |
| `Array` | 1 | - | - | - | - | - | - | - | - | - | - | 1 | - | - | - | - |
| `Gebaeude_Definition` | 1 | - | - | - | 1 | - | - | - | - | - | - | - | - | - | - | - |
| `Kern_LogikBasis` | 1 | 1 | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| `Kern_Mutation` | 1 | 1 | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| `Kern_TimelineEintrag` | 1 | 1 | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| `Label` | 1 | - | - | - | - | - | - | - | - | - | - | 1 | - | - | - | - |
| `Lager_Basis` | 1 | - | - | - | - | - | - | - | - | - | - | 1 | - | - | - | - |
| `Orchestrator_Konfiguration` | 1 | - | - | - | - | - | 1 | - | - | - | - | - | - | - | - | - |
| `Pop_MoodEskalationStufe` | 1 | - | - | - | - | - | - | - | - | - | 1 | - | - | - | - | - |
| `Pop_MoodMaschine` | 1 | - | - | - | - | - | - | - | - | - | - | - | - | - | 1 | - |
| `Pop_MoodModifikator` | 1 | - | - | - | - | - | - | - | - | - | 1 | - | - | - | - | - |
| `Pop_NeedBasis` | 1 | - | - | - | - | - | - | - | - | - | 1 | - | - | - | - | - |
| `Pop_RassenSchema` | 1 | - | - | - | - | - | - | - | - | - | 1 | - | - | - | - | - |
| `RefCounted` | 1 | - | - | 1 | - | - | - | - | - | - | - | - | - | - | - | - |
| `Soz_Geruecht` | 1 | - | - | - | - | - | - | - | - | - | 1 | - | - | - | - | - |
| `Tier_Basis` | 1 | - | - | - | - | 1 | - | - | - | - | - | - | - | - | - | - |
| `Welt_BiomBasis` | 1 | - | - | - | - | - | - | - | - | - | - | - | - | - | - | 1 |
| `Welt_FraktionsKiMaschine` | 1 | - | - | 1 | - | - | - | - | - | - | - | - | - | - | - | - |

## 4. Domaenen im Einzelnen

### core — Kuerzel `kern` — `core/`

Prefix `Kern_`, 21 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Kern_AssetPruefer` | `core/logic/kern_asset_pruefer.gd` | 71 |
| `Kern_Hash` | `core/logic/kern_hash.gd` | 53 |
| `Kern_LogikBasis` | `core/logic/kern_logik_basis.gd` | 24 |
| `Kern_LogikRegistry` | `core/logic/kern_logik_registry.gd` | 68 |
| `Kern_ModifikatorBasis` | `core/logic/kern_modifikator_basis.gd` | 76 |
| `Kern_ModifikatorMaschine` | `core/logic/kern_modifikator_maschine.gd` | 117 |
| `Kern_ModifikatorRegistry` | `core/logic/kern_modifikator_registry.gd` | 89 |
| `Kern_Mutation` | `core/logic/kern_mutation.gd` | 34 |
| `Kern_Mutationsschema` | `core/logic/kern_mutationsschema.gd` | 60 |
| `Kern_PathFinder` | `core/logic/kategorie_pathfinding/path_finder.gd` | 36 |
| `Kern_PathKnoten` | `core/logic/kategorie_pathfinding/path_knoten.gd` | 22 |
| `Kern_PathNetz` | `core/logic/kategorie_pathfinding/path_netz.gd` | 67 |
| `Kern_PathRegistry` | `core/logic/kategorie_pathfinding/path_registry.gd` | 63 |
| `Kern_SignalBus` | `core/logic/events/kern_signal_bus.gd` | 103 |
| `Kern_SteuerungBasis` | `core/logic/kern_steuerung_basis.gd` | 74 |
| `Kern_SteuerungRegistry` | `core/logic/kern_steuerung_registry.gd` | 53 |
| `Kern_TastenTabelle` | `core/logic/kern_tasten_tabelle.gd` | 88 |
| `Kern_Timeline` | `core/logic/events/kern_timeline.gd` | 78 |
| `Kern_TimelineEintrag` | `core/logic/events/kern_timeline_eintrag.gd` | 37 |
| `Kern_Weltuhr` | `core/logic/clock/weltuhr.gd` | 92 |
| `Kern_Zufall` | `core/logic/kern_zufall.gd` | 65 |

#### Signale (Rolle in dieser Domaene)

| Signal | Rolle | mitwirkende Domaenen |
| --- | --- | --- |
| `Einheit_Status.gestorben` | S | ein, kern, pop, rest |
| `Einheit_VitalStatus.gestorben` | S | ein, kern, pop, rest |
| `Kern_ModifikatorMaschine.aktualisiert` | DS | ein, kern |
| `Kern_SignalBus.decken_entfernt` | DS | kern, welt |
| `Kern_SignalBus.einheit_ausgewaehlt` | DS | kern, ui |
| `Kern_SignalBus.gestorben` | DS | ein, kern, pop, rest |
| `Kern_SignalBus.kachel_geaendert` | DS | kern, tools, welt |
| `Kern_SignalBus.kannibalismus_erreignis` | DS | kern |
| `Kern_SignalBus.konflikt_erklaert` | DS | kern |
| `Kern_SignalBus.lager_geaendert` | DS | kern, lager |
| `Kern_SignalBus.menue_geoeffnet` | DSV | kern, obj |
| `Kern_SignalBus.produktionsraum_entstanden` | DS | kern, rest |
| `Kern_SignalBus.schaden_erhalten` | DS | kern, rest |
| `Kern_SignalBus.timeline_eintrag` | DS | kern, rest |
| `Kern_Timeline.eintrag_neu` | DS | kern, rest |
| `Kern_Weltuhr.tick` | DS | ein, kern, obj, orch, rest, tier, ui, welt |

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `String` | 5 |
| `Dictionary` | 3 |
| `Kern_ModifikatorBasis` | 2 |
| `Kern_LogikBasis` | 1 |
| `Kern_Mutation` | 1 |
| `Kern_TimelineEintrag` | 1 |
| `Vector2` | 1 |
| `Vector2i` | 1 |

### world/generator — Kuerzel `gen` — `world/logic/kategorie_generator/`

Prefix `Welt_`, 12 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Welt_BiomAnalyser` | `world/logic/kategorie_generator/welt_biom_analyser.gd` | 122 |
| `Welt_FeldAnalyser` | `world/logic/kategorie_generator/welt_feld_analyser.gd` | 96 |
| `Welt_FraktionsGenerator` | `world/logic/kategorie_generator/welt_fraktions_generator.gd` | 132 |
| `Welt_FraktionsKeimlingAnalysator` | `world/logic/kategorie_generator/fraktions_keimling_analysator.gd` | 274 |
| `Welt_Generator` | `world/logic/kategorie_generator/welt_generator.gd` | 412 |
| `Welt_GeneratorChunkPruefer` | `world/logic/kategorie_generator/generator_chunk_pruefer.gd` | 42 |
| `Welt_GeneratorFelsmassive` | `world/logic/kategorie_generator/generator_felsmassive.gd` | 91 |
| `Welt_GeneratorFliesenWahl` | `world/logic/kategorie_generator/generator_fliesen_wahl.gd` | 65 |
| `Welt_GeneratorGewaesser` | `world/logic/kategorie_generator/generator_gewaesser.gd` | 128 |
| `Welt_GeneratorObjektStempel` | `world/logic/kategorie_generator/generator_objekt_stempel.gd` | 84 |
| `Welt_GeneratorRegistry` | `world/logic/kategorie_generator/generator_registry.gd` | 87 |
| `Welt_GeneratorVerteilung` | `world/logic/kategorie_generator/generator_verteilung.gd` | 58 |

#### Signale (Rolle in dieser Domaene)

_keine Signal-Deklaration in dieser Domaene_

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `String` | 4 |
| `Vector2i` | 4 |
| `float` | 2 |
| `Dictionary` | 1 |
| `Welt_Fraktion` | 1 |

### world/welt — Kuerzel `welt` — `world/logic/kategorie_welt/`

Prefix `Welt_`, 49 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Welt_AsyncChunkLader` | `world/logic/kategorie_welt/welt_async_chunk_lader.gd` | 108 |
| `Welt_BauGeist` | `world/logic/kategorie_welt/welt_bau_geist.gd` | 70 |
| `Welt_BaustellenBedarf` | `world/logic/kategorie_welt/welt_baustellen_bedarf.gd` | 108 |
| `Welt_DefinitionRegistry` | `world/logic/kategorie_welt/welt_definition_registry.gd` | 71 |
| `Welt_EditorWerkzeug` | `world/logic/kategorie_welt/welt_editor_werkzeug.gd` | 52 |
| `Welt_ErschoepfungMaschine` | `world/logic/kategorie_welt/welt_erschoepfung_maschine.gd` | 115 |
| `Welt_Fraktion` | `world/logic/kategorie_welt/welt_fraktion.gd` | 67 |
| `Welt_FraktionsErschoepfung` | `world/logic/kategorie_welt/fraktions_erschoepfung.gd` | 24 |
| `Welt_FraktionsKiMaschine` | `world/logic/kategorie_welt/fraktions_ki_maschine.gd` | 107 |
| `Welt_FraktionsKiVerdrahtung` | `world/logic/kategorie_welt/welt_fraktions_ki_verdrahtung.gd` | 114 |
| `Welt_FraktionsProtokoll` | `world/logic/kategorie_welt/fraktions_protokoll.gd` | 25 |
| `Welt_GrenzProfil` | `world/logic/kategorie_welt/welt_grenz_profil.gd` | 61 |
| `Welt_HudRueckmeldung` | `world/logic/kategorie_welt/welt_hud_rueckmeldung.gd` | 47 |
| `Welt_KachelGeste` | `world/logic/kategorie_welt/welt_kachel_geste.gd` | 43 |
| `Welt_Karawane` | `world/logic/kategorie_welt/welt_karawane.gd` | 179 |
| `Welt_KarawanenManager` | `world/logic/kategorie_welt/welt_karawanen_manager.gd` | 137 |
| `Welt_KarawanenReise` | `world/logic/kategorie_welt/welt_karawanen_reise.gd` | 44 |
| `Welt_KarawanenSpeicher` | `world/logic/kategorie_welt/welt_karawanen_speicher.gd` | 30 |
| `Welt_KarawanenZeichner` | `world/logic/kategorie_welt/welt_karawanen_zeichner.gd` | 44 |
| `Welt_KartenBeobachter` | `world/logic/kategorie_welt/welt_karten_beobachter.gd` | 24 |
| `Welt_Ladevorgang` | `world/logic/kategorie_welt/welt_ladevorgang.gd` | 118 |
| `Welt_LagerFabrik` | `world/logic/kategorie_welt/welt_lager_fabrik.gd` | 27 |
| `Welt_LandeplatzAnzeige` | `world/logic/kategorie_welt/welt_landeplatz_anzeige.gd` | 93 |
| `Welt_MakroGenerator` | `world/logic/kategorie_welt/welt_makro_generator.gd` | 81 |
| `Welt_MapFabrik` | `world/logic/kategorie_welt/welt_map_fabrik.gd` | 102 |
| `Welt_Model` | `world/logic/kategorie_welt/welt_model.gd` | 529 |
| `Welt_NetzwerkPlaner` | `world/logic/kategorie_welt/welt_netzwerk_planer.gd` | 296 |
| `Welt_ObjektDarsteller` | `world/logic/kategorie_welt/welt_objekt_darsteller.gd` | 90 |
| `Welt_ObjektGitter` | `world/logic/kategorie_welt/welt_objekt_gitter.gd` | 68 |
| `Welt_ObjektKnoten` | `world/logic/kategorie_welt/welt_objekt_knoten.gd` | 95 |
| `Welt_PauseMenue` | `world/logic/kategorie_welt/welt_pause_menue.gd` | 130 |
| `Welt_RaumAnalyser` | `world/logic/kategorie_welt/welt_raum_analyser.gd` | 119 |
| `Welt_Registry` | `world/logic/kategorie_welt/welt_registry.gd` | 96 |
| `Welt_RegistryBasis` | `world/logic/kategorie_welt/welt_registry_basis.gd` | 73 |
| `Welt_RegistryKlassenZuordnung` | `world/logic/kategorie_welt/welt_registry_klassen_zuordnung.gd` | 36 |
| `Welt_RegistryZugriff` | `world/logic/kategorie_welt/welt_registry_zugriff.gd` | 45 |
| `Welt_Renderer` | `world/logic/kategorie_welt/welt_renderer.gd` | 676 |
| `Welt_RissGeste` | `world/logic/kategorie_welt/welt_riss_geste.gd` | 44 |
| `Welt_SichtbereichSammler` | `world/logic/kategorie_welt/welt_sichtbereich_sammler.gd` | 50 |
| `Welt_Speicher` | `world/logic/kategorie_welt/welt_speicher.gd` | 74 |
| `Welt_StadiumGeste` | `world/logic/kategorie_welt/welt_stadium_geste.gd` | 25 |
| `Welt_TerrainBlatt` | `world/logic/kategorie_welt/welt_terrain_blatt.gd` | 39 |
| `Welt_TierPlatzierer` | `world/logic/kategorie_welt/welt_tier_platzierer.gd` | 20 |
| `Welt_UiAufbau` | `world/logic/kategorie_welt/welt_ui_aufbau.gd` | 118 |
| `Welt_UmsturzGeste` | `world/logic/kategorie_welt/welt_umsturz_geste.gd` | 39 |
| `Welt_WaermeSammler` | `world/logic/kategorie_welt/welt_waerme_sammler.gd` | 32 |
| `Welt_WasserAutomat` | `world/logic/kategorie_welt/welt_wasser_automat.gd` | 206 |
| `Welt_World` | `world/logic/kategorie_welt/welt_world.gd` | 304 |
| `Welt_WuchsGeste` | `world/logic/kategorie_welt/welt_wuchs_geste.gd` | 23 |

#### Signale (Rolle in dieser Domaene)

| Signal | Rolle | mitwirkende Domaenen |
| --- | --- | --- |
| `Kern_SignalBus.decken_entfernt` | V | kern, welt |
| `Kern_SignalBus.kachel_geaendert` | V | kern, tools, welt |
| `Kern_Weltuhr.tick` | V | ein, kern, obj, orch, rest, tier, ui, welt |
| `Ui_BauPanelSzene.bau_gewaehlt` | V | ui, welt |
| `Welt_AsyncChunkLader.chunk_gefuellt` | DS | rest, tools, welt |
| `Welt_AsyncChunkLader.fertig` | DS | rest, welt |
| `Welt_KarawanenManager.handels_abgeschlossen` | DS | welt |
| `Welt_KarawanenManager.karawane_angekommen` | DS | welt |
| `Welt_KarawanenManager.karawane_entladen` | DS | welt |
| `Welt_KarawanenManager.karawane_gestartet` | DS | welt |
| `Welt_PauseMenue.menue_gewuenscht` | DS | rest, welt |

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `String` | 12 |
| `Dictionary` | 7 |
| `int` | 5 |
| `Vector2i` | 3 |
| `Welt_Karawane` | 3 |
| `float` | 2 |
| `Objekt_Basis` | 1 |
| `RefCounted` | 1 |
| `Vector2` | 1 |
| `Welt_Fraktion` | 1 |
| `Welt_FraktionsKiMaschine` | 1 |

### world/objekt — Kuerzel `obj` — `world/logic/kategorie_objekt/`

Prefix `Objekt_/Gebaeude_`, 38 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Gebaeude_BauAuftrag` | `world/logic/kategorie_objekt/gebaeude_bau_auftrag.gd` | 137 |
| `Gebaeude_BauMaschine` | `world/logic/kategorie_objekt/gebaeude_bau_maschine.gd` | 102 |
| `Gebaeude_BauplatzPruefer` | `world/logic/kategorie_objekt/gebaeude_bauplatz_pruefer.gd` | 60 |
| `Gebaeude_Definition` | `world/logic/kategorie_objekt/gebaeude_definition.gd` | 83 |
| `Gebaeude_DefinitionRegistry` | `world/logic/kategorie_objekt/gebaeude_definition_registry.gd` | 55 |
| `Gebaeude_KartenGate` | `world/logic/kategorie_objekt/gebaeude_karten_gate.gd` | 17 |
| `Gebaeude_Laufzeit` | `world/logic/kategorie_objekt/gebaeude_laufzeit.gd` | 170 |
| `Gebaeude_Manager` | `world/logic/kategorie_objekt/gebaeude_manager.gd` | 150 |
| `Gebaeude_ProduktionsMaschine` | `world/logic/kategorie_objekt/gebaeude_produktions_maschine.gd` | 111 |
| `Gebaeude_Registry` | `world/logic/kategorie_objekt/gebaeude_registry.gd` | 33 |
| `Gebaeude_StatusLeser` | `world/logic/kategorie_objekt/gebaeude_status_leser.gd` | 62 |
| `Natur_Registry` | `world/logic/kategorie_objekt/natur_registry.gd` | 31 |
| `Objekt_Basis` | `world/logic/kategorie_objekt/objekt_basis.gd` | 65 |
| `Objekt_Baum` | `world/logic/kategorie_objekt/objekt_baum.gd` | 31 |
| `Objekt_Baumstumpf` | `world/logic/kategorie_objekt/objekt_baumstumpf.gd` | 28 |
| `Objekt_Berg` | `world/logic/kategorie_objekt/objekt_berg.gd` | 30 |
| `Objekt_Bett` | `world/logic/kategorie_objekt/objekt_bett.gd` | 10 |
| `Objekt_Erzader` | `world/logic/kategorie_objekt/objekt_erzader.gd` | 30 |
| `Objekt_Felswand` | `world/logic/kategorie_objekt/objekt_felswand.gd` | 30 |
| `Objekt_Haus` | `world/logic/kategorie_objekt/objekt_haus.gd` | 28 |
| `Objekt_Hausgross` | `world/logic/kategorie_objekt/objekt_hausgross.gd` | 28 |
| `Objekt_Kachel` | `world/logic/kategorie_objekt/objekt_kachel.gd` | 50 |
| `Objekt_Kadaver` | `world/logic/kategorie_objekt/objekt_kadaver.gd` | 14 |
| `Objekt_KatalogLader` | `world/logic/kategorie_objekt/objekt_katalog_lader.gd` | 50 |
| `Objekt_KategorieSicht` | `world/logic/kategorie_objekt/objekt_kategorie_sicht.gd` | 41 |
| `Objekt_Lagerfeuer` | `world/logic/kategorie_objekt/objekt_lagerfeuer.gd` | 20 |
| `Objekt_MoebelPlatzierer` | `world/logic/kategorie_objekt/objekt_moebel_platzierer.gd` | 70 |
| `Objekt_MoebelRegistry` | `world/logic/kategorie_objekt/moebel_registry.gd` | 71 |
| `Objekt_Registry` | `world/logic/kategorie_objekt/objekt_registry.gd` | 31 |
| `Objekt_RegistryBasis` | `world/logic/kategorie_objekt/objekt_registry_basis.gd` | 69 |
| `Objekt_Ruine` | `world/logic/kategorie_objekt/objekt_ruine.gd` | 30 |
| `Objekt_Schrank` | `world/logic/kategorie_objekt/objekt_schrank.gd` | 10 |
| `Objekt_Stein` | `world/logic/kategorie_objekt/objekt_stein.gd` | 30 |
| `Objekt_Steingruppe` | `world/logic/kategorie_objekt/objekt_steingruppe.gd` | 30 |
| `Objekt_Steinkreis` | `world/logic/kategorie_objekt/objekt_steinkreis.gd` | 30 |
| `Objekt_Stuhl` | `world/logic/kategorie_objekt/objekt_stuhl.gd` | 10 |
| `Objekt_Tisch` | `world/logic/kategorie_objekt/objekt_tisch.gd` | 10 |
| `Objekt_TischStahl` | `world/logic/kategorie_objekt/objekt_tisch_stahl.gd` | 10 |

#### Signale (Rolle in dieser Domaene)

| Signal | Rolle | mitwirkende Domaenen |
| --- | --- | --- |
| `Gebaeude_Manager.gebaeude_fertiggestellt` | DS | obj, tools |
| `Gebaeude_Manager.gebaeude_meldung` | DS | obj, rest |
| `Gebaeude_Manager.gebaeude_platziert` | DS | obj, rest |
| `Gebaeude_Manager.status_geaendert` | DS | obj, rest |
| `Kern_SignalBus.menue_geoeffnet` | V | kern, obj |
| `Kern_Weltuhr.tick` | V | ein, kern, obj, orch, rest, tier, ui, welt |
| `Objekt_MoebelPlatzierer.moebel_platziert` | DS | obj, rest |

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `String` | 13 |
| `Objekt_Basis` | 4 |
| `Dictionary` | 1 |
| `Gebaeude_Definition` | 1 |

### world/tier — Kuerzel `tier` — `world/logic/kategorie_tier/`

Prefix `Tier_`, 21 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Tier_Baer` | `world/logic/kategorie_tier/tier_baer.gd` | 40 |
| `Tier_Basis` | `world/logic/kategorie_tier/tier_basis.gd` | 63 |
| `Tier_Darsteller` | `world/logic/kategorie_tier/tier_darsteller.gd` | 92 |
| `Tier_DarstellerFabrik` | `world/logic/kategorie_tier/tier_darsteller_fabrik.gd` | 38 |
| `Tier_Eisbaer` | `world/logic/kategorie_tier/tier_eisbaer.gd` | 26 |
| `Tier_FeldAbfrage` | `world/logic/kategorie_tier/tier_feld_abfrage.gd` | 40 |
| `Tier_Hase` | `world/logic/kategorie_tier/tier_hase.gd` | 38 |
| `Tier_KlassenFabrik` | `world/logic/kategorie_tier/tier_klassen_fabrik.gd` | 22 |
| `Tier_Leser` | `world/logic/kategorie_tier/tier_leser.gd` | 64 |
| `Tier_Manager` | `world/logic/kategorie_tier/tier_manager.gd` | 146 |
| `Tier_Registry` | `world/logic/kategorie_tier/tier_registry.gd` | 75 |
| `Tier_SichtWaechter` | `world/logic/kategorie_tier/tier_sicht_waechter.gd` | 82 |
| `Tier_Sichtung` | `world/logic/kategorie_tier/tier_sichtung.gd` | 68 |
| `Tier_Status` | `world/logic/kategorie_tier/tier_status.gd` | 111 |
| `Tier_Takt` | `world/logic/kategorie_tier/tier_takt.gd` | 50 |
| `Tier_TempoBerechnung` | `world/logic/kategorie_tier/tier_tempo_berechnung.gd` | 32 |
| `Tier_VerhaltenMaschine` | `world/logic/kategorie_tier/tier_verhalten_maschine.gd` | 115 |
| `Tier_VitalStatus` | `world/logic/kategorie_tier/tier_vital_status.gd` | 18 |
| `Tier_Vogel` | `world/logic/kategorie_tier/tier_vogel.gd` | 40 |
| `Tier_Vogelgruppe` | `world/logic/kategorie_tier/tier_vogelgruppe.gd` | 40 |
| `Tier_ZustandsNamen` | `world/logic/kategorie_tier/tier_zustands_namen.gd` | 27 |

#### Signale (Rolle in dieser Domaene)

| Signal | Rolle | mitwirkende Domaenen |
| --- | --- | --- |
| `Einheit_Status.zustand_geaendert` | SV | ein, orch, tier |
| `Kern_Weltuhr.tick` | V | ein, kern, obj, orch, rest, tier, ui, welt |
| `Orchestrator_Status.zustand_geaendert` | SV | ein, orch, tier |
| `Tier_Status.zustand_geaendert` | DSV | ein, orch, tier |

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `Dictionary` | 4 |
| `Tier_Basis` | 1 |
| `int` | 1 |

### world/orchestrator — Kuerzel `orch` — `world/logic/kategorie_orchestrator/`

Prefix `Orchestrator_`, 11 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Orchestrator_Darsteller` | `world/logic/kategorie_orchestrator/orchestrator_darsteller.gd` | 63 |
| `Orchestrator_EinheitDerWelt` | `world/logic/kategorie_orchestrator/orchestrator_einheit.gd` | 49 |
| `Orchestrator_KonfigLader` | `world/logic/kategorie_orchestrator/orchestrator_konfig_lader.gd` | 18 |
| `Orchestrator_Konfiguration` | `world/logic/kategorie_orchestrator/orchestrator_konfiguration.gd` | 68 |
| `Orchestrator_Manager` | `world/logic/kategorie_orchestrator/orchestrator_manager.gd` | 111 |
| `Orchestrator_Registry` | `world/logic/kategorie_orchestrator/orchestrator_registry.gd` | 58 |
| `Orchestrator_SpawnCap` | `world/logic/kategorie_orchestrator/orchestrator_spawn_cap.gd` | 30 |
| `Orchestrator_Status` | `world/logic/kategorie_orchestrator/orchestrator_status.gd` | 50 |
| `Orchestrator_Verdrahtung` | `world/logic/kategorie_orchestrator/orchestrator_verdrahtung.gd` | 30 |
| `Orchestrator_Verteiler` | `world/logic/kategorie_orchestrator/orchestrator_verteiler.gd` | 52 |
| `Orchestrator_ZielSuche` | `world/logic/kategorie_orchestrator/orchestrator_ziel_suche.gd` | 34 |

#### Signale (Rolle in dieser Domaene)

| Signal | Rolle | mitwirkende Domaenen |
| --- | --- | --- |
| `Einheit_Status.zustand_geaendert` | SV | ein, orch, tier |
| `Kern_Weltuhr.tick` | V | ein, kern, obj, orch, rest, tier, ui, welt |
| `Orchestrator_Manager.orchestrator_platziert` | DS | orch |
| `Orchestrator_Status.bedarf_pruefen` | DSV | orch |
| `Orchestrator_Status.zustand_geaendert` | DSV | ein, orch, tier |
| `Tier_Status.zustand_geaendert` | SV | ein, orch, tier |

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `Dictionary` | 3 |
| `Orchestrator_Darsteller` | 1 |
| `Orchestrator_Konfiguration` | 1 |

### game/einheit — Kuerzel `ein` — `game/logic/kategorie_einheit/`

Prefix `Einheit_`, 31 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Einheit_Basis` | `game/logic/kategorie_einheit/einheit_basis.gd` | 52 |
| `Einheit_Bewegung` | `game/logic/kategorie_einheit/einheit_bewegung.gd` | 82 |
| `Einheit_Darsteller` | `game/logic/kategorie_einheit/einheit_darsteller.gd` | 83 |
| `Einheit_EinwanderungsMaschine` | `game/logic/kategorie_einheit/einheit_einwanderungs_maschine.gd` | 99 |
| `Einheit_ErnteMaschine` | `game/logic/kategorie_einheit/einheit_ernte_maschine.gd` | 113 |
| `Einheit_Inventar` | `game/logic/kategorie_einheit/einheit_inventar.gd` | 197 |
| `Einheit_InventarMutationAbgabe` | `game/logic/kategorie_einheit/einheit_inventar_mutation_abgabe.gd` | 26 |
| `Einheit_InventarMutationAufnahme` | `game/logic/kategorie_einheit/einheit_inventar_mutation_aufnahme.gd` | 22 |
| `Einheit_InventarMutationStart` | `game/logic/kategorie_einheit/einheit_inventar_mutation_start.gd` | 20 |
| `Einheit_InventarSchema` | `game/logic/kategorie_einheit/einheit_inventar_schema.gd` | 45 |
| `Einheit_JobFlussMaschine` | `game/logic/kategorie_einheit/einheit_job_fluss_maschine.gd` | 117 |
| `Einheit_JobQueue` | `game/logic/kategorie_einheit/einheit_job_queue.gd` | 42 |
| `Einheit_JobRegie` | `game/logic/kategorie_einheit/einheit_job_regie.gd` | 98 |
| `Einheit_JobVergabeMaschine` | `game/logic/kategorie_einheit/einheit_job_vergabe_maschine.gd` | 51 |
| `Einheit_LeseSchnittstelle` | `game/logic/kategorie_einheit/einheit_lese_schnittstelle.gd` | 82 |
| `Einheit_Manager` | `game/logic/kategorie_einheit/einheit_manager.gd` | 148 |
| `Einheit_MutationErnte` | `game/logic/kategorie_einheit/einheit_mutation_ernte.gd` | 42 |
| `Einheit_MutationStartBestaende` | `game/logic/kategorie_einheit/einheit_mutation_ressourcen.gd` | 22 |
| `Einheit_Ressourcen` | `game/logic/kategorie_einheit/einheit_ressourcen.gd` | 264 |
| `Einheit_RessourcenSchema` | `game/logic/kategorie_einheit/einheit_ressourcen_schema.gd` | 51 |
| `Einheit_Status` | `game/logic/kategorie_einheit/einheit_status.gd` | 119 |
| `Einheit_TaktMaschine` | `game/logic/kategorie_einheit/einheit_takt_maschine.gd` | 120 |
| `Einheit_TransportMaschine` | `game/logic/kategorie_einheit/einheit_transport_maschine.gd` | 40 |
| `Einheit_TruppMaschine` | `game/logic/kategorie_einheit/einheit_trupp_maschine.gd` | 104 |
| `Einheit_Verdrahtung` | `game/logic/kategorie_einheit/einheit_verdrahtung.gd` | 274 |
| `Einheit_VerhaltensMaschine` | `game/logic/kategorie_einheit/einheit_verhaltens_maschine.gd` | 100 |
| `Einheit_Versorgung` | `game/logic/kategorie_einheit/einheit_versorgung.gd` | 48 |
| `Einheit_VersorgungsMaschine` | `game/logic/kategorie_einheit/einheit_versorgungs_maschine.gd` | 47 |
| `Einheit_VitalStatus` | `game/logic/kategorie_einheit/einheit_vital_status.gd` | 120 |
| `Einheit_WegPlanung` | `game/logic/kategorie_einheit/einheit_weg_planung.gd` | 109 |
| `Einheit_ZielSuche` | `game/logic/kategorie_einheit/einheit_ziel_suche.gd` | 109 |

#### Signale (Rolle in dieser Domaene)

| Signal | Rolle | mitwirkende Domaenen |
| --- | --- | --- |
| `Einheit_ErnteMaschine.beute_erlegt` | DSV | ein |
| `Einheit_ErnteMaschine.inventar_voll` | DSV | ein |
| `Einheit_ErnteMaschine.schlag_objekt_gemeldet` | DSV | ein |
| `Einheit_ErnteMaschine.schlag_ort_gemeldet` | DSV | ein |
| `Einheit_Inventar.bestand_geaendert` | DS | ein, ui |
| `Einheit_Inventar.inventar_leer` | DS | ein |
| `Einheit_Inventar.inventar_voll` | DSV | ein |
| `Einheit_Ressourcen.bestand_geaendert` | DS | ein, ui |
| `Einheit_Status.arbeitsschritt_erledigt` | DSV | ein, job |
| `Einheit_Status.gestorben` | DSV | ein, kern, pop, rest |
| `Einheit_Status.job_beendet` | DSV | ein, tools |
| `Einheit_Status.job_loop_gefragt` | DSV | ein |
| `Einheit_Status.job_vergeben_fehlgeschlagen` | DS | ein |
| `Einheit_Status.naechster_job_aus_queue` | DSV | ein, tools |
| `Einheit_Status.zustand_geaendert` | DSV | ein, orch, tier |
| `Einheit_VitalStatus.gestorben` | DSV | ein, kern, pop, rest |
| `Einheit_VitalStatus.hp_veraendert` | DS | ein |
| `Einheit_VitalStatus.modifikator_geandert` | DS | ein |
| `Job_Basis.arbeitsschritt_erledigt` | SV | ein, job |
| `Job_Basis.job_beendet` | SV | ein, job, tools |
| `Kern_ModifikatorMaschine.aktualisiert` | V | ein, kern |
| `Kern_SignalBus.gestorben` | SV | ein, kern, pop, rest |
| `Kern_Weltuhr.tick` | V | ein, kern, obj, orch, rest, tier, ui, welt |
| `Orchestrator_Status.zustand_geaendert` | SV | ein, orch, tier |
| `Tier_Status.zustand_geaendert` | SV | ein, orch, tier |

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `Dictionary` | 9 |
| `int` | 4 |
| `String` | 3 |
| `Vector2` | 3 |
| `Ressource_Basis` | 2 |
| `Kern_ModifikatorBasis` | 1 |

### game/job — Kuerzel `job` — `game/logic/kategorie_job/`

Prefix `Job_`, 18 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Job_Basis` | `game/logic/kategorie_job/job_basis.gd` | 75 |
| `Job_BaustelleBeliefern` | `game/logic/kategorie_job/job_baustelle_beliefern.gd` | 16 |
| `Job_BeerenSammler` | `game/logic/kategorie_job/job_beeren_sammler.gd` | 11 |
| `Job_FaehigkeitsPruefung` | `game/logic/kategorie_job/job_faehigkeits_pruefung.gd` | 17 |
| `Job_Graben` | `game/logic/kategorie_job/job_graben.gd` | 46 |
| `Job_Heiler` | `game/logic/kategorie_job/job_heiler.gd` | 14 |
| `Job_Holzfaeller` | `game/logic/kategorie_job/job_holzfaeller.gd` | 11 |
| `Job_HolzfaellerStumpf` | `game/logic/kategorie_job/job_holzfaeller_stumpf.gd` | 11 |
| `Job_Jaeger` | `game/logic/kategorie_job/job_jaeger.gd` | 15 |
| `Job_JaegerKadaver` | `game/logic/kategorie_job/job_jaeger_kadaver.gd` | 11 |
| `Job_Kannibale` | `game/logic/kategorie_job/job_kannibale.gd` | 8 |
| `Job_Konfiguration` | `game/logic/kategorie_job/job_konfiguration.gd` | 52 |
| `Job_Orchestrieren` | `game/logic/kategorie_job/job_orchestrieren.gd` | 39 |
| `Job_Registry` | `game/logic/kategorie_job/job_registry.gd` | 84 |
| `Job_Steinmetz` | `game/logic/kategorie_job/job_steinmetz.gd` | 11 |
| `Job_Transport` | `game/logic/kategorie_job/job_transport.gd` | 73 |
| `Job_ZeitRechnung` | `game/logic/kategorie_job/job_zeit_rechnung.gd` | 25 |
| `Job_ZielPruefung` | `game/logic/kategorie_job/job_ziel_pruefung.gd` | 18 |

#### Signale (Rolle in dieser Domaene)

| Signal | Rolle | mitwirkende Domaenen |
| --- | --- | --- |
| `Einheit_Status.arbeitsschritt_erledigt` | S | ein, job |
| `Job_Basis.arbeitsschritt_erledigt` | DS | ein, job |
| `Job_Basis.job_beendet` | D | ein, job, tools |

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `String` | 4 |

### game/ressourcen — Kuerzel `res` — `game/logic/kategorie_ressourcen/`

Prefix `Resource_`, 7 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Ressource_Basis` | `game/logic/kategorie_ressourcen/ressource_basis.gd` | 35 |
| `Ressource_Beeren` | `game/logic/kategorie_ressourcen/ressource_beeren.gd` | 17 |
| `Ressource_Fleisch` | `game/logic/kategorie_ressourcen/ressource_fleisch.gd` | 20 |
| `Ressource_Holz` | `game/logic/kategorie_ressourcen/ressource_holz.gd` | 22 |
| `Ressource_Raeuchelfleisch` | `game/logic/kategorie_ressourcen/ressource_raeuchelfleisch.gd` | 22 |
| `Ressource_Stein` | `game/logic/kategorie_ressourcen/ressource_stein.gd` | 20 |
| `Ressource_Werkzeug` | `game/logic/kategorie_ressourcen/ressource_werkzeug.gd` | 20 |

#### Signale (Rolle in dieser Domaene)

_keine Signal-Deklaration in dieser Domaene_

#### Arrays (`Array[Typ]`)

_keine typisierten Arrays in dieser Domaene_

### population — Kuerzel `pop` — `population/`

Prefix `Pop_`, 30 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Pop_Denkblase` | `population/logic/mood/pop_denkblase.gd` | 58 |
| `Pop_Mood` | `population/logic/mood/pop_mood.gd` | 42 |
| `Pop_MoodAbleitung` | `population/logic/mood/pop_mood_ableitung.gd` | 60 |
| `Pop_MoodEskalation` | `population/logic/mood/pop_mood_eskalation.gd` | 68 |
| `Pop_MoodEskalationStufe` | `population/logic/mood/pop_mood_eskalation_stufe.gd` | 25 |
| `Pop_MoodMaschine` | `population/logic/mood/pop_mood_maschine.gd` | 113 |
| `Pop_MoodModifikator` | `population/logic/mood/pop_mood_modifikator.gd` | 56 |
| `Pop_MoodModifikatorRegistry` | `population/logic/mood/pop_mood_modifikator_registry.gd` | 57 |
| `Pop_MoodRaten` | `population/logic/mood/pop_mood_raten.gd` | 37 |
| `Pop_MoodWaermeGate` | `population/logic/mood/pop_mood_waerme_gate.gd` | 85 |
| `Pop_NamensGenerator` | `population/logic/pop_namens_generator.gd` | 128 |
| `Pop_NeedBasis` | `population/logic/needs/pop_need_basis.gd` | 30 |
| `Pop_NeedBaum` | `population/logic/mood/pop_need_baum.gd` | 68 |
| `Pop_NeedNahrung` | `population/logic/needs/pop_need_nahrung.gd` | 33 |
| `Pop_NeedRegistry` | `population/logic/needs/pop_need_registry.gd` | 79 |
| `Pop_NeedWaerme` | `population/logic/needs/pop_need_waerme.gd` | 6 |
| `Pop_RassenGenerator` | `population/logic/needs/pop_rassen_generator.gd` | 138 |
| `Pop_RassenSchema` | `population/logic/needs/pop_rassen_schema.gd` | 162 |
| `Pop_RassenSchemaRegistry` | `population/logic/needs/pop_rassen_schema_registry.gd` | 92 |
| `Pop_RassenZugriff` | `population/logic/needs/pop_rassen_zugriff.gd` | 29 |
| `Soz_BeziehungsEngine` | `population/logic/sozial/logic/soz_beziehungs_engine.gd` | 57 |
| `Soz_Datenpool` | `population/logic/sozial/logic/soz_datenpool.gd` | 24 |
| `Soz_Denkblase` | `population/logic/sozial/logic/soz_denkblase.gd` | 58 |
| `Soz_EthikLedger` | `population/logic/sozial/logic/soz_ethik_ledger.gd` | 26 |
| `Soz_Geruecht` | `population/logic/sozial/logic/soz_geruecht.gd` | 38 |
| `Soz_GeruechtMaschine` | `population/logic/sozial/logic/soz_geruecht_maschine.gd` | 78 |
| `Soz_ImageGlaube` | `population/logic/sozial/logic/soz_image_glaube.gd` | 16 |
| `Soz_Manager` | `population/logic/sozial/logic/soz_manager.gd` | 105 |
| `Soz_TraitLedger` | `population/logic/sozial/logic/soz_trait_ledger.gd` | 37 |
| `Soz_ZeugenMaschine` | `population/logic/sozial/logic/soz_zeugen_maschine.gd` | 57 |

#### Signale (Rolle in dieser Domaene)

| Signal | Rolle | mitwirkende Domaenen |
| --- | --- | --- |
| `Einheit_Status.gestorben` | V | ein, kern, pop, rest |
| `Einheit_VitalStatus.gestorben` | V | ein, kern, pop, rest |
| `Kern_SignalBus.gestorben` | V | ein, kern, pop, rest |
| `Pop_MoodMaschine.mood_geaendert` | DSV | pop |
| `verteilung_dialog.verteilung_gesetzt` | DS | pop, ui |

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `String` | 4 |
| `Dictionary` | 1 |
| `Pop_MoodEskalationStufe` | 1 |
| `Pop_MoodModifikator` | 1 |
| `Pop_NeedBasis` | 1 |
| `Pop_RassenSchema` | 1 |
| `Soz_Geruecht` | 1 |
| `float` | 1 |
| `int` | 1 |

### economy — Kuerzel `lager` — `economy/`

Prefix `Lager_`, 7 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Lager_Basis` | `economy/logic/storage/lager_basis.gd` | 22 |
| `Lager_Darsteller` | `economy/logic/storage/lager_darsteller.gd` | 60 |
| `Lager_Manager` | `economy/logic/storage/lager_manager.gd` | 136 |
| `Lager_MutationEinlagern` | `economy/logic/storage/lager_mutation.gd` | 34 |
| `Lager_MutationEntnehmen` | `economy/logic/storage/lager_entnahme.gd` | 32 |
| `Lager_Registry` | `economy/logic/storage/lager_registry.gd` | 51 |
| `Lager_StapelBauer` | `economy/logic/storage/lager_stapel_bauer.gd` | 95 |

#### Signale (Rolle in dieser Domaene)

| Signal | Rolle | mitwirkende Domaenen |
| --- | --- | --- |
| `Kern_SignalBus.lager_geaendert` | V | kern, lager |

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `Array` | 1 |
| `Dictionary` | 1 |
| `Label` | 1 |
| `Lager_Basis` | 1 |
| `Sprite2D` | 1 |
| `String` | 1 |

### ui — Kuerzel `ui` — `ui/`

Prefix `Ui_`, 24 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Menue_BuehnenMeister` | `ui/logic/kategorie_ui/menue_buehnen_meister.gd` | 348 |
| `Menue_StoryDaten` | `ui/logic/kategorie_ui/menue_story_daten.gd` | 54 |
| `Menue_StoryRegisseur` | `ui/logic/kategorie_ui/menue_story_regisseur.gd` | 49 |
| `Menue_Unterschrift` | `ui/logic/kategorie_ui/menue_unterschrift.gd` | 34 |
| `Ui_AuswahlManager` | `ui/scenes/selection/auswahl_manager.gd` | 50 |
| `Ui_AuswahlMarkierung` | `ui/logic/kategorie_ui/ui_auswahl_markierung.gd` | 60 |
| `Ui_BauAuftragMaschine` | `ui/logic/kategorie_ui/ui_bau_auftrag_maschine.gd` | 65 |
| `Ui_BauPanel` | `ui/logic/kategorie_ui/ui_bau_panel.gd` | 37 |
| `Ui_BauPanelSzene` | `ui/scenes/panels/bau_panel.gd` | 59 |
| `Ui_DebugPanelSzene` | `ui/scenes/hud/hud_debug_panel.gd` | 46 |
| `Ui_EingabeSteuerung` | `ui/logic/kategorie_ui/ui_eingabe_steuerung.gd` | 369 |
| `Ui_EinheitPanel` | `ui/logic/kategorie_ui/ui_einheit_panel.gd` | 39 |
| `Ui_ExpansionMaschine` | `ui/logic/kategorie_ui/ui_expansion_maschine.gd` | 38 |
| `Ui_JobVergabeMaschine` | `ui/logic/kategorie_ui/ui_job_vergabe_maschine.gd` | 105 |
| `Ui_KameraSteuerung` | `ui/logic/kategorie_ui/ui_kamera_steuerung.gd` | 54 |
| `Ui_KartenViewer` | `ui/logic/kategorie_ui/ui_karten_viewer.gd` | 139 |
| `Ui_LadeLeiste` | `ui/logic/kategorie_ui/ui_lade_leiste.gd` | 69 |
| `Ui_MenueZustaende` | `ui/logic/kategorie_ui/ui_menue_zustaende.gd` | 23 |
| `Ui_OrchestratorPriorityPanel` | `ui/logic/kategorie_ui/ui_orchestrator_priority_panel.gd` | 208 |
| `Ui_PopEinheitUebersetzer` | `ui/logic/kategorie_ui/ui_pop_einheit_uebersetzer.gd` | 112 |
| `Ui_TierPanel` | `ui/logic/kategorie_ui/ui_tier_panel.gd` | 36 |
| `Ui_WeltAuswahlDialog` | `ui/logic/kategorie_ui/ui_welt_auswahl_dialog.gd` | 58 |
| `Ui_WeltInfo` | `ui/logic/kategorie_ui/ui_welt_info.gd` | 33 |
| `Ui_WeltSitzung` | `ui/logic/kategorie_ui/ui_welt_sitzung.gd` | 40 |

#### Signale (Rolle in dieser Domaene)

| Signal | Rolle | mitwirkende Domaenen |
| --- | --- | --- |
| `Einheit_Inventar.bestand_geaendert` | V | ein, ui |
| `Einheit_Ressourcen.bestand_geaendert` | V | ein, ui |
| `Kern_SignalBus.einheit_ausgewaehlt` | V | kern, ui |
| `Kern_Weltuhr.tick` | V | ein, kern, obj, orch, rest, tier, ui, welt |
| `Ui_BauPanelSzene.bau_gewaehlt` | DS | ui, welt |
| `Ui_EingabeSteuerung.debug_umgeschaltet` | DS | rest, ui |
| `Ui_OrchestratorPriorityPanel.panel_geschlossen` | DS | ui |
| `Ui_WeltAuswahlDialog.welt_gewaehlt` | DSV | ui |
| `kontext_menue.aktion_gewaehlt` | DS | rest, ui |
| `verteilung_dialog.verteilung_gesetzt` | V | pop, ui |

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `String` | 7 |
| `Dictionary` | 5 |
| `int` | 3 |
| `AnimatedSprite2D` | 1 |

### shinon — Kuerzel `shinon` — `shinon/`

Prefix `Shinon_`, 0 Klassen.

#### Signale (Rolle in dieser Domaene)

_keine Signal-Deklaration in dieser Domaene_

#### Arrays (`Array[Typ]`)

_keine typisierten Arrays in dieser Domaene_

### tools — Kuerzel `tools` — `tools/`

Prefix `-`, 0 Klassen.

#### Signale (Rolle in dieser Domaene)

| Signal | Rolle | mitwirkende Domaenen |
| --- | --- | --- |
| `Einheit_Status.job_beendet` | S | ein, tools |
| `Einheit_Status.naechster_job_aus_queue` | V | ein, tools |
| `Gebaeude_Manager.gebaeude_fertiggestellt` | V | obj, tools |
| `Job_Basis.job_beendet` | S | ein, job, tools |
| `Kern_SignalBus.kachel_geaendert` | V | kern, tools, welt |
| `Welt_AsyncChunkLader.chunk_gefuellt` | V | rest, tools, welt |
| `Welt_ProgressionsMaschine.folge_objekt_entstanden` | V | rest, tools |
| `Welt_ProgressionsMaschine.stadium_geaendert` | V | rest, tools |

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `String` | 3 |
| `Kern_ModifikatorBasis` | 1 |
| `Pop_MoodMaschine` | 1 |
| `Vector2i` | 1 |
| `int` | 1 |

### rest — Kuerzel `rest` — `(kein Domaenen-Ordner)`

Prefix `-`, 33 Klassen.

| Klasse | Datei | Zeilen |
| --- | --- | --- |
| `Welt_AtmosphaereKonfig` | `world/logic/kategorie_atmosphaere/welt_atmosphaere_konfig.gd` | 74 |
| `Welt_AtmosphaereVerdrahtung` | `world/logic/kategorie_atmosphaere/welt_atmosphaere_verdrahtung.gd` | 160 |
| `Welt_BiomBasis` | `world/logic/kategorie_biom/biom_basis.gd` | 41 |
| `Welt_BiomManager` | `world/logic/kategorie_biom/biom_manager.gd` | 45 |
| `Welt_BiomMutation` | `world/logic/kategorie_biom/biom_mutation.gd` | 34 |
| `Welt_BiomRegistry` | `world/logic/kategorie_biom/biom_registry.gd` | 59 |
| `Welt_ComicOverlayer` | `world/logic/kategorie_atmosphaere/welt_comic_overlayer.gd` | 120 |
| `Welt_FeedbackManager` | `world/logic/kategorie_feedback/feedback_manager.gd` | 64 |
| `Welt_FeedbackTexturCache` | `world/logic/kategorie_feedback/feedback_textur_cache.gd` | 28 |
| `Welt_FortschrittsMaschine` | `world/logic/kategorie_progression/welt_fortschritts_maschine.gd` | 109 |
| `Welt_FortschrittsRegistry` | `world/logic/kategorie_progression/welt_fortschritts_registry.gd` | 49 |
| `Welt_PapierKornEbene` | `world/logic/kategorie_atmosphaere/welt_papier_korn_ebene.gd` | 88 |
| `Welt_PapierLicht` | `world/logic/kategorie_atmosphaere/welt_papier_licht.gd` | 69 |
| `Welt_PlusAnzeige` | `world/logic/kategorie_feedback/feedback_plus_anzeige.gd` | 70 |
| `Welt_ProgressionsMaschine` | `world/logic/kategorie_progression/welt_progressions_maschine.gd` | 99 |
| `Welt_ProgressionsRegistry` | `world/logic/kategorie_progression/welt_progressions_registry.gd` | 80 |
| `Welt_RessourcenZustand` | `world/logic/kategorie_progression/welt_ressourcen_zustand.gd` | 176 |
| `Welt_SchadenAnzeige` | `world/logic/kategorie_feedback/feedback_schaden_anzeige.gd` | 68 |
| `Welt_SchlagStaub` | `world/logic/kategorie_atmosphaere/welt_schlag_staub.gd` | 92 |
| `Welt_SeedSpawnMaschine` | `world/logic/kategorie_progression/welt_seed_spawn_maschine.gd` | 101 |
| `Welt_SonnenEffekt` | `world/logic/kategorie_atmosphaere/welt_sonnen_effekt.gd` | 123 |
| `Welt_StufenBilder` | `world/logic/kategorie_progression/welt_stufen_bilder.gd` | 91 |
| `Welt_SwayAktualisierer` | `world/logic/kategorie_atmosphaere/welt_sway_aktualisierer.gd` | 29 |
| `Welt_SwayMaterial` | `world/logic/kategorie_atmosphaere/welt_sway_material.gd` | 75 |
| `Welt_TagesZyklusFaerbung` | `world/logic/kategorie_tageszyklus/welt_tageszyklus_faerbung.gd` | 53 |
| `Welt_TagesZyklusSpeicher` | `world/logic/kategorie_tageszyklus/welt_tageszyklus_speicher.gd` | 20 |
| `Welt_TageszyklusMaschine` | `world/logic/kategorie_tageszyklus/tageszyklus_maschine.gd` | 107 |
| `Welt_TiefenNeige` | `world/logic/kategorie_atmosphaere/welt_tiefen_neige.gd` | 88 |
| `Welt_TodAnzeige` | `world/logic/kategorie_feedback/feedback_tod_anzeige.gd` | 66 |
| `Welt_WaermeFaktor` | `world/logic/kategorie_progression/welt_waerme_faktor.gd` | 22 |
| `Welt_WaermeFeld` | `world/logic/kategorie_waerme/waerme_feld.gd` | 50 |
| `Welt_WaermeShader` | `world/logic/kategorie_waerme/waerme_shader.gd` | 27 |
| `Welt_WindRechner` | `world/logic/kategorie_atmosphaere/welt_wind_rechner.gd` | 51 |

#### Signale (Rolle in dieser Domaene)

| Signal | Rolle | mitwirkende Domaenen |
| --- | --- | --- |
| `Einheit_Status.gestorben` | V | ein, kern, pop, rest |
| `Einheit_VitalStatus.gestorben` | V | ein, kern, pop, rest |
| `Gebaeude_Manager.gebaeude_meldung` | V | obj, rest |
| `Gebaeude_Manager.gebaeude_platziert` | V | obj, rest |
| `Gebaeude_Manager.status_geaendert` | V | obj, rest |
| `Kern_SignalBus.gestorben` | V | ein, kern, pop, rest |
| `Kern_SignalBus.produktionsraum_entstanden` | V | kern, rest |
| `Kern_SignalBus.schaden_erhalten` | V | kern, rest |
| `Kern_SignalBus.timeline_eintrag` | V | kern, rest |
| `Kern_Timeline.eintrag_neu` | V | kern, rest |
| `Kern_Weltuhr.tick` | V | ein, kern, obj, orch, rest, tier, ui, welt |
| `Objekt_MoebelPlatzierer.moebel_platziert` | V | obj, rest |
| `Ui_EingabeSteuerung.debug_umgeschaltet` | V | rest, ui |
| `Welt_AsyncChunkLader.chunk_gefuellt` | V | rest, tools, welt |
| `Welt_AsyncChunkLader.fertig` | V | rest, welt |
| `Welt_FortschrittsMaschine.orchestrator_gespawnt` | DS | rest |
| `Welt_FortschrittsMaschine.stufe_erreicht` | DSV | rest |
| `Welt_FortschrittsMaschine.ziel_erreicht` | DSV | rest |
| `Welt_PauseMenue.menue_gewuenscht` | V | rest, welt |
| `Welt_ProgressionsMaschine.folge_objekt_entstanden` | DS | rest, tools |
| `Welt_ProgressionsMaschine.objekt_erschoepft` | DSV | rest |
| `Welt_ProgressionsMaschine.saemling_gespawnt` | DS | rest |
| `Welt_ProgressionsMaschine.stadium_geaendert` | DS | rest, tools |
| `Welt_TageszyklusMaschine.phase_geaendert` | DSV | rest |
| `kontext_menue.aktion_gewaehlt` | V | rest, ui |

#### Arrays (`Array[Typ]`)

| Array-Elementtyp | Vorkommen |
| --- | --- |
| `Dictionary` | 4 |
| `String` | 3 |
| `Orchestrator_Darsteller` | 1 |
| `Sprite2D` | 1 |
| `Vector2` | 1 |
| `Welt_BiomBasis` | 1 |
| `int` | 1 |

---

Version: V0.01

