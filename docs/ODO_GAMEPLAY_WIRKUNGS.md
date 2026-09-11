# ODO — Spielbare Wirkungskette

## ACT-01 — Rechtsklick öffnet Kontextmenü und löst konkrete Spielaktion aus

**BETROFFEN**
- `ui/logic/kategorie_ui/ui_eingabe_steuerung.gd`
- `ui/scenes/panels/kontext_menue.gd`
- `world/scenes/welt.gd`
- `world/scenes/welt.tscn`
- `game/data/steuerung.json`
- `Welt_FeedbackManager`
- `Gebaeude_Manager`
- `Einheit_Manager`

**BEFUND**
- Rechtsklick öffnet `PopupMenu`.
- Menü meldet nur `aktion_gewaehlt`.
- `_auf_kontext_aktion` in `welt.gd` leitet an `ui_eingabe_steuerung.auf_kontext_aktion` weiter.
- Das MenüKenntnis endet nach der Wahl ohne jeden anderen weltlichen Schritt, der den Spieler direkt wieder in die Welt führt.

**REFERENZ**
- `ui/scenes/welt.tscn` → Node `KontextMenue`
- `world/scenes/welt.gd` Zeile ~115 und ~239
- `ui/logic/kategorie_ui/ui_eingabe_steuerung.gd` Zeilen 219 ff. und 241 ff.

**ERWARTET**
- Spieler wählt `Sammeln`, `Abbauen`, `Bauen`, `Expansion` oder `Wachstum`.
- Die Wahl führt sofort zu einer sichtbaren Weltreaktion oder einer klaren Meldung, warum die Aktion nicht ausführbar ist.

**GODOT-UMSETZUNG**
- `PopupMenu.id_pressed` → `aktion_gewaehlt` → Spielaktion → `Gebaeude_Manager.bauen_anfordern` / `_stockmaenner.job_vergeben` / `_map_fabrik` / `_lager` / `_ressourcen`.
- Sichtbar: `Gebaeude_Manager.gebaude_meldung`, `Welt_FeedbackManager`, HUD-Änderungen.

**KONKRETE ÄNDERUNG**
- `world/scenes/welt.gd`
- `ui/logic/kategorie_ui/ui_eingabe_steuerung.gd`
- ggf. `Gebaeude_Manager`, `Einheit_Manager`, `Welt_MapFabrik`

**ABHÄNGIGKEITEN**
- `game/data/steuerung.json`
- `Welt_Ladevorgang`
- `WeltSitzung`
- `Einheit_Ressourcen`
- `Lager_Manager`

**RISIKO**
- Kontextmenü-Aktionen bereits teilweise vorhanden; Verstärkung darf alte Abläufe nicht umgehen.

**ABNAHME**
- Rechtsklick → Menü → Wahl → sichtbare Konsequenz oder klares Warum-auf-HUD.

---

## ACT-02 — Gebäudebau zeigt nicht nur Meldung, sondern auch Baustart im Spiel

**BETROFFEN**
- `world/logic/kategorie_objekt/gebaeude_manager.gd`
- `world/scenes/welt.gd`
- `world/scenes/welt.tscn`
- `Welt_Renderer`
- `Einheit_Ressourcen`

**BEFUND**
- `gebaeude_meldung` kommt über `welt.gd._auf_gebaeude_meldung` an das HUD.
- Das Gotteswerk `Bau angefordert` existiert.
- Was danach im Spiel passiert, ist nicht vollständig: Sobald der Spieler gebaut hat, muss die Spielewelt den Baustart und später den Produktionsstart zeigen, nicht nur den Text.

**REFERENZ**
- `world/logic/kategorie_objekt/gebaeude_manager.gd`
- `world/scenes/welt.gd` Zeile ~106 ff. und ~256

**ERWARTET**
- Nach Baugenehmigung erscheint im Spiel ein Gebäude-Objekt in Ausbauphase.
- HUD oder Welt zeigen Baufortlauf oder Produktionsstart.

**GODOT-UMSETZUNG**
- `Gebaeude_Manager` → `model.objekt_hinzufuegen` + Zustandsfelder im Modell.
- `Welt_Renderer.darstellen` / `objekt_knoten_anhaengen` → sichtbarer Knoten.
- HUD: `produktion_anzeigen` oder eigener Baustart-Indikator.

**KONKRETE ÄNDERUNG**
- `Gebaeude_Manager`
- `Welt_Renderer` oder `Welt_ObjektDarsteller`
- HUD-Treiber in `welt.gd`

**ABHÄNGIGKEITEN**
- `Welt_Model`
- `Welt_Registry`
- `Einheit_Ressourcen`
- `Lager_Manager`

**RISIKO**
- Bau-Fortschritt ohne Darstellung ist nur Text.

**ABNAHME**
- Spieler baut → sieht erst Baustart, dann Produktionsstart.

---

## ACT-03 — Ernte und Beute führen zu sichtbarem +', Tod zu sichtbarem ✝

**BETROFFEN**
- `game/logic/kategorie_einheit/einheit_ernte_maschine.gd`
- `world/logic/kategorie_feedback/feedback_manager.gd`
- `world/logic/kategorie_feedback/feedback_plus_anzeige.gd`
- `world/logic/kategorie_feedback/feedback_tod_anzeige.gd`
- `world/scenes/welt.gd`
- `Kern_SignalBus`

**BEFUND**
- Ernte wird intern gebucht: `hinzufuegen`.
- Beute wird intern gebucht.
- Der Spieler sieht nicht automatisch `+Holz`, `+Fleisch` oder `✝ Tier`.
- Der Kreislauf fehlt teilweise: Ernte/Beute erzwingen kein sichtbares Feedback.

**REFERENZ**
- `einheit_ernte_maschine.gd`
- `feedback_manager.gd`
- `feedback_plus_anzeige.gd`
- `feedback_tod_anzeige.gd`
- `kern_signal_bus.gd`
- `welt.gd` Zeile ~45 und ~80

**ERWARTET**
- Jede Ernte zeigt `+Resource` am Objekt.
- Jeder getötete Tier zeigt `✝ Tier` oder ähnlich.
- Schaden zeigt rote Zahl.

**GODOT-UMSETZUNG**
- `Einheit_ErnteMaschine` → `Welt_FeedbackManager.zeige_ernte`.
- `Tier_Status` Tod → `Kern_SignalBus._emit_gestorben` → `Welt_FeedbackManager.zeige_tod`.
- `Einheit_VitalStatus` Schaden → `Kern_SignalBus._emit_schaden` → `Welt_FeedbackManager.zeige_schaden`.

**KONKRETE ÄNDERUNG**
- `einheit_ernte_maschine.gd`
- `feedback_manager.gd`
- `einheit_vital_status.gd`
- `tier_status.gd`
- ggf. `einheit_status.gd`

**ABHÄNGIGKEITEN**
- `Kern_SignalBus`
- `Einheit_Ressourcen`
- `Tier_Manager`
- `Welt_Model`

**RISIKO**
- Feedback ohne Spielmechanik ist Platitiv.

**ABNAHME**
- Spieler sieht bei jeder Ernte und jedem Tier-/EINHEIT-Tod die entsprechende Anzeige.

---

## ACT-04 — Spieler sieht nicht nur HUD-Text, sondern auch Weltzoom und Kamerabewegung bei Ingame-Aktionen

**BETROFFEN**
- `ui/logic/kategorie_ui/ui_kamera_steuerung.gd`
- `world/scenes/welt.gd`
- `ui/scenes/welt.tscn`

**BEFUND**
- Kamera bewegt sich über WASD.
- Welche Aktionen die Kamera auf Spieleraktionen reagieren lassen, ist nicht vollständig spezifiziert.

**REFERENZ**
- `ui/logic/kategorie_ui/ui_kamera_steuerung.gd`
- `world/scenes/welt.gd`
- `world/scenes/welt.tscn`

**ERWARTET**
- Einige Aktionen können Kamerabewegung auslösen, zB Liste, Buildtarget, Auswahl.

**GODOT-UMSETZUNG**
- `Ui_KameraSteuerung` + `Camera2D` im Spiel.
- Verbindung über `welt.gd` für bestimmte Spielereignisse.

**KONKRETE ÄNDERUNG**
- `ui/logic/kategorie_ui/ui_kamera_steuerung.gd`
- `world/scenes/welt.gd`

**ABHÄNGIGKEITEN**
- `Kern_SteuerungRegistry`
- `Welt_Model`

**RISIKO**
- Kamerareaktion ausschließlich über WASD.

**ABNAHME**
- Spieleraktionen können Kamerabewegung auslösen können.

---

## ACT-05 — Welt-Generator-Vislualisierung nach Kartenwechsel oder Expansion

**BETROFFEN**
- `world/logic/kategorie_generator/welt_generator.gd`
- `world/scenes/welt.gd`
- `world/scenes/welt.tscn`
- `Welt_Renderer`
- `Welt_MapFabrik`
- `Welt_Ladevorgang`

**BEFUND**
- Generator erzeugt Karte.
- Szene muss nach dem Laden oder der Expansion die neue Karte sichtbar machen.

**REFERENZ**
- `welt_generator.gd`
- `welt.gd` Zeilen 62 ff., 78, 184, 189
- `Welt_MapFabrik`
- `Welt_Ladevorgang`

**ERWARTET**
- Nach neue Karte oder Expansion erscheint die Karte im Spiel.

**GODOT-UMSETZUNG**
- `Welt_Renderer.darstellen` nach `Welt_Ladevorgang` oder `Expansion`.
- Modellwechsel im `welt.gd` mit `model_liefern`.

**KONKRETE ÄNDERUNG**
- `world/scenes/welt.gd`
- `Welt_Ladevorgang`
- `Welt_MapFabrik`

**ABHÄNGIGKEITEN**
- `WeltSitzung`
- `Welt_Model`
- `Welt_Registry`
- `Welt_Renderer`

**RISIKO**
- Neue Karte ohne sichtbaren Wechsel.

**ABNAHME**
- Nach Laden oder Expansion sieht Spieler die neue Karte.

---

## ACT-06 — Spieler kann Spielerfiguren-Bewegung sehen

**BETROFFEN**
- `game/logic/kategorie_einheit/einheit_status.gd`
- `game/logic/kategorie_einheit/einheit_manager.gd`
- `game/logic/kategorie_einheit/einheit_darsteller.gd`
- `world/scenes/welt.gd`
- `Welt_Renderer`

**BEFUND**
- Zustandsmaschine berechnet Bewegung.
- Ob Spieler die Bewegung sieht oder ob Nodes wirklich verschoben werden, ist unvollständig.

**REFERENZ**
- `einheit_status.gd`
- `einheit_manager.gd`
- `einheit_darsteller.gd`
- `welt.gd` Zeilen ~106 ff.

**ERWARTET**
- Spieler sieht Bewegung der Spielerfiguren.

**GODOT-UMSETZUNG**
- `Einheit_Status.tick` → Position → `Einheit_Darsteller.position` + Animation.
- Verknüpfung im `welt.gd` zwischen Status und Node.

**KONKRETE ÄNDERUNG**
- `einheit_status.gd`
- `einheit_darsteller.gd`
- `einheit_manager.gd`

**ABHÄNGIGKEITEN**
- `Welt_Model`
- `Einheit_WegPlanung`
- `Einheit_ZielSuche`
- `Kern_ModifikatorMaschine`

**RISIKO**
- Bewegung nur als State.

**ABNAHME**
- Spieler sieht die Figuren bewegen.

---

## ACT-07 — Spieler sieht Tierreaktion auf Spieler

**BETROFFEN**
- `world/logic/kategorie_tier/tier_status.gd`
- `world/logic/kategorie_tier/tier_manager.gd`
- `world/logic/kategorie_tier/tier_darsteller.gd`
- `world/scenes/welt.gd`

**BEFUND**
- Tier reagiert auf Spieler.
- Darstellung ist teilweise vorhanden, aber nicht abschließend geprüft, ob Spieler Tierbewegung sieht.

**REFERENZ**
- `tier_status.gd`
- `tier_manager.gd`
- `tier_darsteller.gd`
- `welt.gd`

**ERWARTET**
- Spieler sieht Tierflucht/Verfolgung.

**GODOT-UMSETZUNG**
- `Tier_Status.tick` → `Tier_Darsteller.position` + Animation.
- `Tier_Manager` → Nodes.

**KONKRETE ÄNDERUNG**
- `tier_status.gd`
- `tier_darsteller.gd`
- `tier_manager.gd`

**ABHÄNGIGKEITEN**
- `Tier_Registry`
- `Kern_Weltuhr`

**RISIKO**
- Tierbewegung nur intern.

**ABNAHME**
- Spieler sieht Tierreaktion auf Spieler.

---

## ACT-08 — Spieler sieht Produktionsfortschritt in Gebäude und HUD

**BETROFFEN**
- `world/logic/kategorie_objekt/gebaeude_produktions_maschine.gd`
- `world/scenes/welt.gd`
- `ui/scenes/hud/hud_produktion_anzeige.gd`

**BEFUND**
- Produktionsmaschine läuft intern.
- Fortschritt muss im HUD oder Gebäude sichtbar werden.

**REFERENZ**
- `gebaeude_produktions_maschine.gd`
- `welt.gd`
- `hud_produktion_anzeige.gd`
- `gebaeude_manager.gd`

**ERWARTET**
- Spieler sieht Produktionsfortschritt.

**GODOT-UMSETZUNG**
- `Gebaeude_Manager.status_zeilen` → HUD.
- Gebäude-Objekt im Renderer oder HUD-Fortlauf.

**KONKRETE ÄNDERUNG**
- `gebaeude_manager.gd`
- `hud_produktion_anzeige.gd`
- `welt.gd`

**ABHÄNGIGKEITEN**
- `Gebaeude_ProduktionsMaschine`
- `Einheit_Ressourcen`
- `Lager_Manager`

**RISIKO**
- Produktionsfortschritt nur im Zustand.

**ABNAHME**
- Spieler sieht Produktionsfortschritt.

---

## ACT-09 — Spieler sieht Einsatzende der Einheiten durch Gebäude

**BETROFFEN**
- `world/logic/kategorie_objekt/gebaeude_manager.gd`
- `game/logic/kategorie_einheit/einheit_ernte_maschine.gd`
- `world/scenes/welt.gd`
- `Welt_FeedbackManager`

**BEFUND**
- Gebäude produziert intern.
- Das Gebäude muss dem Spieler das Ende der Einheit zeigen.

**REFERENZ**
- `gebaeude_manager.gd`
- `einheit_ernte_maschine.gd`
- `welt.gd`
- `feedback_manager.gd`

**ERWARTET**
- Gebäude produziert Spieler sieht Ergebnis oder Meldung.

**GODOT-UMSETZUNG**
- `Gebaeude_Manager._outputs_einlagern` → `Welt_FeedbackManager` sowie HUD.

**KONKRETE ÄNDERUNG**
- `gebaeude_manager.gd`
- `feedback_manager.gd`
- `welt.gd`

**ABHÄNGIGKEITEN**
- `Gebaeude_ProduktionsMaschine`
- `Einheit_Ressourcen`
- `Lager_Manager`
- `Kern_SignalBus`

**RISIKO**
- Gebäude produziert nur im Hintergrund.

**ABNAHME**
- Spieler sieht Gebäude-Ergebnis.

---

## ACT-10 — Spieler sieht Spielstand bei Weltwechsel, Laden oder Expansion

**BETROFFEN**
- `world/logic/kategorie_welt/welt_ladevorgang.gd`
- `world/logic/kategorie_welt/welt_world.gd`
- `world/logic/kategorie_welt/welt_speicher.gd`
- `world/scenes/welt.gd`
- `ui/scenes/welt.tscn`
- `WeltSitzung`

**BEFUND**
- Laden/Expansion/Switch existiert.
- Der Spieler muss nach Weltwechsel den neuen Spielstand sehen.

**REFERENZ**
- `welt_ladevorgang.gd`
- `welt_world.gd`
- `welt_speicher.gd`
- `welt.gd`
- `WeltSitzung`

**ERWARTET**
- Nach Laden/Expansion/Switch sieht Spieler den neuen Spielstand.

**GODOT-UMSETZUNG**
- `Welt_Ladevorgang.ausfuehren` → `welt.gd` über `WeltSitzung`.
- `Welt_Renderer.darstellen` nach Modellwechsel.

**KONKRETE ÄNDERUNG**
- `welt_ladevorgang.gd`
- `welt_world.gd`
- `welt_speicher.gd`
- `welt.gd`

**ABHÄNGIGKEITEN**
- `Welt_Model`
- `Welt_Registry`
- `Welt_Renderer`
- `WeltSitzung`
- `Gebaeude_Manager`
- `Einheit_Manager`
- `Tier_Manager`
- `Lager_Manager`
- `Einheit_Ressourcen`
- `Welt_FeedbackManager`

**RISIKO**
- Weltwechsel ohne sichtbaren Spielstand.

**ABNAHME**
- Spieler sieht nach Laden/Expansion den neuen Spielstand.

---

# WIRKUNGS-ODO — Spielfluss

## WIRKUNGS-ODO-01 — Rechtsklick

Rechtsklick
↓
PopupMenu öffnen
↓
id_pressed → aktion_gewaehlt
↓
welt.gd._auf_kontext_aktion
↓
ui_eingabe_steuerung.auf_kontext_aktion
↓
Gebaeude_Manager.bauen_anfordern / _stockmaenner.job_vergeben / _map_fabrik / _lager / _ressourcen
↓
model.objekt_hinzufuegen / job_vergeben / lager / ressourcen
↓
welt_Reaktion / HUD-Meldung / FeedbackManager
↓
Spieler sieht Aktion oder Warum

**LOCH:** nur Meldung oder Weltreaktion statt beides.

---

## WIRKUNGS-ODO-02 — Ernte und Beute

Arbeitsschritt fertig
↓
einheit_ernte_maschine.arbeitsschritt_verarbeiten
↓
ressourcen.hinzufuegen / tier_ernten
↓
feedback_manager.zeige_ernte / feedback_manager.zeige_tod
↓
sichtbare Anzeige am Objekt
↓
Spieler sieht +Resource oder ✝ Tier

**LOCH:** Ernte/Beute ohne Feedback.

---

## WIRKUNGS-ODO-03 — Gebäudebau

Spieler wählt Bau
↓
gebaeude_manager.bauen_anfordern
↓
modell.objekt_hinzufuegen + bau_phase / bau_fortschritt
↓
welt_Renderer oder HUD zeigt Baustart
↓
Gebaeude_Manager tickt Bau/Produktion
↓
HUD oder Gebäude zeigt Fortschritt
↓
Spieler sieht Bau und Produktion

**LOCH:** Baustart oder Fortschritt sichtbar.

---

## WIRKUNGS-ODO-04 — Gebäude-Produktion

Gebaeude tickt Produktion
↓
Gebaeude_ProduktionsMaschine.laeuft / wartet / abgeschlossen
↓
Gebaeude_Manager._inputs_entnehmen / _outputs_einlagern
↓
Welt_FeedbackManager / HUD
↓
Spieler sieht Ergebnis

**LOCH:** Gebäude produziert ohne Ergebnis-Anzeige.

---

## WIRKUNGS-ODO-05 — Tier und Einheit Tod

Tier/ Einheit HP ≤ 0
↓
tier_status / einheit_vital_status → tod
↓
Kern_SignalBus._emit_gestorben
↓
feedback_manager.zeige_tod
↓
sichtbare Anzeige
↓
Spieler sieht Tod

**LOCH:** Tod ohne Anzeige oder nur intern.

---

## WIRKUNGS-ODO-06 — Weltwechsel/Laden/Expansion

Spieler startet Laden/Expansion/Switch
↓
WeltSitzung.neue Welt
↓
Welt_Ladevorgang.ausfuehren / Welt_MapFabrik.neue_karte_erzeugen
↓
Welt_Model + Welt_Renderer
↓
welt_Renderer.darstellen
↓
Spieler sieht neue Karte

**LOCH:** Neue Karte ohne sichtbaren Wechsel.

---

# BEFUND

## BRUTALBEFUND

- Rechtsklick → Kontextmenü → keine folgende Spielaktion in der Kette.
- Ernte und Beute werden intern gebucht, aber Spieler sieht keine sichtbare Anzeige.
- Gebäudebau und Produktion laufen teilweise im Hintergrund, nicht vollständig sichtbar.
- Weltwechsel/Laden/Expansion muss Spielerstand zeigen.

## ALGORITHMUS-DEFEKTE

- Ernte/Beute ohne Feedback.
- Gebäude-Start/Fortschritt ohne sichtbaren Zustand.
- Rechtsklick-Aktionen nur teilweise.

## MISSING SYSTEMS

- Feedback-Manager-Erweiterung für Ernte/Beute/Tod.
- Sichtbarer Gebäude-Start/Fortschritt.
- Vollständige Kontextmenü-Aktionskette.

## UNSICHTBARE AKTIONEN

- Ernte
- Beute
- Gebäudebau
- Gebäude-Produktion
- Rechtsklick-Aktionen
- Weltwechsel/Laden/Expansion

## DESYNCS

- Ernte/Beute-State vs. sichtbare Anzeige.
- Gebäude-State vs. sichtbare Darstellung.
- Rechtsklick-Aktion vs. Weltreaktion.
- Weltwechsel vs. sichtbarer Spielstand.

## GAMEPLAY-WIRKUNGS-ODO

1. ACT-01 — Rechtsklick → Spielaktion
2. ACT-03 — Ernte/Beute → Feedback
3. ACT-02 — Gebäudebau → sichtbarer Start/Fortschritt
4. ACT-04 — Gebäude-Produktion → sichtbares Ergebnis
5. ACT-08 — Tier/EINHEIT-Tod → sichtbare Anzeige
6. ACT-05 — Weltwechsel/Laden/Expansion → sichtbarer Spielstand
