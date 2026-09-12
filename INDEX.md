# INDEX.md — LLM-Übersicht SnipWarfare

Diese Datei ist die maschinenlesbare Übersicht für Agenten und Werkzeuge. Sie ersetzt `AGENTEN_INDEX.md` (der nur noch als Redirect bestehen bleibt) und führt in Daten, Zuständigkeiten und Abhängigkeiten — ohne die Verfassung `AGENTS.md` zu duplizieren.

> Regel 0 gilt auch hier: Der Code ist die Wahrheit. Dieser Index beschreibt den Code, er ist kein Ersatz für ihn. Wenn Index und Code sich widersprechen, gewinnt der Code, und der Index wird über `python tools/index_generieren.py` nachgezogen.

Leseordnung: `AGENTS.md` (Verfassung) → `INDEX.md` (dieser Router) → `Architektur.md` (Referenz) → `ROADMAP.md` (Plan) → Datenpool der Aufgabe.

## 1. Domänen-Tabelle

| Ordner | Prefix | Datenbesitzer (JSON) | Erzeugung und Tick | Erweiterungsgrenze |
| --- | --- | --- | --- | --- |
| `core/` | `Kern_` | `kern_modifikatoren.json`, `modifikator_settings.json`, `kern_logik.json` | `Kern_Weltuhr` (Autoload, 24 Hz), `Kern_ModifikatorMaschine` je State-Maschine, `Kern_SignalBus`, `Kern_Zufall`, `Kern_Timeline` | neuer Modifikator/Bereich/Logik nur als Pool-Eintrag |
| `world/logic/kategorie_generator/` | `Welt_` | `generator_gewichte.json`, `welt_definition.json`, `weltkarte_definition.json` | `Welt_Generator`, `Welt_MakroGenerator`, `Welt_GeneratorVerteilung` | Gewicht/Cluster/Biom-Eintrag plus Asset |
| `world/logic/kategorie_welt/` | `Welt_` | `welt_definition.json`, `standard_welt.json`, `biome.json`, `atmosphaere.json` | `Welt_Model`, `Welt_Renderer`, `Welt_Speicher`, `Welt_World`, `Welt_MapFabrik` | Katalog/Definitions-Eintrag, keine zweite Erzeugung |
| `world/logic/kategorie_objekt/` | `Objekt_`, `Gebaeude_` | `element_katalog.json`, `gebaeude.json` | `Objekt_RegistryBasis`, `Gebaeude_Manager`, `Gebaeude_BauMaschine` | Katalog/Gebäude-Eintrag mit `script`-Feld plus Asset |
| `world/logic/kategorie_tier/` | `Tier_` | `tier_verhalten.json`, `biome.json` | `Tier_Manager`, `Tier_Status`, `Tier_Registry` | Katalog/Verhalten-Eintrag plus Cluster |
| `game/logic/kategorie_einheit/` | `Einheit_` | `ressourcen.json`, `job_config.json` | `Einheit_Manager`, `Einheit_Status`, `Einheit_VitalStatus` | Job-Klasse plus `script`-Feld, Ressourcen-Pool plus Icon |
| `game/logic/kategorie_job/` | `Job_` | `job_config.json` | `Job_Registry`, `Job_Basis` | Job-Klasse plus `script`-Feld |
| `game/logic/kategorie_ressourcen/` | `Resource_` | `ressourcen.json` | `Einheit_Ressourcen` | Ressourcen-Pool plus `script`-Feld |
| `population/` | `Pop_` | `needs.json`, `mood_modifikatoren.json`, `rassen_schemata.json` | `Pop_NeedBaum`, `Pop_MoodMaschine`, `Pop_Denkblase` | Need-Klasse plus `script`, Rassen-Schema, Eskalationsstufe |
| `economy/logic/storage/` | `Lager_` | `lager.json` | `Lager_Registry`, `Lager_Manager` | neuer Lagertyp nur als Template-Eintrag |
| `ui/` | `Ui_` | `steuerung.json` (konsumiert) | `Ui_EingabeSteuerung`, `Ui_KameraSteuerung`, Panels | neue Aktion mit `logik_id` plus Decode-Zweig |
| `world/terrain`, `world/settlements`, `world/resources`, `world/infrastructure`, `military/` | — | — | Gerüste mit `.gitkeep` | neuer Inhalt in passende Domäne, Militär getrennt |

## 2. Zuständigkeiten (Registry → Maschine → Model)

| Frage | Datenklasse | Registry (erzeugt) | Maschine/Manager (tickt an Weltuhr) | Model/Mutation (schreibt) |
| --- | --- | --- | --- | --- |
| Weltobjekt (Baum, Stein, Haus, Feuer) | `Objekt_*` | `Objekt_RegistryBasis` (`_objekt_klasse_fuer` über `script`) | `Welt_Generator`, `Welt_Renderer` | `Welt_Model` via Mutationen |
| Gebäude und Produktion | `Gebaeude_Definition` | `Gebaeude_DefinitionRegistry` | `Gebaeude_Manager`, `Gebaeude_BauMaschine`, `Gebaeude_ProduktionsMaschine` | `Welt_Model` Zusatzfelder |
| Tiere und Verhalten | `Tier_*` | `Tier_Registry` | `Tier_Manager`, `Tier_Status` | `Welt_Model`/`Tier_Daten` |
| Jobs und Ernte | `Job_*` | `Job_Registry` | `Einheit_Status`, `Einheit_ErnteMaschine`, `Einheit_Manager` | `Einheit_Ressourcen` + `Lager_Manager` |
| Ressourcen und Bestände | `Resource_*` | `Einheit_Ressourcen._ressourcen_klasse_fuer` | `Einheit_ErnteMaschine`, `Lager_Manager` | `Kern_Timeline` (Warum-Kette) |
| Bedürfnisse und Stimmung | `Pop_Need*`, `Pop_Mood*` | `Pop_NeedRegistry`, `Pop_MoodModifikatorRegistry` | `Pop_NeedBaum`, `Pop_MoodMaschine` | `Pop_Mood` (Emoji/Blase) |
| Lager und Speicher | `Lager_Basis` | `Lager_Registry` | `Lager_Manager` | `Lager_MutationEinlagern`/`Entnehmen` |
| Zeit und Zufall | `Kern_ModifikatorBasis` | `Kern_ModifikatorRegistry` | `Kern_Weltuhr`, `Kern_Zufall` | `Welt_TageszyklusMaschine` |

Eine Erweiterung ist immer Daten plus Asset: Pool-Eintrag mit `script`-Verweis, sichtbarem Asset, Registry lädt die exakte Klasse — Maschinen bleiben unberührt.

## 3. Abhängigkeits-Graph (wer liest wen)

```
JSON-Pool ──script-Feld──► Registry ──erzeugt──► Datenklasse
                                    │
                                    ▼
Kern_Weltuhr (24 Hz) ──tick──► Maschine/Manager ──schreibt──► Welt_Model / Lager_Manager
                                    │                              │
                                    │ liest                        │ beobachtet
                                    ▼                              ▼
                            Kern_Zufall / Kern_LogikRegistry   Welt_Renderer / HUD / Panels
                                    ▲                              ▲
                                    │         Ui_EingabeSteuerung ─┘
                                    └──────── Kern_SignalBus / Kern_Timeline
```

Spielkette der Eingabe: `Ui_EingabeSteuerung` + `Ui_KameraSteuerung` → Manager/Maschine → `Welt_Model` → `Welt_Renderer`/HUD/Panels. Szenen unter `*/scenes/` verdrahten nur, sie rechnen keine Fachlogik.

**Pflege:** Neuer Datenpool → in Abschnitt 1 und 2 nachtragen. Neue Präfix-Regel → `AGENTS.md` und `tools/preflight/kern.py` plus diese Tabelle. Neuer Preflight-Code → `Architektur.md` Abschnitt 6 und hier in Abschnitt 1.

<!-- INVENTAR:START -->

## 4. Index-Familie (auto-generiert)

_Quelle: `python tools/index_generieren.py` — die vier Indizes werden aus dem Code erzeugt._

| Index | Datei | Inhalt |
| --- | --- | --- |
| Wurzel | [`INDEX.md`](INDEX.md) | Index-Familie und Klasseninventar |
| Domaenen | [`INDEX_DOMAENEN.md`](INDEX_DOMAENEN.md) | Klassen, Signal- und Array-Matrix je Domaene |
| Daten | [`INDEX_DATEN.md`](INDEX_DATEN.md) | JSON-Pools mit Besitzer und Verbrauchern |
| Letzte Aenderung | [`INDEX_LETZTE_AENDERUNG.md`](INDEX_LETZTE_AENDERUNG.md) | Delta des letzten Index-Laufs |

_Stand: V0.01 — 247 Klassen mit `class_name` im Projekt, davon 217 in den 14 Domaenen-Ordnern und 30 ohne Domaenen-Ordner, 63 Signale, 31 Array-Elementtypen und 30 JSON-Pools._

## 5. Klasseninventar (auto-generiert)

_Quelle: `python tools/index_generieren.py` — scannt `class_name` je Domaene._

### core — Prefix `Kern_` — `core/` (19)

| Klasse | Datei |
| --- | --- |
| `Kern_AssetPruefer` | `core/logic/kern_asset_pruefer.gd` |
| `Kern_LogikBasis` | `core/logic/kern_logik_basis.gd` |
| `Kern_LogikRegistry` | `core/logic/kern_logik_registry.gd` |
| `Kern_ModifikatorBasis` | `core/logic/kern_modifikator_basis.gd` |
| `Kern_ModifikatorMaschine` | `core/logic/kern_modifikator_maschine.gd` |
| `Kern_ModifikatorRegistry` | `core/logic/kern_modifikator_registry.gd` |
| `Kern_Mutation` | `core/logic/kern_mutation.gd` |
| `Kern_Mutationsschema` | `core/logic/kern_mutationsschema.gd` |
| `Kern_PathFinder` | `core/logic/kategorie_pathfinding/path_finder.gd` |
| `Kern_PathKnoten` | `core/logic/kategorie_pathfinding/path_knoten.gd` |
| `Kern_PathNetz` | `core/logic/kategorie_pathfinding/path_netz.gd` |
| `Kern_PathRegistry` | `core/logic/kategorie_pathfinding/path_registry.gd` |
| `Kern_SignalBus` | `core/logic/events/kern_signal_bus.gd` |
| `Kern_SteuerungBasis` | `core/logic/kern_steuerung_basis.gd` |
| `Kern_SteuerungRegistry` | `core/logic/kern_steuerung_registry.gd` |
| `Kern_Timeline` | `core/logic/events/kern_timeline.gd` |
| `Kern_TimelineEintrag` | `core/logic/events/kern_timeline_eintrag.gd` |
| `Kern_Weltuhr` | `core/logic/clock/weltuhr.gd` |
| `Kern_Zufall` | `core/logic/kern_zufall.gd` |

### world/generator — Prefix `Welt_` — `world/logic/kategorie_generator/` (12)

| Klasse | Datei |
| --- | --- |
| `Welt_BiomAnalyser` | `world/logic/kategorie_generator/welt_biom_analyser.gd` |
| `Welt_FeldAnalyser` | `world/logic/kategorie_generator/welt_feld_analyser.gd` |
| `Welt_FraktionsGenerator` | `world/logic/kategorie_generator/welt_fraktions_generator.gd` |
| `Welt_FraktionsKeimlingAnalysator` | `world/logic/kategorie_generator/fraktions_keimling_analysator.gd` |
| `Welt_Generator` | `world/logic/kategorie_generator/welt_generator.gd` |
| `Welt_GeneratorChunkPruefer` | `world/logic/kategorie_generator/generator_chunk_pruefer.gd` |
| `Welt_GeneratorFelsmassive` | `world/logic/kategorie_generator/generator_felsmassive.gd` |
| `Welt_GeneratorFliesenWahl` | `world/logic/kategorie_generator/generator_fliesen_wahl.gd` |
| `Welt_GeneratorGewaesser` | `world/logic/kategorie_generator/generator_gewaesser.gd` |
| `Welt_GeneratorObjektStempel` | `world/logic/kategorie_generator/generator_objekt_stempel.gd` |
| `Welt_GeneratorRegistry` | `world/logic/kategorie_generator/generator_registry.gd` |
| `Welt_GeneratorVerteilung` | `world/logic/kategorie_generator/generator_verteilung.gd` |

### world/welt — Prefix `Welt_` — `world/logic/kategorie_welt/` (41)

| Klasse | Datei |
| --- | --- |
| `Welt_BauGeist` | `world/logic/kategorie_welt/welt_bau_geist.gd` |
| `Welt_BaustellenBedarf` | `world/logic/kategorie_welt/welt_baustellen_bedarf.gd` |
| `Welt_DefinitionRegistry` | `world/logic/kategorie_welt/welt_definition_registry.gd` |
| `Welt_EditorWerkzeug` | `world/logic/kategorie_welt/welt_editor_werkzeug.gd` |
| `Welt_ErschoepfungMaschine` | `world/logic/kategorie_welt/welt_erschoepfung_maschine.gd` |
| `Welt_Fraktion` | `world/logic/kategorie_welt/welt_fraktion.gd` |
| `Welt_FraktionsKiMaschine` | `world/logic/kategorie_welt/fraktions_ki_maschine.gd` |
| `Welt_FraktionsKiVerdrahtung` | `world/logic/kategorie_welt/welt_fraktions_ki_verdrahtung.gd` |
| `Welt_GrenzProfil` | `world/logic/kategorie_welt/welt_grenz_profil.gd` |
| `Welt_HudRueckmeldung` | `world/logic/kategorie_welt/welt_hud_rueckmeldung.gd` |
| `Welt_KachelGeste` | `world/logic/kategorie_welt/welt_kachel_geste.gd` |
| `Welt_Karawane` | `world/logic/kategorie_welt/welt_karawane.gd` |
| `Welt_KarawanenManager` | `world/logic/kategorie_welt/welt_karawanen_manager.gd` |
| `Welt_KartenBeobachter` | `world/logic/kategorie_welt/welt_karten_beobachter.gd` |
| `Welt_Ladevorgang` | `world/logic/kategorie_welt/welt_ladevorgang.gd` |
| `Welt_LagerFabrik` | `world/logic/kategorie_welt/welt_lager_fabrik.gd` |
| `Welt_LandeplatzAnzeige` | `world/logic/kategorie_welt/welt_landeplatz_anzeige.gd` |
| `Welt_MakroGenerator` | `world/logic/kategorie_welt/welt_makro_generator.gd` |
| `Welt_MapFabrik` | `world/logic/kategorie_welt/welt_map_fabrik.gd` |
| `Welt_Model` | `world/logic/kategorie_welt/welt_model.gd` |
| `Welt_NetzwerkPlaner` | `world/logic/kategorie_welt/welt_netzwerk_planer.gd` |
| `Welt_ObjektDarsteller` | `world/logic/kategorie_welt/welt_objekt_darsteller.gd` |
| `Welt_ObjektGitter` | `world/logic/kategorie_welt/welt_objekt_gitter.gd` |
| `Welt_ObjektKnoten` | `world/logic/kategorie_welt/welt_objekt_knoten.gd` |
| `Welt_PauseMenue` | `world/logic/kategorie_welt/welt_pause_menue.gd` |
| `Welt_RaumAnalyser` | `world/logic/kategorie_welt/welt_raum_analyser.gd` |
| `Welt_Registry` | `world/logic/kategorie_welt/welt_registry.gd` |
| `Welt_RegistryBasis` | `world/logic/kategorie_welt/welt_registry_basis.gd` |
| `Welt_Renderer` | `world/logic/kategorie_welt/welt_renderer.gd` |
| `Welt_RissGeste` | `world/logic/kategorie_welt/welt_riss_geste.gd` |
| `Welt_SichtbereichSammler` | `world/logic/kategorie_welt/welt_sichtbereich_sammler.gd` |
| `Welt_Speicher` | `world/logic/kategorie_welt/welt_speicher.gd` |
| `Welt_StadiumGeste` | `world/logic/kategorie_welt/welt_stadium_geste.gd` |
| `Welt_TerrainBlatt` | `world/logic/kategorie_welt/welt_terrain_blatt.gd` |
| `Welt_TierPlatzierer` | `world/logic/kategorie_welt/welt_tier_platzierer.gd` |
| `Welt_UiAufbau` | `world/logic/kategorie_welt/welt_ui_aufbau.gd` |
| `Welt_UmsturzGeste` | `world/logic/kategorie_welt/welt_umsturz_geste.gd` |
| `Welt_WaermeSammler` | `world/logic/kategorie_welt/welt_waerme_sammler.gd` |
| `Welt_WasserAutomat` | `world/logic/kategorie_welt/welt_wasser_automat.gd` |
| `Welt_World` | `world/logic/kategorie_welt/welt_world.gd` |
| `Welt_WuchsGeste` | `world/logic/kategorie_welt/welt_wuchs_geste.gd` |

### world/objekt — Prefix `Objekt_/Gebaeude_` — `world/logic/kategorie_objekt/` (31)

| Klasse | Datei |
| --- | --- |
| `Gebaeude_BauMaschine` | `world/logic/kategorie_objekt/gebaeude_bau_maschine.gd` |
| `Gebaeude_Definition` | `world/logic/kategorie_objekt/gebaeude_definition.gd` |
| `Gebaeude_DefinitionRegistry` | `world/logic/kategorie_objekt/gebaeude_definition_registry.gd` |
| `Gebaeude_Laufzeit` | `world/logic/kategorie_objekt/gebaeude_laufzeit.gd` |
| `Gebaeude_Manager` | `world/logic/kategorie_objekt/gebaeude_manager.gd` |
| `Gebaeude_ProduktionsMaschine` | `world/logic/kategorie_objekt/gebaeude_produktions_maschine.gd` |
| `Gebaeude_Registry` | `world/logic/kategorie_objekt/gebaeude_registry.gd` |
| `Natur_Registry` | `world/logic/kategorie_objekt/natur_registry.gd` |
| `Objekt_Basis` | `world/logic/kategorie_objekt/objekt_basis.gd` |
| `Objekt_Baum` | `world/logic/kategorie_objekt/objekt_baum.gd` |
| `Objekt_Baumstumpf` | `world/logic/kategorie_objekt/objekt_baumstumpf.gd` |
| `Objekt_Berg` | `world/logic/kategorie_objekt/objekt_berg.gd` |
| `Objekt_Bett` | `world/logic/kategorie_objekt/objekt_bett.gd` |
| `Objekt_Erzader` | `world/logic/kategorie_objekt/objekt_erzader.gd` |
| `Objekt_Felswand` | `world/logic/kategorie_objekt/objekt_felswand.gd` |
| `Objekt_Haus` | `world/logic/kategorie_objekt/objekt_haus.gd` |
| `Objekt_Hausgross` | `world/logic/kategorie_objekt/objekt_hausgross.gd` |
| `Objekt_Kachel` | `world/logic/kategorie_objekt/objekt_kachel.gd` |
| `Objekt_Kadaver` | `world/logic/kategorie_objekt/objekt_kadaver.gd` |
| `Objekt_Lagerfeuer` | `world/logic/kategorie_objekt/objekt_lagerfeuer.gd` |
| `Objekt_MoebelRegistry` | `world/logic/kategorie_objekt/moebel_registry.gd` |
| `Objekt_Registry` | `world/logic/kategorie_objekt/objekt_registry.gd` |
| `Objekt_RegistryBasis` | `world/logic/kategorie_objekt/objekt_registry_basis.gd` |
| `Objekt_Ruine` | `world/logic/kategorie_objekt/objekt_ruine.gd` |
| `Objekt_Schrank` | `world/logic/kategorie_objekt/objekt_schrank.gd` |
| `Objekt_Stein` | `world/logic/kategorie_objekt/objekt_stein.gd` |
| `Objekt_Steingruppe` | `world/logic/kategorie_objekt/objekt_steingruppe.gd` |
| `Objekt_Steinkreis` | `world/logic/kategorie_objekt/objekt_steinkreis.gd` |
| `Objekt_Stuhl` | `world/logic/kategorie_objekt/objekt_stuhl.gd` |
| `Objekt_Tisch` | `world/logic/kategorie_objekt/objekt_tisch.gd` |
| `Objekt_TischStahl` | `world/logic/kategorie_objekt/objekt_tisch_stahl.gd` |

### world/tier — Prefix `Tier_` — `world/logic/kategorie_tier/` (17)

| Klasse | Datei |
| --- | --- |
| `Tier_Baer` | `world/logic/kategorie_tier/tier_baer.gd` |
| `Tier_Basis` | `world/logic/kategorie_tier/tier_basis.gd` |
| `Tier_Darsteller` | `world/logic/kategorie_tier/tier_darsteller.gd` |
| `Tier_Eisbaer` | `world/logic/kategorie_tier/tier_eisbaer.gd` |
| `Tier_FeldAbfrage` | `world/logic/kategorie_tier/tier_feld_abfrage.gd` |
| `Tier_Hase` | `world/logic/kategorie_tier/tier_hase.gd` |
| `Tier_KlassenFabrik` | `world/logic/kategorie_tier/tier_klassen_fabrik.gd` |
| `Tier_Manager` | `world/logic/kategorie_tier/tier_manager.gd` |
| `Tier_Registry` | `world/logic/kategorie_tier/tier_registry.gd` |
| `Tier_Sichtung` | `world/logic/kategorie_tier/tier_sichtung.gd` |
| `Tier_Status` | `world/logic/kategorie_tier/tier_status.gd` |
| `Tier_TempoBerechnung` | `world/logic/kategorie_tier/tier_tempo_berechnung.gd` |
| `Tier_VerhaltenMaschine` | `world/logic/kategorie_tier/tier_verhalten_maschine.gd` |
| `Tier_VitalStatus` | `world/logic/kategorie_tier/tier_vital_status.gd` |
| `Tier_Vogel` | `world/logic/kategorie_tier/tier_vogel.gd` |
| `Tier_Vogelgruppe` | `world/logic/kategorie_tier/tier_vogelgruppe.gd` |
| `Tier_ZustandsNamen` | `world/logic/kategorie_tier/tier_zustands_namen.gd` |

### world/orchestrator — Prefix `Orchestrator_` — `world/logic/kategorie_orchestrator/` (7)

| Klasse | Datei |
| --- | --- |
| `Orchestrator_Darsteller` | `world/logic/kategorie_orchestrator/orchestrator_darsteller.gd` |
| `Orchestrator_EinheitDerWelt` | `world/logic/kategorie_orchestrator/orchestrator_einheit.gd` |
| `Orchestrator_Konfiguration` | `world/logic/kategorie_orchestrator/orchestrator_konfiguration.gd` |
| `Orchestrator_Manager` | `world/logic/kategorie_orchestrator/orchestrator_manager.gd` |
| `Orchestrator_Registry` | `world/logic/kategorie_orchestrator/orchestrator_registry.gd` |
| `Orchestrator_Status` | `world/logic/kategorie_orchestrator/orchestrator_status.gd` |
| `Orchestrator_Verdrahtung` | `world/logic/kategorie_orchestrator/orchestrator_verdrahtung.gd` |

### game/einheit — Prefix `Einheit_` — `game/logic/kategorie_einheit/` (25)

| Klasse | Datei |
| --- | --- |
| `Einheit_Darsteller` | `game/logic/kategorie_einheit/einheit_darsteller.gd` |
| `Einheit_EinwanderungsMaschine` | `game/logic/kategorie_einheit/einheit_einwanderungs_maschine.gd` |
| `Einheit_ErnteMaschine` | `game/logic/kategorie_einheit/einheit_ernte_maschine.gd` |
| `Einheit_Inventar` | `game/logic/kategorie_einheit/einheit_inventar.gd` |
| `Einheit_InventarMutationAbgabe` | `game/logic/kategorie_einheit/einheit_inventar_mutation_abgabe.gd` |
| `Einheit_InventarMutationAufnahme` | `game/logic/kategorie_einheit/einheit_inventar_mutation_aufnahme.gd` |
| `Einheit_InventarMutationStart` | `game/logic/kategorie_einheit/einheit_inventar_mutation_start.gd` |
| `Einheit_InventarSchema` | `game/logic/kategorie_einheit/einheit_inventar_schema.gd` |
| `Einheit_JobFlussMaschine` | `game/logic/kategorie_einheit/einheit_job_fluss_maschine.gd` |
| `Einheit_LeseSchnittstelle` | `game/logic/kategorie_einheit/einheit_lese_schnittstelle.gd` |
| `Einheit_Manager` | `game/logic/kategorie_einheit/einheit_manager.gd` |
| `Einheit_MutationErnte` | `game/logic/kategorie_einheit/einheit_mutation_ernte.gd` |
| `Einheit_MutationStartBestaende` | `game/logic/kategorie_einheit/einheit_mutation_ressourcen.gd` |
| `Einheit_Ressourcen` | `game/logic/kategorie_einheit/einheit_ressourcen.gd` |
| `Einheit_RessourcenSchema` | `game/logic/kategorie_einheit/einheit_ressourcen_schema.gd` |
| `Einheit_Status` | `game/logic/kategorie_einheit/einheit_status.gd` |
| `Einheit_TaktMaschine` | `game/logic/kategorie_einheit/einheit_takt_maschine.gd` |
| `Einheit_TransportMaschine` | `game/logic/kategorie_einheit/einheit_transport_maschine.gd` |
| `Einheit_TruppMaschine` | `game/logic/kategorie_einheit/einheit_trupp_maschine.gd` |
| `Einheit_VerhaltensMaschine` | `game/logic/kategorie_einheit/einheit_verhaltens_maschine.gd` |
| `Einheit_Versorgung` | `game/logic/kategorie_einheit/einheit_versorgung.gd` |
| `Einheit_VersorgungsMaschine` | `game/logic/kategorie_einheit/einheit_versorgungs_maschine.gd` |
| `Einheit_VitalStatus` | `game/logic/kategorie_einheit/einheit_vital_status.gd` |
| `Einheit_WegPlanung` | `game/logic/kategorie_einheit/einheit_weg_planung.gd` |
| `Einheit_ZielSuche` | `game/logic/kategorie_einheit/einheit_ziel_suche.gd` |

### game/job — Prefix `Job_` — `game/logic/kategorie_job/` (18)

| Klasse | Datei |
| --- | --- |
| `Job_Basis` | `game/logic/kategorie_job/job_basis.gd` |
| `Job_BaustelleBeliefern` | `game/logic/kategorie_job/job_baustelle_beliefern.gd` |
| `Job_BeerenSammler` | `game/logic/kategorie_job/job_beeren_sammler.gd` |
| `Job_FaehigkeitsPruefung` | `game/logic/kategorie_job/job_faehigkeits_pruefung.gd` |
| `Job_Graben` | `game/logic/kategorie_job/job_graben.gd` |
| `Job_Heiler` | `game/logic/kategorie_job/job_heiler.gd` |
| `Job_Holzfaeller` | `game/logic/kategorie_job/job_holzfaeller.gd` |
| `Job_HolzfaellerStumpf` | `game/logic/kategorie_job/job_holzfaeller_stumpf.gd` |
| `Job_Jaeger` | `game/logic/kategorie_job/job_jaeger.gd` |
| `Job_JaegerKadaver` | `game/logic/kategorie_job/job_jaeger_kadaver.gd` |
| `Job_Kannibale` | `game/logic/kategorie_job/job_kannibale.gd` |
| `Job_Konfiguration` | `game/logic/kategorie_job/job_konfiguration.gd` |
| `Job_Orchestrieren` | `game/logic/kategorie_job/job_orchestrieren.gd` |
| `Job_Registry` | `game/logic/kategorie_job/job_registry.gd` |
| `Job_Steinmetz` | `game/logic/kategorie_job/job_steinmetz.gd` |
| `Job_Transport` | `game/logic/kategorie_job/job_transport.gd` |
| `Job_ZeitRechnung` | `game/logic/kategorie_job/job_zeit_rechnung.gd` |
| `Job_ZielPruefung` | `game/logic/kategorie_job/job_ziel_pruefung.gd` |

### game/ressourcen — Prefix `Resource_` — `game/logic/kategorie_ressourcen/` (7)

| Klasse | Datei |
| --- | --- |
| `Ressource_Basis` | `game/logic/kategorie_ressourcen/ressource_basis.gd` |
| `Ressource_Beeren` | `game/logic/kategorie_ressourcen/ressource_beeren.gd` |
| `Ressource_Fleisch` | `game/logic/kategorie_ressourcen/ressource_fleisch.gd` |
| `Ressource_Holz` | `game/logic/kategorie_ressourcen/ressource_holz.gd` |
| `Ressource_Raeuchelfleisch` | `game/logic/kategorie_ressourcen/ressource_raeuchelfleisch.gd` |
| `Ressource_Stein` | `game/logic/kategorie_ressourcen/ressource_stein.gd` |
| `Ressource_Werkzeug` | `game/logic/kategorie_ressourcen/ressource_werkzeug.gd` |

### population — Prefix `Pop_` — `population/` (15)

| Klasse | Datei |
| --- | --- |
| `Pop_Denkblase` | `population/logic/mood/pop_denkblase.gd` |
| `Pop_Mood` | `population/logic/mood/pop_mood.gd` |
| `Pop_MoodEskalationStufe` | `population/logic/mood/pop_mood_eskalation_stufe.gd` |
| `Pop_MoodMaschine` | `population/logic/mood/pop_mood_maschine.gd` |
| `Pop_MoodModifikator` | `population/logic/mood/pop_mood_modifikator.gd` |
| `Pop_MoodModifikatorRegistry` | `population/logic/mood/pop_mood_modifikator_registry.gd` |
| `Pop_NamensGenerator` | `population/logic/pop_namens_generator.gd` |
| `Pop_NeedBasis` | `population/logic/needs/pop_need_basis.gd` |
| `Pop_NeedBaum` | `population/logic/mood/pop_need_baum.gd` |
| `Pop_NeedNahrung` | `population/logic/needs/pop_need_nahrung.gd` |
| `Pop_NeedRegistry` | `population/logic/needs/pop_need_registry.gd` |
| `Pop_NeedWaerme` | `population/logic/needs/pop_need_waerme.gd` |
| `Pop_RassenGenerator` | `population/logic/needs/pop_rassen_generator.gd` |
| `Pop_RassenSchema` | `population/logic/needs/pop_rassen_schema.gd` |
| `Pop_RassenSchemaRegistry` | `population/logic/needs/pop_rassen_schema_registry.gd` |

### economy — Prefix `Lager_` — `economy/` (6)

| Klasse | Datei |
| --- | --- |
| `Lager_Basis` | `economy/logic/storage/lager_basis.gd` |
| `Lager_Darsteller` | `economy/logic/storage/lager_darsteller.gd` |
| `Lager_Manager` | `economy/logic/storage/lager_manager.gd` |
| `Lager_MutationEinlagern` | `economy/logic/storage/lager_mutation.gd` |
| `Lager_MutationEntnehmen` | `economy/logic/storage/lager_entnahme.gd` |
| `Lager_Registry` | `economy/logic/storage/lager_registry.gd` |

### ui — Prefix `Ui_` — `ui/` (19)

| Klasse | Datei |
| --- | --- |
| `Ui_AuswahlManager` | `ui/scenes/selection/auswahl_manager.gd` |
| `Ui_AuswahlMarkierung` | `ui/logic/kategorie_ui/ui_auswahl_markierung.gd` |
| `Ui_BauAuftragMaschine` | `ui/logic/kategorie_ui/ui_bau_auftrag_maschine.gd` |
| `Ui_BauPanel` | `ui/logic/kategorie_ui/ui_bau_panel.gd` |
| `Ui_BauPanelSzene` | `ui/scenes/panels/bau_panel.gd` |
| `Ui_DebugPanelSzene` | `ui/scenes/hud/hud_debug_panel.gd` |
| `Ui_EingabeSteuerung` | `ui/logic/kategorie_ui/ui_eingabe_steuerung.gd` |
| `Ui_EinheitPanel` | `ui/logic/kategorie_ui/ui_einheit_panel.gd` |
| `Ui_ExpansionMaschine` | `ui/logic/kategorie_ui/ui_expansion_maschine.gd` |
| `Ui_JobVergabeMaschine` | `ui/logic/kategorie_ui/ui_job_vergabe_maschine.gd` |
| `Ui_KameraSteuerung` | `ui/logic/kategorie_ui/ui_kamera_steuerung.gd` |
| `Ui_KartenViewer` | `ui/logic/kategorie_ui/ui_karten_viewer.gd` |
| `Ui_MenueZustaende` | `ui/logic/kategorie_ui/ui_menue_zustaende.gd` |
| `Ui_OrchestratorPriorityPanel` | `ui/logic/kategorie_ui/ui_orchestrator_priority_panel.gd` |
| `Ui_PopEinheitUebersetzer` | `ui/logic/kategorie_ui/ui_pop_einheit_uebersetzer.gd` |
| `Ui_TierPanel` | `ui/logic/kategorie_ui/ui_tier_panel.gd` |
| `Ui_WeltAuswahlDialog` | `ui/logic/kategorie_ui/ui_welt_auswahl_dialog.gd` |
| `Ui_WeltInfo` | `ui/logic/kategorie_ui/ui_welt_info.gd` |
| `Ui_WeltSitzung` | `ui/logic/kategorie_ui/ui_welt_sitzung.gd` |

### shinon — Prefix `Shinon_` — `shinon/` (0)

_keine `class_name`-Klassen_

### tools — Prefix `-` — `tools/` (0)

_keine `class_name`-Klassen_

### rest — Prefix `-` — `(kein Domaenen-Ordner)` (30)

| Klasse | Datei |
| --- | --- |
| `Welt_AtmosphaereKonfig` | `world/logic/kategorie_atmosphaere/welt_atmosphaere_konfig.gd` |
| `Welt_AtmosphaereVerdrahtung` | `world/logic/kategorie_atmosphaere/welt_atmosphaere_verdrahtung.gd` |
| `Welt_BiomBasis` | `world/logic/kategorie_biom/biom_basis.gd` |
| `Welt_BiomManager` | `world/logic/kategorie_biom/biom_manager.gd` |
| `Welt_BiomMutation` | `world/logic/kategorie_biom/biom_mutation.gd` |
| `Welt_BiomRegistry` | `world/logic/kategorie_biom/biom_registry.gd` |
| `Welt_ComicOverlayer` | `world/logic/kategorie_atmosphaere/welt_comic_overlayer.gd` |
| `Welt_FeedbackManager` | `world/logic/kategorie_feedback/feedback_manager.gd` |
| `Welt_FeedbackTexturCache` | `world/logic/kategorie_feedback/feedback_textur_cache.gd` |
| `Welt_FortschrittsMaschine` | `world/logic/kategorie_progression/welt_fortschritts_maschine.gd` |
| `Welt_FortschrittsRegistry` | `world/logic/kategorie_progression/welt_fortschritts_registry.gd` |
| `Welt_PlusAnzeige` | `world/logic/kategorie_feedback/feedback_plus_anzeige.gd` |
| `Welt_ProgressionsMaschine` | `world/logic/kategorie_progression/welt_progressions_maschine.gd` |
| `Welt_ProgressionsRegistry` | `world/logic/kategorie_progression/welt_progressions_registry.gd` |
| `Welt_RessourcenZustand` | `world/logic/kategorie_progression/welt_ressourcen_zustand.gd` |
| `Welt_SchadenAnzeige` | `world/logic/kategorie_feedback/feedback_schaden_anzeige.gd` |
| `Welt_SchlagStaub` | `world/logic/kategorie_atmosphaere/welt_schlag_staub.gd` |
| `Welt_SeedSpawnMaschine` | `world/logic/kategorie_progression/welt_seed_spawn_maschine.gd` |
| `Welt_SonnenEffekt` | `world/logic/kategorie_atmosphaere/welt_sonnen_effekt.gd` |
| `Welt_StufenBilder` | `world/logic/kategorie_progression/welt_stufen_bilder.gd` |
| `Welt_SwayAktualisierer` | `world/logic/kategorie_atmosphaere/welt_sway_aktualisierer.gd` |
| `Welt_SwayMaterial` | `world/logic/kategorie_atmosphaere/welt_sway_material.gd` |
| `Welt_TagesZyklusFaerbung` | `world/logic/kategorie_tageszyklus/welt_tageszyklus_faerbung.gd` |
| `Welt_TagesZyklusSpeicher` | `world/logic/kategorie_tageszyklus/welt_tageszyklus_speicher.gd` |
| `Welt_TageszyklusMaschine` | `world/logic/kategorie_tageszyklus/tageszyklus_maschine.gd` |
| `Welt_TodAnzeige` | `world/logic/kategorie_feedback/feedback_tod_anzeige.gd` |
| `Welt_WaermeFaktor` | `world/logic/kategorie_progression/welt_waerme_faktor.gd` |
| `Welt_WaermeFeld` | `world/logic/kategorie_waerme/waerme_feld.gd` |
| `Welt_WaermeShader` | `world/logic/kategorie_waerme/waerme_shader.gd` |
| `Welt_WindRechner` | `world/logic/kategorie_atmosphaere/welt_wind_rechner.gd` |

<!-- INVENTAR:ENDE -->

Version: V0.01
