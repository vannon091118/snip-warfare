# Implementation Plan: 2D Godot Game Engine

## Overview

This plan outlines the implementation of a 2D Godot game engine with world generation, Z-depth mining, dynamic factions, resource transport, and parallel map simulation. The plan explicitly addresses all concrete problems mentioned by the user. Shinon watches from the corner of the room, sipping his bitter coffee, and comments that the original plan was one long bullet-point nap that went nowhere fast.

## Current State

- Core kernel system exists with PCG-based deterministic RNG
- World data structures exist with biome definitions, weights, and sample world
- Shinnon commit gate system is operational (E030-E036 requirements documented)
- Basic game logic modules (pathfinding, asset management, modifiers) are present
- Missing: Main world generation implementation, Z-layer system, faction system, resource transport, parallel simulation
- Key constraint: All code must pass shinon commit gate (no banners, no bullets, numbered sentences, file names mentioned)

## Concrete Problems This Plan Addresses

1. **Part-based building system**: Furniture placement via Job_MoebelPlatzieren generates production buildings, NOT whole buildings as placeholders. The player places individual furniture items from a godoview perspective, and only after enough furniture accumulates does a production room emerge from the tag chaos. Whole buildings as placeholders are banned to the memory hole.

2. **Z-depth mining**: Underground mining with Job_Graben, water integration via Wasser_Automat, cave systems with depth-dependent biomes. Deeper levels have higher Erz-Affinität, less light, and other temperature thresholds. Water only crosses Z-levels as a single special trigger, everything else stays per-layer isolated.

3. **Atlas world map**: SVG-based visualization of faction progress on the world map. House SVGs and coarse elements for tracking other factions' progress. The atlas gives the player a strategic overview without cluttering the main view.

4. **Visible heat/day-night cycle**: CanvasModulate + shader affects sprites, tilemaps, particles simultaneously. HUD shows stickman states with color indicating heat exposure. The day cycle runs on the world clock, not player frames. Heat gets a 15-line shader that takes waerme_wert as input and outputs warm-orange with alpha control. No polling, only on change.

5. **Jobs as chaining mechanism**: Internal job chaining for automation, NOT Rimworld-style work system. Resources must be physically transported via Job_Transport from harvest to storage. No magical resource spawning into storage ever. The Timeline records every Lager-Eingang as Delta-Buchung with Herkunfts-Einheit. If a unit's inventory fills during harvest, Job_Transport enqueues automatically to the next registered Lager.

6. **Orchestrator as town-hall NPC**: Spawned via Welt_FortschrittsMaschine when Rathaus furniture set triggers produktionsraum_entstanden. Orchestrator-Einheit is a normal unit with reserved Job_Orchestrieren running permanently. Player controls priorities via orchestrator_config.json. Spawn caps come from rassen_schemata.json. This is NOT a work system like Rimworld - direct RTS control with surveillance, player activates Orchestrator directly.

7. **Physical resource transport**: Resources must be carried via Job_Transport and visibly placed in Lager_Darsteller. NO magical spawning. Everything flows through explicit jobs. Unit carries resources from harvest to storage. Visible sprites placed via Lager_Darsteller. Capped at 5 icons, then number beside it.

8. **Dynamic faction/race generation**: No fixed races. Biome affinity determines race probability. Rassen_Generator samples from rassen_vorlagen.json ranges. Template has fields like "grab_bonus": [1.0, 2.0] instead of fixed numbers. Result: fully immutable Pop_RassenSchema. World features like many mountains = likely Dwarven race probable, forests = Elves probable. Resources want to spawn but only through Expansion and Espionage. World exhausted = growth stops (planned for later).

## Implementation Phases

### Phase 1: World Generation Foundation (Generator-Kern zuerst)

1. Implement Welt_Generator with three seeded FastNoiseLite instances (height, moisture, temperature). Each seeded via Kern_Zufall.abgeleitet_fuer("hoehe", welt_seed) - NEVER direct randomization. All three enable domain_warp_enabled = true with domain_warp_amplitude from generator_gewichte.json. Non-predictable biome boundaries via domain warping.

2. Create Generator_BiomAnalyse in kategorie_generator/. Reads three noise values per tile and matches against biome.json threshold tables. Produces biom_id per tile stored in Welt_Model as second grid alongside object grid. Same structure, separate array.

3. Generator_Felsmassive and Generator_Gewaesser already exist with biom-check gate before spawn. Fels spawns only on tiles with biom_affinitaet: "fels". Wasser spawns only on tiles with biom_affinitaet: "wasser". This stands in biome.json as field per entry - NO new code.

### Phase 2: Z-Depth Mining System

1. Extend Welt_Model with aktive_z_ebene: int (Standard 0, negativ = Untergrund).

2. Implement Welt_MapFabrik for generating Z-layer chunks. Creates separate chunk-map per Z-level (third address axis instead of card coordinate). Multi-map system for parallel cards works similarly, only with Z as third axis.

3. Create Job_Graben in job_config.json. Targets tile marked as Fels in current Z-level. Damages objekt_basis.leben of Fels tile. At 0, tile removed and tile below on Z-1 becomes visible. Generator has Z-1 layers generated with same Noise-System but depth-dependent biome parameters. Deeper = higher Erz-Affinität, less light, other temperature thresholds.

4. Implement Wasser_Automat running every 3 ticks on Weltuhr's Dirty-Queue. Each water tile checks four horizontal neighbors and tile directly below on Z-1. If target tile empty, moves water there and adds new water tile to Dirty-Queue for next tick. When ceiling removed by Job_Graben, emits Kern_SignalBus.decke_entfernt(position, z_ebene). Wasser_Automat adds all water tiles directly above to Dirty-Queue. THIS IS THE ONLY Cross-Z trigger - everything else stays per-isolated layer.

### Phase 3: Dynamic Factions & Fraction System

1. Implement Fraktions_Keimling_Analysator as last generator pass. Divides finished world into NxN makrocells, N from weltkarte_definition.json. Sums biome frequencies and resource densities per cell. Writes archetype_score Dictionary: {"berg": 0.7, "wald": 0.1, "wasser": 0.2}. If score exceeds threshold from fraktions_ki_config.json, creates Keimpunkt with Position and dominant Archetype. NO fixed faction count - world structure determines how many emerge.

2. Implement Rassen_Generator. Reads archetype of each Keimpunkt. Samples with Kern_Zufall.abgeleitet_fuer("rasse", keimpunkt_id) values from Ranges in rassen_vorlagen.json. Template has fields like "grab_bonus": [1.0, 2.0] instead of fixed numbers. Result: fully instantiated immutable Pop_RassenSchema. Pop_RassenSchemaRegistry registers it under generated rassen_id.

3. Fraction AI generates based on world features, not static placement. Many mountains = likely Dwarven race probable. Elves prefer forests. Aggression are resource-dependent. Resources want to spawn but only through Expansion and Espionage. World exhausted = growth stops (planned for later).

### Phase 4: More Tiles + Möbel-System

1. Set kachel_groesse in welt_definition.json to 32, double karten_breite and karten_hoehe. Welt_ObjektGitter scales automatically - calculates cell size relative to kachel_größe. Welt_Renderer renders only viewport - total size is free.

2. Create möbel.json with entries having id, tags-Array, script-reference and asset-path.

3. Create Möbel_Registry in game/logic/kategorie_möbel/. Instantiates exactly like object-Registry over the script-field.

4. Create new Job_MöbelPlatzieren. Places furniture on ground tile via Right-click context menu. Checks if tile is free, carries furniture from unit inventory, writes to Welt_Model as object entry. After placement, calls Raum_Analysator.analysiere(position). Flood-Fill over Welt_ObjektGitter recognizing wall tiles as boundaries. Aggregates all furniture tags in room - result is tag-set. Gebaeude_Manager compares tag-set against gebaeude.json entries now having benötigt_tags-Array instead of fixed building form. On match emits Kern_SignalBus.produktionsraum_entstandene(raum_id, profil). Gebaeude_ProduktionsMaschine begins ticking. Existing interface changes NOT - only the trigger.

5. Furniture system serves as part-based building environment. Player places furniture Minecraft-style from Vogelperspektive. Furniture placement generates production buildings. NOT whole buildings as placeholders.

### Phase 5: Visualization & Simulation

1. Build Atlas_Welt for viewing active/inactive maps. SVG-based visualization of faction progress on world map. House SVGs and coarse elements for tracking other factions' progress.

2. Implement Welt_World manager for parallel map simulation. Holds _karten: Dictionary with karten_id → Welt_Model. Each Welt_Model has ist_aktiv: bool. On card switch: sets previous Karte on ist_aktiv = false and new on true. Welt_Renderer renders only active Karte. Every manager has at tick entry: if not _model.ist_aktiv and Engine.get_process_frames() % 6 != 0: return. Inactive Karten run with 1/6 tick rate, without renderer load.

3. Add heat/day-night cycle with visible effects. Single CanvasModulate Node directly under Welt in scene hierarchy. Welt_TageszyklusMaschine sets every tick canvas_modulate.color = tages_farbe_fuer_tick(aktueller_tick). tages_farbe_fuer_tick from curve in atmosphaere.json interpolated: four waypoints - Morgen (warm weiß), Mittag (neutral weiß), Abend (orange), Nacht (dunkelblau). Godot's Color.lerp() between waypoints. Affects EVERY sprite, EVERY tilemap layer, EVERY particle simultaneously without further adjustment. Heat gets ShaderMaterial on ColorRect fullscreen over world with mouse_filter = IGNORE. Shader is 15 lines: uniform float waerme_wert input, color from Warm-Orange with waerme_wert as alpha output. Welt_WaermeSammler (already exists) sets after each tick-run $WaermeOverlay.material.set_shader_parameter("waerme_wert", aggregierter_wert). No polling, only on change.

4. Create Pop_EinheitPanel as PanelContainer for unit HUD. Visible on Kern_SignalBus.einheit_ausgewaehlt(einheit_id). Holds Übersetzer querying Pop_NeedBaum, Pop_MoodMaschine, Einheit_Status and Einheit_Ressourcen of selected unit. Signal-driven, no frame-polling. Fields: current job, hunger value with color scale, heat value, mood modifiers as scrollable list, inventory slots.

5. Lager_Darsteller observer node on Lager-Szene. On Kern_SignalBus.lager_geaendert(lager_id) reads storage contents. Places resource sprites on Lager-Kachel. Per resource type stacked sprite from ressource_holz.svg etc. Number of icons determines count (capped at 5 icons, then number beside it). NO change to Lager_Manager - just observer.

### Phase 6: Ressourcentransport physisch

1. Implement Job_Transport as core glue job. Derived from Job_BaustelleBeliebern as specialization. Also registered as standalone Folge-Job in job_config.json withfolge_job_id: "transport". At Ernte-Job when unit inventory full, automatically enqueues Job_Transport to next registered Lager in Lager_Registry. Transport always physical, always visible, always verifiable via "Warum?"-Dialog. Kern_Timeline writes every Lager-Eingang as Delta-Buchung mit Herkunfts-Einheit.

2. Resources must be physically transported and visibly placed. NO magical resource spawning into storage. Everything flows through explicit jobs. Unit carries resources from harvest to storage. Visible sprites placed via Lager_Darsteller.

### Phase 7: Fraktions-KI

1. Implement Fraktions_KI_Maschine running every 120 Weltuhr-Ticks (not every frame). Reads three thresholds from fraktions_ki_config.json: Expansion, Handel, Konflikt. Calculates current aggression as aggressions_basis * (ressourcen_bedarf / max(1, lager_bestand)). ressourcen_bedarf from rassen_schemata.json of generated race. If value exceeds Expansion threshold: sends Exploration units to adjacent chunks. Signal to Welt_MapFabrik generating new chunks for this faction and writing to its Welt_Model-Instance. If conflict threshold exceeded: emits Kern_SignalBus.konflikt_erklaert(fraktion_a, fraktion_b). World map visualizes as line color-change between faction nodes. Exhaustion counter set once per resource type per world chunk at generation. Can only be increased through new chunk generation via Expansion. If lager_bestand / erschoepfungs_maximum > 0.8 blocks Ressource_Basis.kann_spawnen(). This forces Expansion as ONLY growth strategy.

### Phase 8: Orchestrator als Rathaus-NPC

1. When Rathaus furniture set built (triggers produktionsraum_entstanden with profil: "rathaus"). Welt_FortschrittsMaschine spawns Orchestrator_Einheit via Einheit_Manager. Orchestrator-Einheit is normal unit with reserved Job_Orchestrieren running permanently.

2. Orchestrator_Manager reads every 60 ticks Einheit_Manager.idle_einheiten(). Selects from orchestrator_config.json jobs assigned by priority. Player can directly click Orchestrator and change orchestrator_config.json priorities via panel.

3. Spawn caps as max_einheiten in rassen_schemata.json of generated race. Welt_FortschrittsMaschine checks before every spawn: Einheit_Manager.einheiten_count() < rassen_schema.max_einheiten.

4. NOT a "work system" like Rimworld. Direct RTS control with surveillance. Player activates Orchestrator directly. Priority configurable via orchestrator_config.json.

### Phase 9: Polish & Integration

1. Validate all systems interact correctly.

2. Run headless simulations and verify visibility in-game.

3. Ensure shinon commit gate passes (E030-E036).

4. Finalize README and documentation.

## Risks & Dependencies

- Z-layer system: Requires careful integration with existing world model; water only cross-Z trigger.
- Faction AI: Needs robust expulsion/expansion logic based on resource levels; exhaustion counter mechanics.
- Resource transport: Must coordinate between units, jobs, and storage; no magical spawning.
- Parallel simulation: Background maps must not interfere with active gameplay; 1/6 tick rate for inactive.
- Shinon gate compliance: All code must pass E030-E036 checks; no banners, no bullets, numbered sentences, file names mentioned.
- Part-based building: Must ensure furniture placement generates buildings, not whole buildings as placeholders.

## Validation Steps

1. Generate sample world using Welt_Generator with three noise instances.
2. Verify Z-layers properly created and accessible with water integration.
3. Test faction expansion/conflict mechanics with dynamic generation.
4. Simulate resource transport from mines to storage with visible placement.
5. Confirm parallel map rendering works with 1/6 tick for inactive.
6. Run full simulation and verify shinon gate passes (check commit_msg.txt format).
7. Verify part-based building: place furniture -> check if production room triggered.

## Open Questions (must resolve before implementation)

1. Should Z-layers be separate mesh layers or tilemap layers? (affects water integration)
2. How should faction/race generation exactly map biomes to archetypes?
3. What job chaining mechanism preferred: direct links vs. queue? (must not fill job slots like Rimworld)
4. Should atlas map be separate view or integrated into main renderer?
5. How to balance resource consumption with growth when world exhausted?

## Next Action

Begin Phase 1: Implement Welt_Generator with three seeded FastNoiseLite instances and biome analysis, ensuring all code passes shinon commit gate formatting requirements (no banners, no bullets, numbered sentences, file names mentioned in shinon/commit_msg.txt).

## Shinon Commit Gate Requirements (must follow for all code)

- E030: No banner lines (more than 10 same special characters: Gleichzeichen, Rauten, Stern, Strich, Tilde)
- E031: No bullet lines (bullet list verbot)
- E032: Numbered sentences required - every content line starts with number + period + space, ends with period
- E033: Lifelike language as Shinon - vivid, in-universe, zynisch humorvoll, Stil-ästhetisch; min 180 words; technical code listings VIOLATE this
- E034: shinon/commit_msg.txt must exist (created before commit, not deleted after)
- E035: lebenswerte README.md from Shinon perspective - gamer-oriented, in-universe, zynisch humorvoll, stil-ästhetisch, min 180 words
- E036: Human-readable control configuration in game/data/steuerung.json with WASD for camera, Left click alone, Left hold and drag for amount, Right click opens context menu with "Sammeln" and "Abbauen" plus icon_path and tooltip with tool placeholder