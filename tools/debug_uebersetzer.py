# -*- coding: utf-8 -*-
"""Debug Übersetzer. Eigene Zuständigkeit: Godot-Ausgabe in eigene Fehlercodes übersetzen."""

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class Uebersetzung:
    code: str
    text: str


class DebugUebersetzer:
    """Nimmt eine rohe Godot-Zeile und liefert den passenden E-Code plus menschenlesbaren Hinweis."""

    MUSTER: list[tuple[re.Pattern, str, str]] = [
        # E016 Parse / Struktur
        (re.compile(r"hides an autoload singleton", re.I), "E016", "Autoload Schatten: Klassenname verdeckt Autoload. Autoload umbenennen, Klasse behalten und über bus() zugreifen."),
        (re.compile(r"Could not resolve super class", re.I), "E016", "Vererbung gebrochen: Basisklasse fehlt oder class_name nicht im Cache. Cache neu importieren, class_name prüfen."),
        (re.compile(r"Parse Error", re.I), "E016", "Parse Fehler: Syntax oder Typ in der genannten Datei. Zeile im Headless Log prüfen."),
        (re.compile(r"SCRIPT ERROR", re.I), "E016", "Skript Fehler zur Laufzeit: Aufruf auf null oder falscher Typ."),
        (re.compile(r"Failed to load script", re.I), "E016", "Skript konnte nicht geladen werden: Abhängigkeit vorher rot."),
        # E017 Unbekannte Definition
        (re.compile(r"not declared in the current scope", re.I), "E017", "Unbekannter Bezeichner: Klasse oder Variable nicht sichtbar. class_name oder preload prüfen und Cache neu bauen."),
        (re.compile(r"Could not find type", re.I), "E017", "Typ unbekannt: Class_name fehlt oder falscher Pfad. Datei enthält class_name und liegt im richtigen Ordner."),
        (re.compile(r"Could not parse global class", re.I), "E017", "Globale Klasse nicht parsebar: Ziel Datei hat selbst Parse Fehler."),
        (re.compile(r"Could not resolve.*class", re.I), "E017", "Klasse nicht auflösbar: Vererbung oder Registry Ziel fehlt."),
        (re.compile(r"Cannot find member", re.I), "E017", "Member fehlt: Methode oder Feld in Basis nicht vorhanden. Weltuhr.tick statt Kern_Weltuhr.tick prüfen."),
        (re.compile(r"Cannot infer the type", re.I), "E017", "Typ Inferenz gescheitert: Variable braucht expliziten Typ, z.B. var x: Typ := ..."),
        (re.compile(r"Identifier .* not declared", re.I), "E017", "Bezeichner nicht deklariert: Autoload oder Import fehlt."),
        # E018 Warnings als Fehler
        (re.compile(r"WARNING.*Variant.*Warning treated as error", re.I), "E018", "Variant Warning: var ohne Typ wird als Variant gefolgert. Expliziten Typ ergänzen."),
        (re.compile(r"WARNING.*Variant", re.I), "E018", "Variant Warnung: Impliziter Variant Typ. Typisierung nachziehen."),
        (re.compile(r"WARNING.*unused", re.I), "E018", "Ungenutzter Code: Signal oder Parameter ohne Nutzung. @warning_ignore ergänzen oder nutzen."),
        (re.compile(r"WARNING.*SHADOWED", re.I), "E018", "Schatten Warnung: Parameter verdeckt Basis Eigenschaft. Name umbenennen."),
        (re.compile(r"WARNING", re.I), "E018", "Warning als Fehler: In-Engine Warnung, nicht verstecken. Zeile beheben oder explizit ignorieren."),
        (re.compile(r"ERROR", re.I), "E016", "Error im Lauf: Siehe Details der Zeile, meist Vorfehler."),
    ]

    def uebersetze(self, zeile: str) -> Uebersetzung:
        gekuerzt = zeile.strip()
        for muster, code, hinweis in self.MUSTER:
            if muster.search(gekuerzt):
                return Uebersetzung(code=code, text=f"{gekuerzt} | Hinweis: {hinweis}")
        # Fallback
        if "ERROR" in gekuerzt or "Parse Error" in gekuerzt:
            return Uebersetzung(code="E016", text=gekuerzt)
        if "WARNING" in gekuerzt:
            return Uebersetzung(code="E018", text=gekuerzt)
        return Uebersetzung(code="E018", text=gekuerzt)

    def datei_und_zeile(self, zeile: str) -> tuple[str, int]:
        treffer = re.search(r"res://([^\s:]+):(\d+)", zeile)
        if treffer is not None:
            return treffer.group(1), int(treffer.group(2))
        treffer2 = re.search(r"([A-Za-z0-9_/\\]+\.gd):(\d+)", zeile)
        if treffer2 is not None:
            return treffer2.group(1), int(treffer2.group(2))
        return "godot", 0
