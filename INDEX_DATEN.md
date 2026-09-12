# INDEX_DATEN.md — Daten-Index SnipWarfare

_Quelle: `python tools/index_generieren.py` — erzeugt aus dem Code, nie von Hand gepflegt._

Stand: V0.01 — 30 JSON-Pools, davon 30 lesbar und 2 ohne namentlichen Verbraucher.

## 1. Pools in Besitz einer Domaene

| Pool | Domaene | Eintraege | Oberste Schluessel | Verbraucher |
| --- | --- | --- | --- | --- |
| [`kern_logik.json`](core/data/kern_logik.json) | `core` | 9 | `baer_verfolgen`, `hase_flucht`, `vogel_flucht`, `vogelgruppe_flucht`, `ressource_holz`, `ressource_stein` und 3 weitere | `core/logic/kern_logik_basis.gd`, `core/logic/kern_logik_registry.gd`, `world/logic/kategorie_objekt/objekt_basis.gd` und 1 weitere |
| [`kern_modifikatoren.json`](core/data/kern_modifikatoren.json) | `core` | 7 | `normal`, `aggressiv`, `langsam`, `schnell`, `verletzung_bein`, `verletzung_arm` und 1 weitere | `core/logic/kern_modifikator_maschine.gd`, `core/logic/kern_modifikator_registry.gd` |
| [`modifikator_settings.json`](core/data/modifikator_settings.json) | `core` | 3 | `_kommentar`, `global`, `bereiche` | `core/logic/kern_modifikator_maschine.gd` |
| [`lager.json`](economy/data/lager.json) | `economy` | 2 | `kleines_lager`, `grosses_lager` | `economy/logic/storage/lager_registry.gd` |
| [`animationen.json`](game/data/animationen.json) | `game/data` | 8 | `laufen`, `idle`, `hacken`, `grind`, `raeuchern`, `flackern` und 2 weitere | `game/logic/kategorie_einheit/einheit_darsteller.gd`, `world/logic/kategorie_objekt/objekt_basis.gd`, `world/logic/kategorie_welt/welt_objekt_darsteller.gd` |
| [`job_config.json`](game/data/job_config.json) | `game/data` | 12 | `holzfaeller`, `steinmetz`, `jaeger`, `holzfaeller_stumpf`, `jaeger_kadaver`, `heiler` und 6 weitere | `game/logic/kategorie_job/job_basis.gd`, `game/logic/kategorie_job/job_beeren_sammler.gd`, `game/logic/kategorie_job/job_graben.gd` und 8 weitere |
| [`mutationen_inventar.json`](game/data/mutationen_inventar.json) | `game/data` | 3 | `schema_name`, `start_zustaende`, `mutationen` | `game/logic/kategorie_einheit/einheit_inventar.gd`, `game/logic/kategorie_einheit/einheit_inventar_schema.gd` |
| [`mutationen_ressourcen.json`](game/data/mutationen_ressourcen.json) | `game/data` | 3 | `schema_name`, `start_zustaende`, `mutationen` | `game/logic/kategorie_einheit/einheit_ressourcen_schema.gd` |
| [`möbel.json`](game/data/möbel.json) | `game/data` | 5 | `[Liste]` | `ui/logic/kategorie_ui/ui_bau_panel.gd`, `world/logic/kategorie_welt/welt_raum_analyser.gd` |
| [`orchestrator_config.json`](game/data/orchestrator_config.json) | `game/data` | 2 | `holzsammler_zone`, `jaeger_zone` | `ui/logic/kategorie_ui/ui_orchestrator_priority_panel.gd`, `world/logic/kategorie_orchestrator/orchestrator_manager.gd`, `world/logic/kategorie_orchestrator/orchestrator_registry.gd` und 1 weitere |
| [`progression.json`](game/data/progression.json) | `game/data` | 2 | `_kommentar`, `stufen` | `game/logic/kategorie_einheit/einheit_versorgungs_maschine.gd`, `world/logic/kategorie_progression/welt_fortschritts_registry.gd`, `world/logic/kategorie_progression/welt_progressions_registry.gd` und 1 weitere |
| [`ressourcen.json`](game/data/ressourcen.json) | `game/data` | 6 | `holz`, `stein`, `fleisch`, `werkzeug`, `raeuchelfleisch`, `beeren` | `game/logic/kategorie_einheit/einheit_inventar.gd`, `game/logic/kategorie_einheit/einheit_ressourcen.gd`, `game/logic/kategorie_einheit/einheit_ressourcen_schema.gd` und 2 weitere |
| [`steuerung.json`](game/data/steuerung.json) | `game/data` | 8 | `version`, `_kommentar`, `kamera`, `auswahl`, `kontextmenue`, `pathfinding` und 2 weitere | `core/logic/kategorie_pathfinding/path_registry.gd`, `core/logic/kern_steuerung_basis.gd`, `core/logic/kern_steuerung_registry.gd` und 5 weitere |
| [`bindung.json`](population/data/bindung.json) | `population` | 5 | `_kommentar`, `regeln`, `stufen`, `ereignisse`, `verlust` | keiner |
| [`mood_modifikatoren.json`](population/data/mood_modifikatoren.json) | `population` | 5 | `_kommentar`, `kaelte`, `hitze`, `hunger`, `kannibalismus` | `game/logic/kategorie_einheit/einheit_vital_status.gd`, `population/logic/mood/pop_mood_eskalation_stufe.gd`, `population/logic/mood/pop_mood_modifikator_registry.gd` und 1 weitere |
| [`needs.json`](population/data/needs.json) | `population` | 3 | `weltrhythmus`, `nahrung`, `waerme` | `game/logic/kategorie_einheit/einheit_manager.gd`, `game/logic/kategorie_einheit/einheit_versorgung.gd`, `population/logic/needs/pop_need_basis.gd` und 5 weitere |
| [`rassen_schemata.json`](population/data/rassen_schemata.json) | `population` | 3 | `mensch`, `elf`, `ork` | `population/logic/needs/pop_rassen_schema.gd`, `population/logic/needs/pop_rassen_schema_registry.gd`, `world/logic/kategorie_orchestrator/orchestrator_manager.gd` und 2 weitere |
| [`rassen_vorlagen.json`](population/data/rassen_vorlagen.json) | `population` | 6 | `_kommentar`, `wald`, `berg`, `wasser`, `steppe`, `tundra` | `population/logic/needs/pop_rassen_generator.gd` |
| [`atmosphaere.json`](world/data/atmosphaere.json) | `world/data` | 7 | `_dokumentation_atmosphaere`, `wind`, `partikel`, `sonne`, `papier`, `tageslicht` und 1 weitere | `world/logic/kategorie_atmosphaere/welt_atmosphaere_konfig.gd`, `world/logic/kategorie_atmosphaere/welt_comic_overlayer.gd` |
| [`biome.json`](world/data/biome.json) | `world/data` | 3 | `_kommentar`, `thresholds`, `biome` | `world/logic/kategorie_biom/biom_basis.gd`, `world/logic/kategorie_biom/biom_registry.gd`, `world/logic/kategorie_generator/welt_biom_analyser.gd` und 1 weitere |
| [`element_katalog.json`](world/data/element_katalog.json) | `world/data` | 32 | `[Liste]` | `game/logic/kategorie_einheit/einheit_manager.gd`, `ui/scenes/panels/kontext_menue.gd`, `world/logic/kategorie_objekt/objekt_registry_basis.gd` und 1 weitere |
| [`fraktions_ki_config.json`](world/data/fraktions_ki_config.json) | `world/data` | 9 | `_kommentar`, `expansion`, `handel`, `konflikt`, `aggressions_basis`, `keimling_schwellenwert` und 3 weitere | `world/logic/kategorie_generator/fraktions_keimling_analysator.gd`, `world/logic/kategorie_generator/welt_generator.gd`, `world/logic/kategorie_welt/fraktions_ki_maschine.gd` und 2 weitere |
| [`gebaeude.json`](world/data/gebaeude.json) | `world/data` | 4 | `[Liste]` | `tools/lauf_pruefung_welt.gd`, `ui/logic/kategorie_ui/ui_bau_panel.gd`, `world/logic/kategorie_objekt/gebaeude_definition.gd` und 1 weitere |
| [`generator_gewichte.json`](world/data/generator_gewichte.json) | `world/data` | 9 | `_kommentar`, `domain_warp_amplitude`, `objekte`, `tiere`, `biome`, `gebaeude` und 3 weitere | `world/logic/kategorie_generator/generator_registry.gd`, `world/logic/kategorie_generator/welt_feld_analyser.gd`, `world/logic/kategorie_generator/welt_fraktions_generator.gd` und 2 weitere |
| [`moral_regeln.json`](world/data/moral_regeln.json) | `world/data` | 5 | `_kommentar`, `grundsaetze`, `ersatzhandlungen`, `wirkung_je_rasse`, `verzweigung` | keiner |
| [`ressourcen_progression.json`](world/data/ressourcen_progression.json) | `world/data` | 5 | `_kommentar`, `stufen`, `stufen_blatt`, `waerme`, `seed_spawn` | `world/logic/kategorie_progression/welt_progressions_registry.gd`, `world/logic/kategorie_progression/welt_stufen_bilder.gd` |
| [`standard_welt.json`](world/data/standard_welt.json) | `world/data` | 6 | `version`, `kachel_groesse`, `raster_breite`, `raster_hoehe`, `raster`, `objekte` | `world/scenes/karten_editor.gd` |
| [`tier_verhalten.json`](world/data/tier_verhalten.json) | `world/data` | 5 | `hase`, `vogel`, `vogelgruppe`, `baer`, `eisbaer` | `game/logic/kategorie_job/job_jaeger.gd`, `world/logic/kategorie_tier/tier_baer.gd`, `world/logic/kategorie_tier/tier_basis.gd` und 4 weitere |
| [`welt_definition.json`](world/data/welt_definition.json) | `world/data` | 7 | `_kommentar`, `max_karten_groesse`, `min_karten_groesse`, `kachel_groesse`, `chunk_groesse`, `region_kante` und 1 weitere | `tools/lauf_pruefung_wasser.gd`, `world/logic/kategorie_generator/welt_generator.gd`, `world/logic/kategorie_welt/welt_definition_registry.gd` und 3 weitere |
| [`weltkarte_definition.json`](world/data/weltkarte_definition.json) | `world/data` | 4 | `_kommentar`, `regionen`, `region_kante_kacheln`, `start_biom` | `world/logic/kategorie_generator/fraktions_keimling_analysator.gd`, `world/logic/kategorie_welt/welt_makro_generator.gd` |

## 2. Pools ohne namentlichen Verbraucher

Ein Pool ohne Verbraucher ist ein Vertrag ohne Gegenstand: Entweder fehlt die verdrahtete Klasse, oder der Pool darf gehen.

| Pool | Domaene | Eintraege |
| --- | --- | --- |
| [`bindung.json`](population/data/bindung.json) | `population` | 5 |
| [`moral_regeln.json`](world/data/moral_regeln.json) | `world/data` | 5 |

## 3. Verbraucher im Einzelnen

### kern_logik.json

Pfad `core/data/kern_logik.json`, Domaene `core`, 9 Eintraege.

* `core/logic/kern_logik_basis.gd`
* `core/logic/kern_logik_registry.gd`
* `world/logic/kategorie_objekt/objekt_basis.gd`
* `world/logic/kategorie_tier/tier_manager.gd`

### kern_modifikatoren.json

Pfad `core/data/kern_modifikatoren.json`, Domaene `core`, 7 Eintraege.

* `core/logic/kern_modifikator_maschine.gd`
* `core/logic/kern_modifikator_registry.gd`

### modifikator_settings.json

Pfad `core/data/modifikator_settings.json`, Domaene `core`, 3 Eintraege.

* `core/logic/kern_modifikator_maschine.gd`

### lager.json

Pfad `economy/data/lager.json`, Domaene `economy`, 2 Eintraege.

* `economy/logic/storage/lager_registry.gd`

### animationen.json

Pfad `game/data/animationen.json`, Domaene `game/data`, 8 Eintraege.

* `game/logic/kategorie_einheit/einheit_darsteller.gd`
* `world/logic/kategorie_objekt/objekt_basis.gd`
* `world/logic/kategorie_welt/welt_objekt_darsteller.gd`

### job_config.json

Pfad `game/data/job_config.json`, Domaene `game/data`, 12 Eintraege.

* `game/logic/kategorie_job/job_basis.gd`
* `game/logic/kategorie_job/job_beeren_sammler.gd`
* `game/logic/kategorie_job/job_graben.gd`
* `game/logic/kategorie_job/job_heiler.gd`
* `game/logic/kategorie_job/job_holzfaeller.gd`
* `game/logic/kategorie_job/job_holzfaeller_stumpf.gd`
* `game/logic/kategorie_job/job_jaeger.gd`
* `game/logic/kategorie_job/job_jaeger_kadaver.gd`
* `game/logic/kategorie_job/job_registry.gd`
* `game/logic/kategorie_job/job_steinmetz.gd`
* `tools/lauf_pruefung_welt.gd`

### mutationen_inventar.json

Pfad `game/data/mutationen_inventar.json`, Domaene `game/data`, 3 Eintraege.

* `game/logic/kategorie_einheit/einheit_inventar.gd`
* `game/logic/kategorie_einheit/einheit_inventar_schema.gd`

### mutationen_ressourcen.json

Pfad `game/data/mutationen_ressourcen.json`, Domaene `game/data`, 3 Eintraege.

* `game/logic/kategorie_einheit/einheit_ressourcen_schema.gd`

### möbel.json

Pfad `game/data/möbel.json`, Domaene `game/data`, 5 Eintraege.

* `ui/logic/kategorie_ui/ui_bau_panel.gd`
* `world/logic/kategorie_welt/welt_raum_analyser.gd`

### orchestrator_config.json

Pfad `game/data/orchestrator_config.json`, Domaene `game/data`, 2 Eintraege.

* `ui/logic/kategorie_ui/ui_orchestrator_priority_panel.gd`
* `world/logic/kategorie_orchestrator/orchestrator_manager.gd`
* `world/logic/kategorie_orchestrator/orchestrator_registry.gd`
* `world/scenes/welt.gd`

### progression.json

Pfad `game/data/progression.json`, Domaene `game/data`, 2 Eintraege.

* `game/logic/kategorie_einheit/einheit_versorgungs_maschine.gd`
* `world/logic/kategorie_progression/welt_fortschritts_registry.gd`
* `world/logic/kategorie_progression/welt_progressions_registry.gd`
* `world/logic/kategorie_progression/welt_stufen_bilder.gd`

### ressourcen.json

Pfad `game/data/ressourcen.json`, Domaene `game/data`, 6 Eintraege.

* `game/logic/kategorie_einheit/einheit_inventar.gd`
* `game/logic/kategorie_einheit/einheit_ressourcen.gd`
* `game/logic/kategorie_einheit/einheit_ressourcen_schema.gd`
* `game/logic/kategorie_ressourcen/ressource_basis.gd`
* `game/logic/kategorie_ressourcen/ressource_werkzeug.gd`

### steuerung.json

Pfad `game/data/steuerung.json`, Domaene `game/data`, 8 Eintraege.

* `core/logic/kategorie_pathfinding/path_registry.gd`
* `core/logic/kern_steuerung_basis.gd`
* `core/logic/kern_steuerung_registry.gd`
* `ui/logic/kategorie_ui/ui_eingabe_steuerung.gd`
* `ui/logic/kategorie_ui/ui_kamera_steuerung.gd`
* `ui/scenes/panels/kontext_menue.gd`
* `world/scenes/karten_editor.gd`
* `world/scenes/welt.gd`

### mood_modifikatoren.json

Pfad `population/data/mood_modifikatoren.json`, Domaene `population`, 5 Eintraege.

* `game/logic/kategorie_einheit/einheit_vital_status.gd`
* `population/logic/mood/pop_mood_eskalation_stufe.gd`
* `population/logic/mood/pop_mood_modifikator_registry.gd`
* `ui/logic/kategorie_ui/ui_pop_einheit_uebersetzer.gd`

### needs.json

Pfad `population/data/needs.json`, Domaene `population`, 3 Eintraege.

* `game/logic/kategorie_einheit/einheit_manager.gd`
* `game/logic/kategorie_einheit/einheit_versorgung.gd`
* `population/logic/needs/pop_need_basis.gd`
* `population/logic/needs/pop_need_nahrung.gd`
* `population/logic/needs/pop_need_registry.gd`
* `tools/lauf_pruefung_welt.gd`
* `ui/logic/kategorie_ui/ui_eingabe_steuerung.gd`
* `world/scenes/welt.gd`

### rassen_schemata.json

Pfad `population/data/rassen_schemata.json`, Domaene `population`, 3 Eintraege.

* `population/logic/needs/pop_rassen_schema.gd`
* `population/logic/needs/pop_rassen_schema_registry.gd`
* `world/logic/kategorie_orchestrator/orchestrator_manager.gd`
* `world/logic/kategorie_welt/fraktions_ki_maschine.gd`
* `world/logic/kategorie_welt/welt_fraktions_ki_verdrahtung.gd`

### rassen_vorlagen.json

Pfad `population/data/rassen_vorlagen.json`, Domaene `population`, 6 Eintraege.

* `population/logic/needs/pop_rassen_generator.gd`

### atmosphaere.json

Pfad `world/data/atmosphaere.json`, Domaene `world/data`, 7 Eintraege.

* `world/logic/kategorie_atmosphaere/welt_atmosphaere_konfig.gd`
* `world/logic/kategorie_atmosphaere/welt_comic_overlayer.gd`

### biome.json

Pfad `world/data/biome.json`, Domaene `world/data`, 3 Eintraege.

* `world/logic/kategorie_biom/biom_basis.gd`
* `world/logic/kategorie_biom/biom_registry.gd`
* `world/logic/kategorie_generator/welt_biom_analyser.gd`
* `world/logic/kategorie_generator/welt_generator.gd`

### element_katalog.json

Pfad `world/data/element_katalog.json`, Domaene `world/data`, 32 Eintraege.

* `game/logic/kategorie_einheit/einheit_manager.gd`
* `ui/scenes/panels/kontext_menue.gd`
* `world/logic/kategorie_objekt/objekt_registry_basis.gd`
* `world/logic/kategorie_welt/welt_renderer.gd`

### fraktions_ki_config.json

Pfad `world/data/fraktions_ki_config.json`, Domaene `world/data`, 9 Eintraege.

* `world/logic/kategorie_generator/fraktions_keimling_analysator.gd`
* `world/logic/kategorie_generator/welt_generator.gd`
* `world/logic/kategorie_welt/fraktions_ki_maschine.gd`
* `world/logic/kategorie_welt/welt_erschoepfung_maschine.gd`
* `world/logic/kategorie_welt/welt_fraktions_ki_verdrahtung.gd`

### gebaeude.json

Pfad `world/data/gebaeude.json`, Domaene `world/data`, 4 Eintraege.

* `tools/lauf_pruefung_welt.gd`
* `ui/logic/kategorie_ui/ui_bau_panel.gd`
* `world/logic/kategorie_objekt/gebaeude_definition.gd`
* `world/logic/kategorie_objekt/gebaeude_definition_registry.gd`

### generator_gewichte.json

Pfad `world/data/generator_gewichte.json`, Domaene `world/data`, 9 Eintraege.

* `world/logic/kategorie_generator/generator_registry.gd`
* `world/logic/kategorie_generator/welt_feld_analyser.gd`
* `world/logic/kategorie_generator/welt_fraktions_generator.gd`
* `world/logic/kategorie_generator/welt_generator.gd`
* `world/logic/kategorie_welt/welt_fraktion.gd`

### ressourcen_progression.json

Pfad `world/data/ressourcen_progression.json`, Domaene `world/data`, 5 Eintraege.

* `world/logic/kategorie_progression/welt_progressions_registry.gd`
* `world/logic/kategorie_progression/welt_stufen_bilder.gd`

### standard_welt.json

Pfad `world/data/standard_welt.json`, Domaene `world/data`, 6 Eintraege.

* `world/scenes/karten_editor.gd`

### tier_verhalten.json

Pfad `world/data/tier_verhalten.json`, Domaene `world/data`, 5 Eintraege.

* `game/logic/kategorie_job/job_jaeger.gd`
* `world/logic/kategorie_tier/tier_baer.gd`
* `world/logic/kategorie_tier/tier_basis.gd`
* `world/logic/kategorie_tier/tier_hase.gd`
* `world/logic/kategorie_tier/tier_registry.gd`
* `world/logic/kategorie_tier/tier_vogel.gd`
* `world/logic/kategorie_tier/tier_vogelgruppe.gd`

### welt_definition.json

Pfad `world/data/welt_definition.json`, Domaene `world/data`, 7 Eintraege.

* `tools/lauf_pruefung_wasser.gd`
* `world/logic/kategorie_generator/welt_generator.gd`
* `world/logic/kategorie_welt/welt_definition_registry.gd`
* `world/logic/kategorie_welt/welt_model.gd`
* `world/logic/kategorie_welt/welt_wasser_automat.gd`
* `world/scenes/welt.gd`

### weltkarte_definition.json

Pfad `world/data/weltkarte_definition.json`, Domaene `world/data`, 4 Eintraege.

* `world/logic/kategorie_generator/fraktions_keimling_analysator.gd`
* `world/logic/kategorie_welt/welt_makro_generator.gd`

---

Version: V0.01

