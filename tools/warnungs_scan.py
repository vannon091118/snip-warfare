# -*- coding: utf-8 -*-
"""Warnungs-Scan. Eigene Zuständigkeit: erkennt deterministisch dieselben
GDScript-Warnklassen, die der Godot-Editor bei einem Script-Reload meldet,
und liefert Befunde mit Datei und Zeile.

Hintergrund: Die Editor-Warnungen (Integer-Division, Schatten, ungenutzte
Parameter/Variablen/Signale, statische Aufrufe auf Instanzen, verwirrende
Deklarationen) erscheinen nur im GUI-Editor-Reload, nicht im Headless-Lauf.
Dieser Scan macht sie zur Pflichtprüfung im Preflight, damit kein stilles
Grün über Warnungen liegt. Er ist bewusst konservativ: Gemeldet wird nur,
was eindeutig der Engine-Warnklasse entspricht.
"""

import re
from pathlib import Path

INT_LITERAL = re.compile(r"^\d+$")  # ohne Punkt: 60.0 ist float, 60 ist int
VAR_DECL = re.compile(r"\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?::\s*([A-Za-z_][A-Za-z0-9_.]*))?\s*(:=|=)")
FUNC_SIG = re.compile(r"^func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\((.*?)\)\s*(?:->|:)", re.M)
PARAM = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*(?::\s*[^,)]+)?(?:,|$)")
SIGNAL_DECL = re.compile(r"^\s*signal\s+([A-Za-z_][A-Za-z0-9_]*)")
STATISCH_AUF_RUF = re.compile(r"\b([a-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)\(")

# Methoden der Godot-Basisklassen, die bei Parametern mit gleichem Namen
# die Engine-Warnung SHADOWED_VARIABLE auslösen (Node2D, Control, Label).
BASIS_FUNKTIONEN = {
    "position", "get_position", "scale", "rotation", "visible", "modulate",
    "text", "get_text", "value", "size", "global_position", "global_scale",
    "z_index", "process_mode", "owner", "name", "path", "get_name",
    "get_parent", "get_children", "queue_free", "set_text", "get_value",
}

# Basisklassen, bei denen ein Parameter wie "position" tatsächlich die
# gleichnamige Eigenschaft der Engine verschattet (Godot meldet
# SHADOWED_VARIABLE_BASE_CLASS). Für RefCounted/Resource gilt das nicht.
BASIS_KLASSEN_MIT_POSITION = {
    "Node2D", "CanvasItem", "Sprite2D", "AnimatedSprite2D", "CharacterBody2D",
    "Area2D", "Control", "Label", "Button", "TextureRect", "ColorRect",
    "Panel", "Node",  # Node selbst hat kein position, wird unten gefiltert
}
# Node hat kein position – deshalb extra Menge für position-relevante Basen.
POSITION_BASEN = {
    "Node2D", "CanvasItem", "Sprite2D", "AnimatedSprite2D", "CharacterBody2D",
    "Area2D", "Control", "Label", "Button", "TextureRect", "ColorRect", "Panel",
}

# Ausdrücke, die bekanntermaßen int liefern; für die Integer-Divisions-Prüfung.
INT_RUECKGABE_FUNKTIONEN = {
    "size", "count", "len", "maxi", "mini", "clampi", "absi", "floori",
    "ceili", "roundi", "objekt_anzahl", "lager_zahl", "raster_breite",
    "raster_hoehe", "region_kante", "chunk_groesse", "ticks_aus_faktor",
}


class Befund:
    """Ein Warn-Befund: Datei, Zeile, Warnklasse und Meldung."""

    def __init__(self, datei: Path, zeile: int, klasse: str, meldung: str):
        self.datei = datei
        self.zeile = zeile
        self.klasse = klasse
        self.meldung = meldung


class WarnungsScan:
    """Scannt alle GDScript-Dateien auf die Editor-Warnklassen."""

    def __init__(self, projekt_stamm: Path):
        self.projekt_stamm = projekt_stamm

    def scanne(self, dateien):
        """dateien: Liste aus (Pfad, Code). Liefert Liste[Befund]."""
        befunde = []
        for pfad, code in dateien:
            relativ = pfad.relative_to(self.projekt_stamm)
            befunde.extend(self._datei_scannen(relativ, code))
        return befunde

    # ------------------------------------------------------------------
    # Datei-Ebene
    # ------------------------------------------------------------------

    def _datei_scannen(self, relativ: Path, code: str) -> list:
        befunde = []
        zeilen = code.splitlines()
        funktionen = set(re.findall(r"^func\s+([A-Za-z_][A-Za-z0-9_]*)", code, re.M))
        # Basisklasse und Member-Variablen für SHADOWED_VARIABLE (Godot meldet
        # sowohl Verschattung einer Basiseigenschaft als auch einer Member-Variablen).
        basis_treffer = re.search(r"^\s*extends\s+([A-Za-z_][A-Za-z0-9_]*)", code, re.M)
        basis_klasse = basis_treffer.group(1) if basis_treffer else ""
        # Nur top-level vars (ohne führenden Tab/Leerzeichen) sind Member.
        member_vars = set(re.findall(r"^var\s+([A-Za-z_][A-Za-z0-9_]*)\b", code, re.M))
        for nummer, zeile in enumerate(zeilen, start=1):
            signal_treffer = SIGNAL_DECL.match(zeile)
            if signal_treffer:
                name = signal_treffer.group(1)
                if not self._signal_genutzt(code, name):
                    # Bewusste Vertrags-Signale (dokumentiert mit "nicht emittiert"
                    # oder "bewusst") sind keine Befunde.
                    umgebung = "\n".join(zeilen[max(nummer - 3, 0):nummer + 1]).lower()
                    if "bewusst" in umgebung or "nicht emittiert" in umgebung or "nicht verbunden" in umgebung:
                        continue
                    befunde.append(Befund(relativ, nummer, "UNUSED_SIGNAL",
                                          'Signal "%s" ist deklariert, wird aber nirgends verbunden oder emittiert.' % name))
        # Funktions-Ebene: Parameter und lokale Variablen.
        for treffer in FUNC_SIG.finditer(code):
            funktions_name = treffer.group(1)
            parameter_text = treffer.group(2)
            start = treffer.end()
            ende = self._funktions_ende(code, start)
            funktions_code = code[start:ende]
            funktions_zeilen_offset = code.count("\n", 0, start)
            befunde.extend(self._funktion_scannen(
                relativ, funktions_name, parameter_text, funktions_code,
                funktions_zeilen_offset, funktionen, code, basis_klasse, member_vars))
        return befunde

    def _signal_genutzt(self, code: str, name: str) -> bool:
        for muster in (r"\.emit\b", r"\.connect\b", r"\.disconnect\b"):
            if re.search(r"\b%s\s*%s" % (re.escape(name), muster), code):
                return True
        # Direkte Verbindung ohne Objekt: name.connect(...)
        if re.search(r"\b%s\s*\.connect\b" % re.escape(name), code):
            return True
        return False

    def _funktions_ende(self, code: str, start: int) -> int:
        """Ende der Funktion über Einrückung: nächste Top-Level-func-Zeile.

        GDScript nutzt Tabs; eine Top-Level-Funktion beginnt mit 'func ' ohne
        führenden Tab. Alles bis zur nächsten solchen Zeile gehört zum Körper.
        """
        zeilen = code[start:].splitlines()
        position = start
        for zeile in zeilen:
            if zeile.startswith("\t") or zeile.startswith("    "):
                position += len(zeile) + 1
                continue
            if zeile.strip() == "":
                position += len(zeile) + 1
                continue
            if zeile.lstrip().startswith("func "):
                return position
            # Kommentar oder Klassenkopf auf Top-Level: nicht Teil des Körpers.
            position += len(zeile) + 1
        return len(code)

    # ------------------------------------------------------------------
    # Funktions-Ebene
    # ------------------------------------------------------------------

    def _funktion_scannen(self, relativ, funktions_name, parameter_text,
                          funktions_code, offset, funktionen, gesamt_code, basis_klasse="", member_vars=None) -> list:
        if member_vars is None:
            member_vars = set()
        befunde = []
        parameter = [p.strip().split(":")[0].strip()
                     for p in parameter_text.split(",") if p.strip()]
        # UNUSED_PARAMETER und SHADOWED_VARIABLE je Parameter.
        for parameter_name in parameter:
            if parameter_name.startswith("_"):
                continue
            gebrauch = len(re.findall(r"\b%s\b" % re.escape(parameter_name), funktions_code))
            if gebrauch == 0 and funktions_code.strip() != "":
                befunde.append(Befund(relativ, offset + 1, "UNUSED_PARAMETER",
                                      'Der Parameter "%s" wird in der Funktion "%s" nie verwendet.' % (parameter_name, funktions_name)))
            # SHADOWED_VARIABLE: drei echte Godot-Fälle – Parameter verschattet
            # (a) eine Funktion der eigenen Klasse, (b) eine Member-Variable
            # der Klasse (welt_position), (c) eine Eigenschaft der Basisklasse
            # (Node2D.position). Früher wurde (c) für position/text unterdrückt,
            # deshalb blieb Godots SHADOWED_VARIABLE_BASE_CLASS unentdeckt.
            verschattet = False
            grund = ""
            if parameter_name in funktionen:
                verschattet = True
                grund = "Funktion"
            elif parameter_name in member_vars:
                verschattet = True
                grund = "Member-Variable"
            elif parameter_name in BASIS_FUNKTIONEN:
                # Nur melden, wenn die Basisklasse die Eigenschaft wirklich hat.
                if parameter_name == "position" and basis_klasse not in POSITION_BASEN:
                    pass
                elif parameter_name == "global_position" and basis_klasse not in POSITION_BASEN:
                    pass
                elif basis_klasse in BASIS_KLASSEN_MIT_POSITION or parameter_name in ("name", "owner", "visible", "modulate"):
                    # Für generische Basen wie Node gilt nur subset.
                    if basis_klasse == "Node" and parameter_name in ("position", "global_position", "scale", "rotation", "z_index", "global_scale"):
                        pass
                    else:
                        verschattet = True
                        grund = "Basiseigenschaft %s" % basis_klasse
                elif parameter_name in ("text", "value", "size") and basis_klasse in ("Control", "Label", "Button", "TextureRect"):
                    verschattet = True
                    grund = "Basiseigenschaft %s" % basis_klasse
            if verschattet:
                befunde.append(Befund(relativ, offset + 1, "SHADOWED_VARIABLE",
                                      'Der Parameter "%s" verschattet eine gleichnamige %s.' % (parameter_name, grund)))
        # UNUSED_VARIABLE: lokale Deklarationen, die im Funktionskörper nie auftauchen.
        for treffer in VAR_DECL.finditer(funktions_code):
            name = treffer.group(1)
            if name.startswith("_"):
                continue
            # Nur Deklarationen, die wirklich im Funktionskörper liegen (erste Zeile).
            if treffer.start() >= len(funktions_code) or funktions_code[treffer.start():].strip().startswith("return"):
                continue
            benutzungen = len(re.findall(r"\b%s\b" % re.escape(name), funktions_code))
            if benutzungen <= 1 and not re.search(r"\b%s\s*\(" % re.escape(name), funktions_code):
                zeile = offset + funktions_code.count("\n", 0, treffer.start()) + 1
                befunde.append(Befund(relativ, zeile, "UNUSED_VARIABLE",
                                      'Die lokale Variable "%s" wird nie verwendet.' % name))
        # INTEGER_DIVISION: Division zweier int-typisierter Operanden.
        int_variablen = self._int_variablen(funktions_code)
        for nummer, zeile in enumerate(funktions_code.splitlines(), start=1):
            # Nur ganze Token: 60.0 ist float, 60 ist int; \w allein würde die
            # Nachkomma-Stelle von 60.0 als eigene Zahl lesen.
            for div in re.finditer(r"(\d+\.\d+|[A-Za-z_]\w*)\s*/\s*(\d+\.\d+|[A-Za-z_]\w*)", zeile):
                links, rechts = div.group(1), div.group(2)
                if (self._ist_int(links, int_variablen, gesamt_code)
                        and self._ist_int(rechts, int_variablen, gesamt_code)):
                    befunde.append(Befund(relativ, offset + nummer, "INTEGER_DIVISION",
                                          "Integer-Division: %s / %s verwirft den Nachkommaanteil." % (links, rechts)))
        # STATIC_CALLED_ON_INSTANCE: Methodenaufruf auf einer Instanz-Variable.
        for treffer in STATISCH_AUF_RUF.finditer(funktions_code):
            instanz, methode = treffer.group(1), treffer.group(2)
            if not instanz.startswith("_") and not instanz[0].isupper():
                continue
            if instanz[0].isupper():
                continue  # Typ-Aufruf (Klasse.Methode) ist korrekt.
            # Nur wenn die Instanz als Variable deklariert ist und die Methode
            # als statische Funktion der Klasse existiert (heuristisch: Methode
            # heißt neuer_zustand oder ist eine bekannte statische Fabrik).
            if methode in ("neuer_zustand", "neuer_eintrag", "erzeugen", "aus_katalog"):
                befunde.append(Befund(relativ, offset + funktions_code.count("\n", 0, treffer.start()) + 1,
                                      "STATIC_CALLED_ON_INSTANCE",
                                      'Die statische Funktion "%s" wird über die Instanz "%s" statt über den Typ aufgerufen.' % (methode, instanz)))
        # CONFUSABLE_LOCAL_DECLARATION: gleicher Variablenname in Eltern- und Kind-Block.
        for treffer in VAR_DECL.finditer(funktions_code):
            name = treffer.group(1)
            davor = funktions_code[:treffer.start()]
            if re.search(r"\bvar\s+%s\b" % re.escape(name), davor):
                zeile = offset + funktions_code.count("\n", 0, treffer.start()) + 1
                befunde.append(Befund(relativ, zeile, "CONFUSABLE_LOCAL_DECLARATION",
                                      'Die Variable "%s" wurde bereits im umgebenden Block deklariert.' % name))
        return befunde

    def _int_variablen(self, code: str) -> set:
        """Namen lokaler Variablen, die sicher int sind (explizit oder Literal)."""
        ints = set()
        for treffer in VAR_DECL.finditer(code):
            name, typ, op, wert_teil = self._zerlege(treffer)
            if typ in ("int", "Vector2i", "Vector3i", "Array[int]"):
                ints.add(name)
                continue
            if op == ":=" and wert_teil is not None:
                wert = wert_teil.strip()
                if INT_LITERAL.match(wert):
                    ints.add(name)
                else:
                    aufruf = re.match(r"([A-Za-z_][A-Za-z0-9_]*)\(?", wert)
                    if aufruf and aufruf.group(1) in INT_RUECKGABE_FUNKTIONEN:
                        ints.add(name)
        return ints

    def _zerlege(self, treffer):
        name = treffer.group(1)
        typ = (treffer.group(2) or "").strip()
        op = treffer.group(3)
        rest = treffer.group(0)
        wert_start = rest.find(op) + len(op)
        wert = rest[wert_start:].strip()
        return name, typ, op, wert

    def _ist_int(self, ausdruck: str, int_variablen: set, gesamt_code: str) -> bool:
        if re.match(r"^\d+$", ausdruck):
            return True
        if ausdruck in int_variablen:
            return True
        if ausdruck in ("size", "count", "length"):
            return True
        return False
