# -*- coding: utf-8 -*-
"""Erzeugt die Vorschau-Seite, indem alle SVG-Assets direkt eingebettet werden.

Die SVG-Dateien bleiben die alleinige Quelle. Dieses Skript liest sie ein und
schreibt die Vorschau neu. Ausgeführt wird es aus dem Ordner world/assets:
    python vorschau_erzeugen.py
"""

from pathlib import Path

ORDNER_HIER = Path(__file__).resolve().parent
ORDNER_TERRAIN = ORDNER_HIER / "terrain"
ORDNER_TIERE = ORDNER_HIER / "tiere"
ORDNER_UI = ORDNER_HIER / "ui"

# Reihenfolge und Beschriftung der Einzel-Assets
EINZEL_ASSETS = [
    ("baum.svg", "Baum", 128, 160),
    ("baum_stumpf.svg", "Baumstumpf", 96, 88),
    ("stein.svg", "Stein", 96, 88),
    ("steine_gruppe.svg", "Steingruppe", 160, 104),
    ("../ui/laeufer_rechts.svg", "Läufer rechts (4 Frames)", 192, 64),
    ("../ui/laeufer_links.svg", "Läufer links (4 Frames)", 192, 64),
]

# Reihenfolge der Kacheln für das 3x3-Muster
KACHELN = [
    ("boden_kachel.svg", "Boden-Kachel"),
    ("wiese_kachel.svg", "Wiese-Kachel"),
]

# Häuser als eigene Gruppe mit eigenem Bildausschnitt
HAUSER = [
    ("haus.svg", "Haus", 160, 144),
    ("haus_gross.svg", "Großes Haus", 208, 160),
]

# Tiere: Sprite-Sheets mit 4 Frames à Frame-Breite
TIERE = [
    ("baer.svg", "Bär (4 Frames)", 48, 72),
    ("hase.svg", "Hase (4 Frames)", 32, 72),
    ("vogel.svg", "Vogel (4 Frames)", 32, 64),
    ("vogelgruppe.svg", "Vogelgruppe (4 Frames)", 48, 64),
]

# Spielfigur: Animations-Sheets mit festen Fußpunkten
FIGUREN = [
    ("laeufer_rechts.svg", "Laufen rechts (4 Frames)", 48, 64),
    ("laeufer_links.svg", "Laufen links (4 Frames)", 48, 64),
    ("idle_rechts.svg", "Idle rechts (4 Frames, Füße fest)", 48, 64),
    ("idle_links.svg", "Idle links (4 Frames, Füße fest)", 48, 64),
    ("hacken_rechts.svg", "Holzhacken rechts (4 Frames, Füße fest)", 64, 64),
    ("hacken_links.svg", "Holzhacken links (4 Frames, Füße fest)", 64, 64),
]

# Ressourcen-Icons aus der zentralen Konfiguration
ICONS = [
    ("ressource_holz.svg", "Holz", 64, 64),
    ("ressource_stein.svg", "Stein", 64, 64),
    ("ressource_fleisch.svg", "Fleisch", 64, 64),
]

SEITEN_VORLAGE = """<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>Papercraft-Assets – Vorschau</title>
<style>
  :root {{
    --papier: #F6F1E4;
    --tinte: #4A4237;
  }}
  body {{
    margin: 0;
    background: #E9E2D0;
    color: var(--tinte);
    font-family: Georgia, "Times New Roman", serif;
  }}
  h1 {{ text-align: center; margin: 24px 0 4px; }}
  .hinweis {{ text-align: center; margin: 0 0 20px; opacity: .75; }}
  .karte {{
    background: var(--papier);
    border-radius: 12px;
    box-shadow: 0 6px 18px rgba(74, 66, 55, .25);
    max-width: 960px;
    margin: 0 auto 28px;
    padding: 20px 24px 28px;
  }}
  .reihe {{
    display: flex;
    flex-wrap: wrap;
    gap: 32px;
    justify-content: center;
    align-items: flex-end;
  }}
  .feld {{
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
  }}
  .feld span {{ font-size: 14px; opacity: .8; }}
  .kacheln {{
    display: grid;
    grid-template-columns: repeat(3, 170px);
    justify-content: center;
    border: 2px solid var(--tinte);
    border-radius: 8px;
    overflow: hidden;
  }}
  .kacheln img {{ display: block; width: 170px; height: 170px; }}
  .sprite {{
    filter: drop-shadow(0 10px 8px rgba(74, 66, 55, .18));
  }}
</style>
</head>
<body>
<h1>Papercraft-Assets – Vorschau</h1>
<p class="hinweis">Erster Blick auf die modularen SVG-Assets im Papierschnitt-Stil.</p>

<div class="karte">
  <div class="reihe">
{einzel}
  </div>
</div>

<div class="karte">
  <div class="reihe">
{haeuser}
  </div>
</div>

<div class="karte">
  <div class="reihe">
{tiere}
  </div>
</div>

<div class="karte">
  <div class="reihe">
{figuren}
  </div>
</div>

<div class="karte">
  <div class="reihe">
{icons}
  </div>
</div>

<div class="karte">
  <div class="kacheln">
{kacheln}
  </div>
</div>

</body>
</html>
"""

def lies_svg(name, ordner=None):
    pfad = (ordner or ORDNER_TERRAIN) / name
    with pfad.open("r", encoding="utf-8") as datei:
        inhalt = datei.read()
    # Namespace-Fehler abfangen, bevor die Seite kaputtgeht
    if 'xmlns="http://www.w3.org/2000/svg"' not in inhalt:
        raise SystemExit(f"{pfad}: xmlns fehlt oder ist fehlerhaft")
    return inhalt

def baue_gruppe(asset_liste, ordner=None):
    zeilen = []
    for name, beschriftung, breite, hoehe in asset_liste:
        svg = lies_svg(name, ordner)
        zeilen.append(
            '    <div class="feld">'
            f'<div class="sprite" style="width:{breite * 1.4:.0f}px;height:{hoehe * 1.4:.0f}px">{svg}</div>'
            f'<span>{beschriftung}</span>'
            "</div>"
        )
    return "\n".join(zeilen)

def baue_einzel():
    return baue_gruppe(EINZEL_ASSETS)

def baue_haeuser():
    return baue_gruppe(HAUSER)

def baue_tiere():
    return baue_gruppe(TIERE, ORDNER_TIERE)

def baue_figuren():
    return baue_gruppe(FIGUREN, ORDNER_UI)

def baue_icons():
    return baue_gruppe(ICONS, ORDNER_UI)

def baue_kacheln():
    zeilen = []
    for _durchlauf in range(3):
        for name, _beschriftung in KACHELN:
            svg = lies_svg(name)
            svg = svg.replace('width="512" height="512"', 'width="170" height="170"')
            zeilen.append(f"    {svg}")
    return "\n".join(zeilen)

def hauptprogramm():
    svg_einzel = baue_einzel()
    svg_haeuser = baue_haeuser()
    svg_tiere = baue_tiere()
    svg_figuren = baue_figuren()
    svg_icons = baue_icons()
    svg_kacheln = baue_kacheln()
    seite = SEITEN_VORLAGE.format(einzel=svg_einzel, haeuser=svg_haeuser, tiere=svg_tiere, figuren=svg_figuren, icons=svg_icons, kacheln=svg_kacheln)
    ziel = ORDNER_HIER / "vorschau.html"
    with ziel.open("w", encoding="utf-8") as datei:
        datei.write(seite)
    print(f"Vorschau geschrieben: {ziel}")

if __name__ == "__main__":
    hauptprogramm()
