# Papercraft-Stil-Guide

Dieser Ordner enthält die modularen SVG-Assets der Prototyp-Karte im Papierschnitt-Stil. Alle Assets sind frei platzierbar und folgen denselben Stilregeln.

> Die verbindliche Projektarchitektur mit Kategorien, Daten-/Logik-Trennung und Preflight-Regeln steht in der [Architektur.md](../../Architektur.md); sie ist Pflichtdokumentation und wird aktiv gepflegt.

## Dateien

| Datei | Beschreibung |
| --- | --- |
| `terrain/boden_kachel.svg` | Boden-Kachel 512x512 mit eingerissenem Papier-Rand, Lichtflecken, Löchern, Grasbüscheln und Papier-Kieselsteinen |
| `terrain/wiese_kachel.svg` | Wiesenvariante mit dichterem Gras und Papierblüten |
| `terrain/baum.svg` | Baum 128x160, Krone aus drei gestapelten Papierschichten |
| `terrain/baum_stumpf.svg` | Baumstumpf 96x88 mit Jahresringen auf der Anschnitt-Fläche |
| `terrain/stein.svg` | Einzelner Stein 96x88 aus drei gestapelten Papierschichten |
| `terrain/steine_gruppe.svg` | Steingruppe 160x104 aus großem Stein, kleinem Stein und Splitter |
| `terrain/haus.svg` | Haus 160x144 mit Satteldach, Tür, Fenster, Schornstein und Papier-Rauch |
| `terrain/haus_gross.svg` | Großes Haus 208x160 mit zwei Fenstern und Bogen-Tür |
| `terrain/werkstatt.svg` | Werkstatt 160x144 als Papier-Pultdach-Halle mit Tor, Fenster, Schornstein, Stamm und Werkzeugplan |
| `terrain/werkstatt_grind.svg` | Werkstatt-Funktions-Animation "grind", 4 Frames à 160x144; Frame 1 ist das Standbild, der Werkzeugplan schlägt und Papierstaub fällt (nur Bewegungsformen tragen opacity) |
| `terrain/raeucherei.svg` | Räucherei 160x144 als Holzzylinder auf Steinsockel mit Tür, Schlitz, Hakenzeichen und eigenem Schornstein |
| `terrain/raeucherei_rauch.svg` | Räucherei-Funktions-Animation "raeuchern", 4 Frames à 160x144; Rauchstöße in der Papierwolken-Sprache aus haus.svg |
| `terrain/lagerfeuer.svg` | Lagerfeuer 128x128 mit drei Papier-Scheiten und dreischichtiger Papierflamme |
| `terrain/lagerfeuer_flackern.svg` | Lagerfeuer-Funktions-Animation "flackern", 4 Frames à 128x128; Flamme neigt, streckt und legt sich, Scheite und Schatten stehen still |
| `terrain/busch.svg` | Busch 96x88 aus drei Papierschichten mit Bodenschatten und ausgeschnittenem Blatt |
| `terrain/busch_wehen.svg` | Busch-Funktions-Animation "wehen", 4 Frames à 96x88; Kronenschichten wiegen sich wie im Wind, Erdpunkt bleibt fixiert |
| `ui/laeufer_rechts.svg` | Strichmännchen-Gangzyklus, 4 Frames à 48x64 auf 192x64, Laufrichtung rechts |
| `ui/laeufer_links.svg` | Gleicher Gangzyklus gespiegelt, Laufrichtung links |
| `ui/idle_rechts.svg` | Idle-Animation, 4 Frames à 48x64, Atmung und Wiegen; Füße bleiben an derselben Stelle |
| `ui/idle_links.svg` | Gespiegelte Idle-Variante |
| `ui/hacken_rechts.svg` | Holzhack-Zyklus mit Papier-Axt, 4 Frames à 64x64 auf 256x64; Füße fest, Splitter beim Treffer |
| `ui/hacken_links.svg` | Gespiegelte Hack-Variante |
| `ui/ressource_holz.svg` | Ressourcen-Icon Holz: zwei gestapelte Papierstämme mit heller Schnittfläche |
| `ui/ressource_stein.svg` | Ressourcen-Icon Stein: gestapelte Papierschichten |
| `ui/ressource_fleisch.svg` | Ressourcen-Icon Fleisch: Schinkenkeule mit Papierknochen |
| `ui/strichmaennchen_stehend.svg` | Stehendes Strichmännchen 48x64, Spielermarker und Cursor |
| `tiere/baer.svg` | Bär, 4 Frames à 48x72 auf 192x72, Watschel-Gang |
| `tiere/hase.svg` | Hase, 4 Frames à 32x72 auf 128x72, Flucht-Hoppeln |
| `tiere/vogel.svg` | Vogel, 4 Frames à 32x64 auf 128x64, Flügelschlag |
| `tiere/vogelgruppe.svg` | Vogelgruppe, 4 Frames à 48x64 auf 192x64, Keilformation |
| `vorschau.html` | Generierte Vorschau-Seite mit allen Assets inklusive Funktions-Animationen |
| `vorschau_erzeugen.py` | Generator-Skript für die Vorschau-Seite |

## Stilregeln

1. **Papierschichten:** Jedes Objekt besteht aus zwei bis vier flachen Farbschichten. Die unterste Schicht ist die dunkelste und schaut unten links hervor; nach oben links werden die Schichten heller (Lichtquelle oben links).
2. **Schlagschatten:** Jeder Schatten besteht aus zwei flachen Ellipsen ohne Weichzeichnung: eine dunklere Ellipse versetzt nach unten links, eine hellere darüber, leicht nach oben rechts versetzt. Der Versatz beträgt etwa zwei bis drei Prozent der Bildbreite. Kein SVG-Filter, damit die SVG-Dateien auch in Godot sauber als Texturen importiert werden können.
3. **Schnittkanten:** Wo ein Blatt Papier „geschnitten" ist, liegt ein heller Saum (helles Grün, helles Grau, helles Holz) als Strich entlang der Kante.
4. **Flächen:** Nur flache Volltonfarben, keine Verläufe. Details wie Risse, Jahresringe und Blüten werden als flache, kleinere Formen darüber gelegt.
5. **Freistehende Objekte** (Baum, Baumstumpf, Stein, Steingruppe) tragen einen Bodenschatten-Ellipsenpaar in den Grasfarben der Karte, damit sie auf jeder Unterlage liegen.
6. **Kacheln** decken das volle Quadrat ab: ein vollflächiger Hintergrund als unterste Papierebene plus eine obere Papierebene mit eingerissenem Rand; an den Kachelgrenzen stößt die dunkle unterste Ebene sichtbar an und betont den Papier-Layer-Look.

## Farbpalette (Terrain, Grün)

| Zweck | Farbe |
| --- | --- |
| Unterste Bodenschicht | `#8FAB58` |
| Obere Bodenschicht | `#A3BE6B` |
| Helle Papierschnipsel | `#B7CE7E` |
| Risse und Löcher | `#7A9549` |
| Grasbüschel Boden | `#6F8A42` |
| Grasbüschel Wiese | `#5E7A36` |
| Krone unten | `#4E7434` |
| Krone Mitte | `#5E8A3E` |
| Krone oben | `#7AA84E` |
| Schnittkante Krone | `#94C464` |
| Blütenblatt | `#FBF6E8` |
| Blütenkern | `#E8B84B` |
| Schattenflächen freistehender Objekte | `#7A9549` / `#8FAB58` |

## Farbpalette (Holz und Stein)

| Zweck | Farbe |
| --- | --- |
| Holz dunkel (Mantel) | `#6D4A31` |
| Holz hell (Lichtseite) | `#8A6240` |
| Anschnitt-Fläche | `#C89B6C` |
| Anschnitt-Fläche hell | `#D9B183` |
| Jahresringe | `#A87F52` |
| Erdklumpen dunkel | `#7A5A3A` |
| Erdklumpen hell | `#946F48` |
| Stein dunkel (Fundament) | `#6E675D` |
| Stein Mittelton | `#8B8478` / `#9A9287` |
| Stein hell (Deckel) | `#CFC9BE` |
| Stein Lichtkante | `#B5AEA1` |

## Farbpalette (Dach und Strichmännchen)

| Zweck | Farbe |
| --- | --- |
| Dach dunkel (Unterschicht) | `#A0522D` |
| Dach Hauptfläche | `#B8663A` |
| Dach hell (Deckfläche) | `#C97B4A` |
| Dach First-Kante | `#E0995C` |
| Strichmännchen Linien | `#4A4237` |
| Strichmännchen Kopf | `#FBF6E8` |
| Schal | `#C75B39` |
| Tierfell dunkel | `#6D4A31` / `#8A6240` |
| Tierfell hell | `#A87F52` / `#C89B6C` |
| Hase hell | `#B5AEA1` / `#CFC9BE` |
| Schnabel/Blütenkern | `#E8B84B` |
| Axtstiel | `#8B5A2B` |
| Axtblatt | `#C9C2B4` |
| Holz-Icon Stämme | `#8B5A2B` / `#A5713C` / `#E8D9A8` |
| Stein-Icon | `#B9B2A2` / `#C4BCAA` / `#D8D2C2` / `#DDD6C6` |
| Fleisch-Icon | `#C75B39` / `#E0876A` / `#FBF6E8` |

## Funktions-Animationen der Weltobjekte (Registry)

Weltobjekte können eine Funktions-Animation tragen. Der Name steht im Element-Katalog (`world/data/element_katalog.json`, Feld `funktions_animation`) und zeigt auf einen Eintrag in der zentralen Animations-Registry `game/data/animationen.json`; dort liegen Sheet-Pfad, Frame-Größe, Frame-Anzahl und `ticks_pro_frame`. Optional drosselt `funktions_takt_faktor` den Animationstakt je Objekt (0.4 bedeutet: die Flamme flackert langsamer als der Registry-Standard).

Die Kette ist fest: Katalog-Eintrag -> `Objekt_Basis` liest `funktions_animation` -> `Welt_Renderer` erzeugt für das Standbild den ersten Frame des Sheets -> `Welt_ObjektDarsteller` (`world/logic/kategorie_welt/welt_objekt_darsteller.gd`) schneidet alle Frames aus `sheet_pfad` und spielt sie mit 24 geteilt durch `ticks_pro_frame` Animationsschritten pro Sekunde ab, gekoppelt an die 24 Ticks der Weltuhr. Ein Objekt ohne Registry-Eintrag wird nie animiert; es gibt keine versteckte Aktivierung.

Regeln für Funktions-Animationen: Frame 1 ist immer exakt das Standbild, damit Editor, Vorschau und Karte dasselbe Bild zeigen. Bewegung entsteht nur durch Formen, die zusätzlich gezeichnet werden oder versetzt werden; alle Formen, die nur im Bewegungsframe existieren, tragen ein opacity-Attribut. Es gibt keine eigenständige Darsteller-Zeit: Nur die zentrale Weltuhr treibt die Abspielgeschwindigkeit.

| Objekt | Animation | Funktion |
| --- | --- | --- |
| Werkstatt | grind | Arbeit am Werkstück: Werkzeugplan schlägt, Papierstaub fällt |
| Räucherei | raeuchern | Produktion: Rauchstöße über dem eigenen Schornstein |
| Lagerfeuer | flackern | Wärmequelle: Flamme flackert im Feuertakt |
| Busch | wehen | Natur: Kronenschichten wiegen sich im Wind |

## Tiere und Verhalten (Trigger-Zonen)

Die Tierverhalten stehen in `world/data/tier_verhalten.json` und werden nicht hart codiert:

| Tier | Auslöser im Umkreis | Reaktion |
| --- | --- | --- |
| Hase | 420 Pixel | Hoppelt kurz auf und rennt am Boden in Flugrichtung davon (nur Flucht, kein Fliegen) |
| Vogel | 380 Pixel | Fliegt davon, steigt während der ersten 40 Ticks schräg nach oben und blendet danach über 90 Ticks aus (Fade) |
| Vogelgruppe | 480 Pixel | Wie Vogel, aber mit größerem Radius und längerem Fade (110 Ticks) |
| Bär | 700 Pixel | Geht direkt auf die Spielereinheit zu und bleibt auf 120 Pixel Abstand stehen |

### Harvest-Werte (Fleisch) und Lebenspunkte

Die Werte stehen ebenfalls in `tier_verhalten.json` (Schlüssel `fleisch` und `hp`); vorerst entspricht die HP-Zahl dem Fleisch-Ertrag:

| Tier | Fleisch (Harvest) | HP (vorläufig) |
| --- | --- | --- |
| Bär | 30 | 30 |
| Hase | 5 | 5 |
| Vogel | 1 | 1 |
| Vogelgruppe | 3 (kleiner Ertrag je Vogel) | 3 |

`Tier_Manager` bietet dafür `tier_angreifen(tier_nummer, schaden)` und `tier_ernten(tier_nummer)`: Erst sinkt die HP, beim Ernten eines toten Tieres wird der Fleisch-Ertrag zurückgegeben und der Darsteller blendet kurz aus. Tote Tiere bewegen sich nicht mehr, bis sie geerntet werden.

## Strichmännchen als Spielfiguren (Jobs)

Die Strichmännchen sind die Spielfiguren. Ihre Animationen stehen zentral in `game/data/animationen.json`, die Idle-Bewegung ist reine Atmung und Wiegen: die Füße bleiben in allen Frames an denselben Punkten, weil sich eine Einheit im Idle niemals selbst bewegt. Bewegungen legt ausschließlich der Spieler fest.

Jede Einheit hat einen Job-Wert. Der Spieler legt den Job fest, indem er das passende Job-Objekt anklickt; die Einheit übernimmt die dazugehörige Arbeit:

| Job | Job-Objekt | Ressource | Arbeitsanimation |
| --- | --- | --- | --- |
| Holzfäller | Baum | Holz | hacken |
| Steinmetz | Stein, Steingruppe | Stein | hacken |
| Jäger | Tiere (nach dem Erlegen) | Fleisch | hacken |

Die Regeln für Jobs liegen in `game/data/job_config.json` (Harvest-Zeit in Ticks, Menge je Arbeitsschritt, Reichweite); jeder Job ist ein eigenes Skript in `game/logic/` (`job_holzfaeller.gd`, `job_steinmetz.gd`, `job_jaeger.gd`) und erbt von `job_basis.gd`. Neue Jobs werden als eigenes Skript in der passenden Domäne angelegt und in `job_registry.gd` registriert, ohne bestehende Dateien zu verändern. Die Ressourcen mit ihren Icons stehen zentral in `game/data/ressourcen.json`.

In der Karte vergibt man den Job per Linksklick auf Baum, Stein oder Tier (innerhalb der Reichweite), Rechtsklick bricht den Job ab; das HUD zeigt den aktuellen Job und die gesammelten Ressourcen mit den SVG-Icons.

Die Bewegung läuft ausschließlich über den globalen Tick (Weltuhr, 24 Ticks/Sekunde); `Einheit_Status` ist die Zustandsmaschine pro Einheit (nur IDLE und ARBEITEN, keine eigene Bewegung), `Einheit_Darsteller` spielt die Animationen aus den zentralen Sheets ab und `Einheit_Manager` wickelt die Arbeitsschritte ab. Beim Jagen verletzt jeder Schlag das Tier; erst ein totes Tier kann geerntet werden.

Die Tierbewegung läuft ebenfalls über den globalen Tick (Weltuhr, 24 Ticks/Sekunde); `Tier_Manager` prüft die Trigger-Zonen, `Tier_Status` ist die Zustandsmaschine pro Tier und `Tier_Darsteller` spielt die Frames ab, spiegelt die Richtung und setzt das Verblassen um. In der Karte werden Tiere als Objekte mit dem Typ `bewegt` im Element-Katalog geführt; der Prototyp-Karte dient ein Spielermarker (WASD/Pfeiltasten) als Test-Spielereinheit.

## Regeln für Dateien

- Nur relative Pfade: Die Vorschau liest die SVG-Dateien über relative Pfadangaben ein.
- Keine fest einprogrammierten Werte in Logikdateien: Werte stehen in den SVG-Dateien, in `element_katalog.json` bzw. in den Tabellen dieser Dokumentation.
- Neue Assets folgen denselben Stilregeln und werden in `vorschau_erzeugen.py` ergänzt, sodass die Vorschau sie automatisch anzeigt.
- Sprite-Sheets für Animationen haben immer vier Frames nebeneinander mit gleicher Frame-Breite (48 Pixel beim Strichmännchen); Godot schneidet die Frames über AtlasTexture aus.
- Funktions-Animationen der Objekte nutzen dieselbe Frame-Größe wie das zugehörige Standbild, und Frame 1 entspricht dem Standbild; die Standbilddatei selbst enthält keine Bewegungsformen.
- Animations-Frames der Spielfigur verankern die Füße an denselben Punkten (y = 58 in den Grund-Frames); Bewegung entsteht nie innerhalb der Animation.

## Struktur der Spieldomänen (Stand dieses Schritts)

| Ordner | Verantwortung |
| --- | --- |
| `core/weltuhr.gd` | Autoload: einziger globaler Tick (24 Ticks/Sekunde, klassischer RTS-Standard) |
| `ui/` | Hauptmenü, Menü-Zustandsmaschine, Weltauswahl, Sitzungszustand |
| `game/data/` | Zentrale Configs: Animationen, Job-Konfiguration, Ressourcen mit Icons |
| `game/logic/` | Job-Basis und konkrete Jobs (Einzelskripte), Job_Registry, Einheit-Ressourcen, Einheit-Zustandsmaschine, Darsteller und Manager in Kategorie-Ordnern |
| `world/logic/` | Welt-Modell, Welt-Speicher, Element-Registry, Karten-Renderer, Editor-Werkzeugmaschine, Tier-Logik |
| `world/data/` | Element-Katalog (mit Kategorien), Tier-Verhalten und Standardwelt als JSON |
| `world/scenes/` | Prototyp-Karte und Karten-Editor als Godot-Szenen |

## Karten-Editor im Kreativmodus

- Der Editor ist ein eigener UI-Modus („Kreativmodus") und dient dem Bau von Testkarten.
- Alle Assets erscheinen in einer Seitenleiste, sortiert nach Kategorien aus `element_katalog.json` (aktuell Terrain, Natur, Gebäude). Neue Kategorien entstehen automatisch, sobald ein Katalogeintrag eine neue Kategorie erhält.
- Platzieren erfolgt per Drag & Drop: Maustaste auf einer Asset-Kachel halten, auf die Karte ziehen, loslassen.
- Platzierte Objekte lassen sich erneut anfassen und per Drag & Drop verschieben; mit dem Werkzeug „Entfernen" löscht man Objekte.
- Karten sind relativ groß: Standard 32x24 Kacheln à 512 Pixel (16384x12288 Pixel Weltgröße), beliebig zwischen 4x4 und 64x64 Kacheln möglich. Die Kamera folgt den Pfeiltasten, das Mausrad zoomt.
- Gespeicherte Welten liegen als JSON im Benutzerordner und enthalten Kartengröße, Fliesenraster und Objektliste mit Positionen.

Version: V0.01
