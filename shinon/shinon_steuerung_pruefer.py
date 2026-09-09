# -*- coding: utf-8 -*-
"""Shinon Steuerung Prüfer. Eigene Zuständigkeit: Die Steuerung bleibt lesbar und aktuell."""

import json
from dataclasses import dataclass
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent
STEUERUNG_PFAD = PROJEKT_STAMM / "game" / "data" / "steuerung.json"


@dataclass(frozen=True)
class ShinonSteuerungBefund:
    code: str
    datei: str
    zeile: int
    text: str


class ShinonSteuerungPruefer:
    """Prüft ob game/data/steuerung.json als menschenlesbare Config existiert und gültig ist."""

    def pruefen(self, pfad: Path | None = None) -> list[ShinonSteuerungBefund]:
        ziel = pfad or STEUERUNG_PFAD
        rel = str(ziel.relative_to(PROJEKT_STAMM)) if ziel.is_relative_to(PROJEKT_STAMM) else str(ziel)
        if not ziel.is_file():
            return [ShinonSteuerungBefund(
                code="E036",
                datei=rel,
                zeile=1,
                text="Steuerung Pflicht: Die Datei game/data/steuerung.json fehlt, jede Steuerung muss menschenlesbar konfiguriert sein -- WASD Kamera, Linksklick Einzel, Drag Masse, Rechtsklick Kontextmenue mit sammeln und abbauen samt Tooltip und Werkzeug.",
            )]
        try:
            inhalt = ziel.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            return [ShinonSteuerungBefund(
                code="E036",
                datei=rel,
                zeile=1,
                text="Steuerung Pflicht: Die Datei game/data/steuerung.json ist nicht als UTF-8 lesbar.",
            )]
        try:
            daten = json.loads(inhalt)
        except ValueError as fehler:
            return [ShinonSteuerungBefund(
                code="E036",
                datei=rel,
                zeile=1,
                text=f"Steuerung Pflicht: Die Datei game/data/steuerung.json ist kein gültiges JSON -- {fehler}.",
            )]
        if not isinstance(daten, dict):
            return [ShinonSteuerungBefund(
                code="E036",
                datei=rel,
                zeile=1,
                text="Steuerung Pflicht: Die Datei game/data/steuerung.json muss ein Objekt mit kamera, auswahl und kontextmenue sein.",
            )]
        befunde: list[ShinonSteuerungBefund] = []
        kamera = daten.get("kamera")
        if not isinstance(kamera, dict):
            befunde.append(ShinonSteuerungBefund(
                code="E036", datei=rel, zeile=1,
                text="Steuerung Pflicht: Abschnitt kamera fehlt oder ist kein Objekt, erwartet werden tasten, geschwindigkeit und Beschreibung für WASD.",
            ))
        else:
            if not kamera.get("tasten"):
                befunde.append(ShinonSteuerungBefund(
                    code="E036", datei=rel, zeile=1,
                    text="Steuerung Pflicht: kamera.tasten fehlt oder ist leer, WASD muss explizit als tasten konfiguriert sein.",
                ))
            geschw = kamera.get("geschwindigkeit")
            if not isinstance(geschw, (int, float)) or geschw <= 0:
                befunde.append(ShinonSteuerungBefund(
                    code="E036", datei=rel, zeile=1,
                    text="Steuerung Pflicht: kamera.geschwindigkeit fehlt oder ist ungueltig, erwartet wird eine Zahl groesser 0.",
                ))
        auswahl = daten.get("auswahl")
        if not isinstance(auswahl, dict):
            befunde.append(ShinonSteuerungBefund(
                code="E036", datei=rel, zeile=1,
                text="Steuerung Pflicht: Abschnitt auswahl fehlt, erwartet werden Linksklick einzeln und Links halten und ziehen fuer Masse.",
            ))
        else:
            if str(auswahl.get("ausloeser_einzeln", "")) != "linksklick":
                befunde.append(ShinonSteuerungBefund(
                    code="E036", datei=rel, zeile=1,
                    text="Steuerung Pflicht: auswahl.ausloeser_einzeln muss linksklick sein, sonst versteht niemand die Einzelauswahl.",
                ))
            if str(auswahl.get("ausloeser_masse", "")) != "links_halten_ziehen":
                befunde.append(ShinonSteuerungBefund(
                    code="E036", datei=rel, zeile=1,
                    text="Steuerung Pflicht: auswahl.ausloeser_masse muss links_halten_ziehen sein, sonst ist die Massenauswahl nicht erkennbar.",
                ))
        kontext = daten.get("kontextmenue")
        if not isinstance(kontext, dict):
            befunde.append(ShinonSteuerungBefund(
                code="E036", datei=rel, zeile=1,
                text="Steuerung Pflicht: Abschnitt kontextmenue fehlt, Rechtsklick muss immer ein Menue mit sammeln und abbauen samt tooltip fuer Werkzeug oeffnen.",
            ))
        else:
            if str(kontext.get("ausloeser", "")) == "":
                befunde.append(ShinonSteuerungBefund(
                    code="E036", datei=rel, zeile=1,
                    text="Steuerung Pflicht: kontextmenue.ausloeser fehlt, Rechtsklick muss explizit als immer oeffnend beschrieben sein.",
                ))
            aktionen = kontext.get("aktionen")
            if not isinstance(aktionen, list) or len(aktionen) < 2:
                befunde.append(ShinonSteuerungBefund(
                    code="E036", datei=rel, zeile=1,
                    text="Steuerung Pflicht: kontextmenue.aktionen muss mindestens sammeln und abbauen mit icon und tooltip enthalten.",
                ))
            else:
                ids = [str(a.get("id", "")) for a in aktionen if isinstance(a, dict)]
                if "sammeln" not in ids:
                    befunde.append(ShinonSteuerungBefund(
                        code="E036", datei=rel, zeile=1,
                        text="Steuerung Pflicht: In kontextmenue.aktionen fehlt die Aktion sammeln mit icon.",
                    ))
                if "abbauen" not in ids:
                    befunde.append(ShinonSteuerungBefund(
                        code="E036", datei=rel, zeile=1,
                        text="Steuerung Pflicht: In kontextmenue.aktionen fehlt die Aktion abbauen mit icon.",
                    ))
                for aktion in aktionen:
                    if not isinstance(aktion, dict):
                        continue
                    aktion_id = str(aktion.get("id", "unbekannt"))
                    if str(aktion.get("icon_pfad", "")) == "":
                        befunde.append(ShinonSteuerungBefund(
                            code="E036", datei=rel, zeile=1,
                            text=f"Steuerung Pflicht: Aktion {aktion_id} hat kein icon_pfad, jede Aktion braucht ein sichtbares Icon.",
                        ))
                    else:
                        icon_res = str(aktion.get("icon_pfad", ""))
                        if not icon_res.startswith("res://"):
                            befunde.append(ShinonSteuerungBefund(
                                code="E036", datei=rel, zeile=1,
                                text=f"Steuerung Pflicht: icon_pfad {icon_res} von {aktion_id} ist nicht im Format res:// und damit im Generator ungueltig.",
                            ))
                        elif not (PROJEKT_STAMM / icon_res[len("res://"):]).is_file():
                            befunde.append(ShinonSteuerungBefund(
                                code="E036", datei=rel, zeile=1,
                                text=f"Steuerung Pflicht: icon_pfad {icon_res} von {aktion_id} existiert nicht, fehlende Icons machen Aktionen unsichtbar.",
                            ))
                    if "{werkzeug}" not in str(aktion.get("tooltip", "")):
                        befunde.append(ShinonSteuerungBefund(
                            code="E036", datei=rel, zeile=1,
                            text=f"Steuerung Pflicht: Aktion {aktion_id} braucht einen tooltip mit Benoetigt Werkzeug Platzhalter, damit Spieler verstehen warum gesperrt ist.",
                        ))
        return befunde
