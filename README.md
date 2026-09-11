<div align="center">

# ✂️ SNIPWARFARE 🪵
### *Ein Papierschnitt-Kolonie- und RTS-Spektakel aus den zynischen Augen von Shinon*

[![Godot Engine](https://img.shields.io/badge/Godot-4.7.2%20GL--Compatibility-478cbf?style=for-the-badge&logo=godotengine&logoColor=white)](https://godotengine.org)
[![Preflight Status](https://img.shields.io/badge/Preflight-100%25%20Gr%C3%BCn%20(E001--E040)-2ea44f?style=for-the-badge&logo=githubactions&logoColor=white)](#-ein-befehl-zur-wahrheit)
[![Tests](https://img.shields.io/badge/pytest-48%2F48%20Passed-brightgreen?style=for-the-badge&logo=pytest&logoColor=white)](#-ein-befehl-zur-wahrheit)
[![Architecture](https://img.shields.io/badge/Architecture-Config--Driven%20%7C%20Single--Source-orange?style=for-the-badge)](#-die-architektur-pyramide)

<br/>

<p align="center">
  <img src="world/assets/terrain/lagerfeuer.svg" width="96" alt="Lagerfeuer" />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="world/assets/ui/strichmaennchen_stehend.svg" width="64" alt="Stickman" />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="world/assets/terrain/haus.svg" width="112" alt="Haus" />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="world/assets/tiere/baer.svg" width="80" alt="Baer" />
</p>

> **"Hallo du. Ich bin Shinon. Ich halte dieses handgeschnittene Papier-Lager zusammen, solange du zuschaust. Du liest das hier nicht, weil der Godot-Debugger dich liebt. Du liest es, weil ich das Chaos mechanisch gezähmt habe, bevor es dir die Frame-Rate zerfetzt."**

</div>

---

## 🎭 Shinon bricht die vierte Wand: Worum es hier wirklich geht

Schau dir das Spiel an. Du denkst vielleicht: *„Oh, süße Strichmännchen im Papercraft-Look, ein bisschen Holz hacken, ein nettes Lagerfeuer entzünden und friedlich schlafen.“* 

**Vergiss es.** 

Hinter der Papierschichten-Ästhetik pocht ein knallharter Simulationskern. Wenn deine Siedler verhungern, weil du die Beerenbüsche ignoriert hast, schlägt der Hunger über die Mood-Maschine gnadenlos in Eskalation um. Und wenn weit und breit kein Hase flieht, schielt der hungrige Kolonist plötzlich mit sehr ungemütlichem Appetit auf seinen schlafenden Nachbarn. Jede Entscheidung hat Konsequenzen. Nichts passiert zufällig im luftleeren Raum, sondern folgt einem eisernen, unerbittlichen Takt.

---

## ⏱️ Das Herzstück: Genau eine Weltuhr (24 Hz)

Im gesamten Projekt existiert **genau eine globale Weltzeit**. Keine Domäne, kein Node und keine State Machine besitzt eine eigene geheime Uhrzeit oder heimliche `_process`-Berechnungen.

* **24 Ticks pro Sekunde:** Das Autoload `Weltuhr` (`Kern_Weltuhr`) ist der Herzschlag der gesamten Kolonie.
* **Akkumulator-Spiralenschutz:** Selbst wenn dein Rechner unter Last stöhnt, fängt das Rahmen-Budget die Ticks deterministisch ab.
* **Keine Zeitmagie:** Alle Umrechnungen (`ticks_aus_faktor`, `ticks_aus_minuten`) laufen zentral über die Uhr.

> [!NOTE]
> Wenn bei dir etwas im Spiel passiert, dann nur, weil die `Kern_Weltuhr` getickt und eine registrierte Zustandsmaschine darauf reagiert hat. Keine parallelen Geisteruhren.

---

## 🏛️ Die Architektur-Pyramide (Config-Driven & Modular)

SnipWarfare folgt einer kompromisslosen **Single-Source-of-Truth-Architektur**. Der Code ist die Wahrheit (Regel 0), und die Werte wohnen deklarativ in JSON-Datenpools.

```text
  ┌────────────────────────────────────────────────────────┐
  │       JSON-Datenpools (res://*/data/*.json)           │  ◄── Einzige Wahrheit aller Werte
  └──────────────────────────┬─────────────────────────────┘
                             │ lädt via script-Feld
  ┌──────────────────────────▼─────────────────────────────┐
  │         Registries & Datenklassen (Registry)           │  ◄── Typgeprüfte Instanziierung
  └──────────────────────────┬─────────────────────────────┘
                             │ steuert & mutiert
  ┌──────────────────────────▼─────────────────────────────┐
  │     Maschinen & Manager (24 Hz Weltuhr-Tick)          │  ◄── Keine UI, reine Fachlogik
  └──────────────────────────┬─────────────────────────────┘
                             │ schreibt Zustand
  ┌──────────────────────────▼─────────────────────────────┐
  │          Welt_Model (Autoritativer Zustand)            │  ◄── Fliesenraster & Objektlisten
  └──────────────────────────┬─────────────────────────────┘
                             │ beobachten & spiegeln
  ┌──────────────────────────▼─────────────────────────────┐
  │        Renderer, HUD, Bau-Panel & Darsteller           │  ◄── Reine Präsentationsschicht
  └────────────────────────────────────────────────────────┘
```

---

## 🎮 Steuerung & Interaktion

Die Steuerung ist vollständig menschenlesbar in [`game/data/steuerung.json`](game/data/steuerung.json) definiert und trennt Befehlserfassung von Gameplay-Logik:

| Eingabe | Aktion | Auswirkung im Spiel |
|---|---|---|
| <kbd>W</kbd> <kbd>A</kbd> <kbd>S</kbd> <kbd>D</kbd> | **Kamera bewegen** | Sanftes Verschieben des Sichtfelds über das Gelände ohne Ruckler. |
| <kbd>Linksklick</kbd> | **Einzelauswahl** | Selektiert einen Siedler oder ein Objekt; hebt vorherige Auswahl auf. |
| <kbd>Links Halten & Ziehen</kbd> | **Rechteck-Massenwahl** | Wählt alle Kolonisten im gezogenen Rahmen (General-Modus). |
| <kbd>Rechtsklick</kbd> *(auf Ziel)* | **Direktbefehl** | Startet sofort Holzfällen, Steinmetzen, Jagen oder Marschieren. |
| <kbd>Rechtsklick</kbd> *(auf Boden)* | **Kontextmenü** | Öffnet zielgefilterte Aktionen mit Tooltip & Werkzeuganforderung. |
| <kbd>F3</kbd> | **Debug-Overlay** | Schaltet System- und Tier-Statistiken ein/aus. |

---

## 📦 Das Ressourcen- & Produktionsnetz

Jede Ressource besitzt ihr eigenes SVG-Asset und eine dedizierte Datenklasse. Das HUD liest Bestände atomar aus dem Lager:

<div align="center">

| Holz | Stein | Fleisch | Beeren | Räucherfleisch | Werkzeug |
|:---:|:---:|:---:|:---:|:---:|:---:|
| <img src="world/assets/ui/ressource_holz.svg" width="48" /> | <img src="world/assets/ui/ressource_stein.svg" width="48" /> | <img src="world/assets/ui/ressource_fleisch.svg" width="48" /> | <img src="world/assets/ui/ressource_beeren.svg" width="48" /> | <img src="world/assets/ui/ressource_raeuchelfleisch.svg" width="48" /> | <img src="world/assets/ui/ressource_werkzeug.svg" width="48" /> |
| `Holz` | `Stein` | `Fleisch` | `Beeren` | `Räucherfleisch` | `Werkzeug` |

</div>

> [!TIP]
> Die Produktionskette folgt dem echten Bedarf: Die **Werkstatt** schmiedet Werkzeuge zur Halbierung der Erntezeit, während die **Räucherei** rohes Fleisch vor dem Verderb schützt.

---

## 🗺️ Aktueller Projektstand & Master-Roadmap

Der aktuelle **Stand** umfasst ein stabiles Fundament mit 162 Klassen, 8 Szenen, funktionierender A*-Wegplanung, multi-map-fähiger World-Expansion und 48 bestandenen Pytest-Prüfungen.

Unsere konsolidierte **Vision** orientiert sich an der Tiefe von Koloniesimulatoren wie *RimWorld*:

* [x] **Phase 0 (Kern):** 24-Hz-Weltuhr, deterministischer RNG, Signalbus, Multi-Map-Savegames, A*-Pfadfinder.
* [x] **Phase P1 (Progression):** Datengetriebene Einstiegskette: *Lagerfeuer setzen* ➔ *Erstes Haus* ➔ *Einwanderung*.
* [ ] **Slice 1 (Aufräumen & Gating):** Entkoppeltes Bau-Panel, Ziel-Tags im Katalog, saubere Statusleisten.
* [ ] **Slice 2 (Maßstab & Terrain):** 64px-Micro-Tiles, Terrain-Pool (`terrain.json`), Varianten-Blatt & Y-Sort-Tiefensortierung.
* [ ] **Slice 3 (Landschaft):** Deterministische Fluss- & Felsmassive-Generatoren, Erzadern, Ruinen & dichte Wälder.
* [ ] **Slice 4 (Weltkarte):** Makrokarte mit Fraktionsnetzwerk, minimaler Startbereich & sichtbare Landeplatzmarkierung.
* [ ] **Slice 5 (Bauen & Logistik):** Blueprint-Planung, Materialtransport (`Job_BaustelleBeliefern`) vor Baubeginn.
* [ ] **Slice 6 (Auswahl & Autonomie):** Goldener Stern für aktive Einheit, Queue-Abbruch bei Direktklick & Idle-Autonomie.
* [ ] **Slice 7 (UI & Rahmung):** Feste HUD-Leisten, Blueprint-Ghost-Vorschau und ereignisgesteuerte Signal-Updates.
* [ ] **Slice 8 (Eskalation & Moral):** Verzweigte Mood-Ketten in der Timeline, Spielergrundsätze (`Pop_MoralInstanz`) & Trait *"Mag kein Papier"*.
* [ ] **Slice 9 (Ökonomie & Erze):** Schmelze, Schmiede, Barren und stufenweiser Erzabbau.

*(Die vollständige Checkpoint-Aufschlüsselung findest du in der [`ROADMAP.md`](ROADMAP.md).)*

---

## 🛡️ Ein Befehl zur Wahrheit: Der Preflight

Bevor irgendein Commit die Ziellinie überquert, muss er durch mein mechanisches Schafott:

```bash
python tools/preflight.py
```

```text
==============================================================================
PREFLIGHT OK: 16 Prüfkategorien grün (0 Befunde)
- Godot Headless Kompilierung & Warnungs-Scan (E016–E018, E025)
- Naming & Ordner-Kategorie-Präfixe (E001–E004, E021)
- Determinismus & Zufalls-Prüfung (E012–E014)
- Datenparität & Single Source of Truth (E040)
- Shinon Commit Gate (E030–E039)
==============================================================================
```

> [!IMPORTANT]
> **Shinon Gate Pflicht (Regel 5):** Commits werden nicht nach Lust und Laune geschrieben. Jede Nachricht entsteht in nummerierten Sätzen, bildlicher Sprache und ohne dekorative Banner. Wer schlampt, fängt sich einen Fehlercode ein.

---

<div align="center">

**SnipWarfare** — *Gebaut nach den Regeln der Projektverfassung [`AGENTS.md`](AGENTS.md).*  
*Stand: September 2026 • Gepflegt von Shinon*

</div>
