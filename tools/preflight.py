# -*- coding: utf-8 -*-
"""Preflight des Projekts: Naming, Daten-/Logik-Trennung, Determinismus und
Godot-Compilierung in einem Werkzeug mit Fehlercodes und Flags.

Verbindliche Regeltexte: Architektur.md. Kein Commit gilt als fertig,
solange dieser Preflight nicht vollständig grün ist. Grün bedeutet:
der Godot-Debugger meldet keine Fehler, keine unbekannten Definitionen
und keine Warnungen, und alle Prüfungen dieses Skripts sind erfüllt.

Fehlercodes:
  E000  Preflight-Selbsttest fehlgeschlagen (keine False Truth)
  E001  Klasse trägt kein Kategorie-Präfix
  E002  doppelter oder ähnlich klingender Klassenname
  E003  Klasse liegt nicht im Ordner ihrer Kategorie
  E004  Skript ohne class_name
  E005  Datei ist nicht als UTF-8 lesbar
  E006  Daten-Arrays ohne Markierung "## Kategorie daten"
  E007  Daten-Arrays ohne Markierung "## Kategorie logik"
  E008  unzulässiger Doppelpunkt im Klassennamen
  E009  unzulässiges Komma im Klassennamen
  E010  getyptes Array mit unbekanntem Elementtyp
  E011  Inventar der Datenobjekt-Erzeugung (Information, kein Fehler)
  E012  verbotener Zufallsaufruf (randi, randf, randomize, ...)
        außerhalb der erlaubten Klasse Kern_Zufall
  E013  Mutationsmatrix ohne zugeordnete Mutations-Klasse im selben Ordner
  E014  Mutationsschema ohne erkennbare Startzustände
  E015  Pfad-Eintrag existiert nicht oder ist nicht projektrelativ (res://)
  E016  Godot-Lauf: Parse-Fehler oder Script-Fehler
  E017  Godot-Lauf: unbekannte Definitionen (Typ, Klasse, Bezeichner)
  E018  Godot nicht ausführbar, oder Lauf meldet Fehler oder Warnungen
  E019  Registry- oder Matrix-Quelle fehlt, ist unlesbar oder hat falsches Format
  E020  Registry-Gruppe ohne Member-Registry, oder IDs kollidieren
  E021  Registry-Klassenname folgt nicht dem Schema Prefix_Registry
  E022  Registry-Eintrag zeigt auf kein gültiges Asset (res://*.svg/.png) und ist damit im Generator ungültig
  E023  RT Pyramide verletzt: Logik wird an zwei Orten gleich berechnet oder ein System faehrt zwei verschiedene Dinge
  E024  Biom Pflicht: Biome wirken nicht als Mutation und umgehen die Zustands Pyramide
  E030  Shinon Gate: Banner Verbot verletzt (Tralal oder dekorativer Sonderzeichen Rahmen)
  E031  Shinon Gate: Bullet Listen Verbot verletzt (Zeile beginnt mit - * + oder Mittelpunkt)
  E032  Shinon Gate: Nummerierungspflicht verletzt (jede inhaltstragende Zeile muss 1. Satz. sein)
  E033  Shinon Gate: Bildsprachepflicht verletzt (rein technische Aufzaehlung statt bildlicher Erzaehlung)
  E034  Shinon Gate: commit_msg.txt fehlt oder ist leer oder nicht als UTF-8 lesbar
  E035  Shinon Gate: README fehlt, ist leer oder bricht nicht die vierte Wand (Shinon Pitch Pflicht)
  E036  Steuerung Pflicht: game/data/steuerung.json fehlt oder ist nicht menschenlesbar konfiguriert

Prüfkategorien (Flags) und ihre Codes:
  klassen       E001 E002 E003 E004 E008 E009 E021
  trennung      E006 E007 E010
  daten         E005 E011
  determinismus E012 E013 E014 E019
  pfade         E015
  registries    E020 E022
  godot         E016 E017 E018
  shinon        E030 E031 E032 E033 E034
  assets        E022

Ausführung aus dem Projektstamm:
    python tools/preflight.py                            volle Abdeckung
    python tools/preflight.py --kategorie determinismus  nur ein Bereich
    python tools/preflight.py --kategorie klassen --kategorie pfade
    python tools/preflight.py --ohne-godot               ohne Engine-Lauf
    python tools/preflight.py --godot-befehl PFAD        anderer Godot-Pfad

Ohne Befunde endet das Skript mit Exit-Code 0, mit Befunden mit 1 und bei
unbrauchbarem Preflight (E000, unbekannte Flags) mit 2.
"""

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent

KATEGORIE_PRAEFIXE = {
    "Objekt_": "world/logic/kategorie_objekt",
    "Natur_": "world/logic/kategorie_objekt",
    "Gebaeude_": "world/logic/kategorie_objekt",
    "Resource_": "game/logic/kategorie_ressourcen",
    "Resources_": "game/logic/kategorie_ressourcen",
    "Tier_": "world/logic/kategorie_tier",
    "Einheit_": "game/logic/kategorie_einheit",
    "Job_": "game/logic/kategorie_job",
    "Ui_": "ui/logic/kategorie_ui",
    "Welt_": None,          # Welt_ darf domänenübergreifend liegen
    "Kern_": "core",
}

KATEGORIEN_TRENNUNG = ("## Kategorie daten", "## Kategorie logik")

ERLAUBTE_ZUFALLS_KLASSEN = ("Kern_Zufall",)

ZUFALLS_MUSTER = re.compile(
    r"\b(randi|randf|randi_range|randf_range|randfn|randomize)\s*\(")

ARRAY_BASISTYPEN = {
    "String", "int", "float", "bool", "Vector2", "Vector2i", "Vector3",
    "Dictionary", "Node", "Node2D", "Texture2D", "Color", "StringName",
    "RefCounted", "Resource", "AnimatedSprite2D", "Sprite2D", "Control",
    "PackedScene", "Label", "Button", "TextureRect",
}

PRUEFKATEGORIEN = {
    "klassen": ("E001", "E002", "E003", "E004", "E008", "E009", "E021"),
    "trennung": ("E006", "E007", "E010"),
    "daten": ("E005", "E011"),
    "determinismus": ("E012", "E013", "E014", "E019"),
    "pfade": ("E015",),
    "registries": ("E020", "E022"),
    "godot": ("E016", "E017", "E018"),
    "shinon": ("E030", "E031", "E032", "E033", "E034", "E035", "E036"),
    "assets": ("E022",),
    "pyramide": ("E023", "E024"),
    "biome": ("E024",),
    "einheitlich": ("E023", "E024"),
}

GODOT_FEHLER_MUSTER = ("ERROR", "WARNING", "Parse Error", "SCRIPT ERROR")

FEHLER = []


def fehler(code, datei, zeile, text):
    eintrag = (code, str(datei), zeile, text)
    if eintrag not in FEHLER:
        FEHLER.append(eintrag)


def zeile_von(code_index, suchtext):
    position = code_index.find(suchtext)
    if position < 0:
        return 1
    return code_index.count("\n", 0, position) + 1


def zeile_bei(code_index, position):
    return code_index.count("\n", 0, position) + 1


def lies_dateien():
    dateien = []
    for pfad in sorted(PROJEKT_STAMM.rglob("*.gd")):
        try:
            code = pfad.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            fehler("E005", pfad.relative_to(PROJEKT_STAMM), 1,
                   "Datei ist nicht als UTF-8 lesbar")
            continue
        dateien.append((pfad, code))
    return dateien


def klassen_name_lesen(code):
    treffer = re.search(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", code, re.M)
    return treffer.group(1) if treffer else None


# --------------------------------------------------------------------------
# E000: Selbsttest. Die Kernprüfungen werden gegen bekannte Beispiele
# ausgeführt; weicht ein Ergebnis ab, ist der Preflight selbst unbrauchbar.
# --------------------------------------------------------------------------

def _sammle_zufallsfundstellen(code, klasse):
    if klasse in ERLAUBTE_ZUFALLS_KLASSEN:
        return []
    return list(ZUFALLS_MUSTER.finditer(code))


def _matrix_zuordnung_aus_code(code):
    zuordnung = {}
    muster = re.compile(
        r'"([^"\n]+)"\s*:\s*\n\s*return\s+([A-Za-z_][A-Za-z0-9_]*)\.new\(\)')
    for treffer in muster.finditer(code):
        zuordnung[treffer.group(1)] = treffer.group(2)
    return zuordnung


def selbsttest():
    probleme = []
    probe_quelle = "extends RefCounted\nclass_name E000_Probe\nvar wert := randi()\n"
    if len(_sammle_zufallsfundstellen(probe_quelle, "E000_Probe")) != 1:
        probleme.append("Zufallsdetektor fand randi() in einer Fremdklasse nicht")
    kern_quelle = "extends RefCounted\nclass_name Kern_Zufall\nvar wert := randi()\n"
    if len(_sammle_zufallsfundstellen(kern_quelle, "Kern_Zufall")) != 0:
        probleme.append("Zufallsdetektor meldet erlaubte Aufrufe in Kern_Zufall")
    matrix_quelle = ('match str(eintrag.get("name", "")):\n'
                     '\t"TestA":\n'
                     '\t\treturn Probe_MutationA.new()\n'
                     '\t"TestB":\n'
                     '\t\treturn Probe_MutationB.new()\n')
    zuordnung = _matrix_zuordnung_aus_code(matrix_quelle)
    if zuordnung != {"TestA": "Probe_MutationA", "TestB": "Probe_MutationB"}:
        probleme.append("Matrix-Zuordnung wurde falsch ausgelesen: %r" % zuordnung)
    # Shinon Gate Selbsttest: Banner, Bullet, Nummerierung und Bildsprache muessen sicher greifen.
    try:
        import importlib.util as _ilu
        import sys as _sys
        _pfad = PROJEKT_STAMM / "shinon" / "shinon_gate.py"
        _spez = _ilu.spec_from_file_location("_shinon_gate_selbsttest", str(_pfad))
        _mod = _ilu.module_from_spec(_spez)
        _sys.modules[_spez.name] = _mod
        _spez.loader.exec_module(_mod)
        _ShinonGate = _mod.ShinonGate
        gate = _ShinonGate()
        if not any(b.code == "E030" for b in gate.pruefe_text("1. Hallo Welt mit fuenf Woertern im Satz.\n===========\n")):
            probleme.append("Shinon Banner Pruefer meldet Banner nicht")
        if not any(b.code == "E031" for b in gate.pruefe_text("- Bullet mit genug Woertern im ganzen Satz.\n")):
            probleme.append("Shinon Bullet Pruefer meldet Bullet nicht")
        if not any(b.code == "E032" for b in gate.pruefe_text("Ohne Nummer aber mit genug Woertern im Satz.\n")):
            probleme.append("Shinon Nummerierung Pruefer meldet fehlende Nummer nicht")
        if not any(b.code == "E033" for b in gate.pruefe_text("1. Kurz.\n")):
            probleme.append("Shinon Bildsprache Pruefer meldet zu kurzen Satz nicht")
        # E035 Readme und E036 Steuerung muessen ebenfalls im Selbsttest greifen.
        _rm_pfad2 = PROJEKT_STAMM / "shinon" / "shinon_readme_pruefer.py"
        _rm_spez2 = _ilu.spec_from_file_location("_shinon_readme_selbsttest", str(_rm_pfad2))
        _rm_mod2 = _ilu.module_from_spec(_rm_spez2)
        _sys.modules[_rm_spez2.name] = _rm_mod2
        _rm_spez2.loader.exec_module(_rm_mod2)
        if not _rm_mod2.ShinonReadmePruefer().pruefen(PROJEKT_STAMM / "__shinon_probe_nicht_existent_readme__.md"):
            probleme.append("Shinon Readme Pruefer meldet fehlende Readme nicht")
        _st_pfad2 = PROJEKT_STAMM / "shinon" / "shinon_steuerung_pruefer.py"
        _st_spez2 = _ilu.spec_from_file_location("_shinon_steuerung_selbsttest", str(_st_pfad2))
        _st_mod2 = _ilu.module_from_spec(_st_spez2)
        _sys.modules[_st_spez2.name] = _st_mod2
        _st_spez2.loader.exec_module(_st_mod2)
        if not _st_mod2.ShinonSteuerungPruefer().pruefen(PROJEKT_STAMM / "__shinon_probe_nicht_existent_steuerung__.json"):
            probleme.append("Shinon Steuerung Pruefer meldet fehlende Steuerung nicht")
    except Exception as lauf_fehler:
        probleme.append(f"Shinon Gate Selbsttest wirft Ausnahme: {lauf_fehler}")
    return probleme


# --------------------------------------------------------------------------
# Prüfkategorie klassen
# --------------------------------------------------------------------------

def pruefe_klassen(dateien):
    klassen_nach_name = {}
    registry_klassen = {}
    for pfad, code in dateien:
        rel_pfad = pfad.relative_to(PROJEKT_STAMM)
        normalisiert = str(rel_pfad).replace("\\", "/")
        name = klassen_name_lesen(code)
        if name is None:
            teile = normalisiert.split("/")
            if "scenes" not in teile and not normalisiert.startswith("tools/"):
                fehler("E004", rel_pfad, zeile_von(code, "extends"),
                       "Skript ohne class_name gefunden")
            continue
        zeile = zeile_von(code, "class_name " + name)
        if name in klassen_nach_name:
            fehler("E002", rel_pfad, zeile,
                   "Doppelter Klassenname '%s' (bereits in %s)" %
                   (name, klassen_nach_name[name][0]))
        klassen_nach_name[name] = (str(rel_pfad), zeile)

        passendes_praefix = None
        for praefix in KATEGORIE_PRAEFIXE:
            if name.startswith(praefix):
                passendes_praefix = praefix
                break
        if passendes_praefix is None:
            fehler("E001", rel_pfad, zeile,
                   "Klasse '%s' trägt kein Kategorie-Präfix (%s)" %
                   (name, ", ".join(sorted(KATEGORIE_PRAEFIXE))))
        elif KATEGORIE_PRAEFIXE[passendes_praefix] is not None:
            erwarteter_ordner = KATEGORIE_PRAEFIXE[passendes_praefix]
            if not normalisiert.startswith(erwarteter_ordner):
                fehler("E003", rel_pfad, zeile,
                       "Klasse '%s' (Präfix %s) liegt nicht im Kategorie-Ordner '%s'" %
                       (name, passendes_praefix, erwarteter_ordner))
        for unzulaessig, code_fehler in ((":", "E008"), (",", "E009")):
            if unzulaessig in name:
                fehler(code_fehler, rel_pfad, zeile,
                       "Klassenname '%s' enthält '%s'; in Godot global unzulässig" %
                       (name, unzulaessig))
        if re.match(r"^[A-Za-z0-9]+_Registry$", name):
            registry_klassen[name] = (rel_pfad, zeile)

    pruefe_aehnliche_klassen(klassen_nach_name)
    pruefe_registry_namen(registry_klassen)
    return klassen_nach_name


def pruefe_aehnliche_klassen(klassen_nach_name):
    normalisierungen = {}
    for name in sorted(klassen_nach_name.keys()):
        schluessel = name.lower().replace("_", "")
        normalisierungen.setdefault(schluessel, []).append(name)
    for gruppe in normalisierungen.values():
        if len(gruppe) > 1:
            erstes = gruppe[0]
            for weiteres in gruppe[1:]:
                ort, zeile = klassen_nach_name[weiteres]
                fehler("E002", ort, zeile,
                       "Klasse '%s' klingt wie '%s' (%s); doppelte Klassennamen sind verboten" %
                       (weiteres, erstes, erstes.lower().replace("_", "")))


def pruefe_registry_namen(registry_klassen):
    # E021: Prefix_Registry ist die Konvention; Prefix_RegistryGruppe darf
    # nur existieren, wenn mindestens eine Prefix_*-Registry ihr zugehört.
    alle_namen = set(registry_klassen.keys())
    for name, (ort, zeile) in registry_klassen.items():
        prefix = name[: -len("_Registry")]
        if prefix.endswith("Gruppe"):
            schema_prefix = prefix[: -len("Gruppe")]
            member = [n for n in alle_namen
                      if n.startswith(schema_prefix + "_")
                      and re.match(r"^[A-Za-z0-9]+_Registry$", n)]
            if not member:
                fehler("E020", ort, zeile,
                       "Registry-Gruppe '%s' besitzt keine Member-Registry " % name +
                       "der Form %s_*_Registry" % schema_prefix)
        else:
            continue


# --------------------------------------------------------------------------
# Prüfkategorie trennung
# --------------------------------------------------------------------------

def pruefe_trennung(dateien):
    for pfad, code in dateien:
        rel_pfad = pfad.relative_to(PROJEKT_STAMM)
        name = klassen_name_lesen(code) or str(rel_pfad)
        hat_arrays = re.search(r"^var\s+\w+\s*:\s*Array\[", code, re.M) is not None
        if not hat_arrays:
            continue
        if "## Kategorie daten" not in code:
            fehler("E006", rel_pfad, 1,
                   "Klasse '%s' enthält Daten-Arrays, markiert die Trennung " % name +
                   "aber nicht mit '## Kategorie daten'")
        if "## Kategorie logik" not in code:
            fehler("E007", rel_pfad, 1,
                   "Klasse '%s' enthält Daten-Arrays, markiert die logische " % name +
                   "Seite aber nicht mit '## Kategorie logik'")
        for treffer in re.finditer(r":\s*Array\[([A-Za-z_][A-Za-z0-9_]*)\]", code):
            element_typ = treffer.group(1)
            if element_typ in ARRAY_BASISTYPEN:
                continue
            if element_typ not in ALLE_KLASSEN:
                fehler("E010", rel_pfad, zeile_bei(code, treffer.start()),
                       "Array-Typ '%s' ist keine bekannte Datenklasse" % element_typ)


# --------------------------------------------------------------------------
# Prüfkategorie daten: exakte Ausgabe der Datenobjekt-Erzeugung (E011)
# --------------------------------------------------------------------------

def gib_dateninventar_aus(dateien):
    print("=" * 78)
    print("DATENINVENTAR (exakte Namen der erzeugten Datenobjekte je Datei)")
    print("=" * 78)
    daten_praefixe = ("Objekt_", "Resources_", "Resource_", "Tier_")
    gefunden = False
    for pfad, code in dateien:
        rel_pfad = pfad.relative_to(PROJEKT_STAMM)
        erzeugungen = []
        for treffer in re.finditer(r"\b([A-Z][A-Za-z_][A-Za-z0-9_]*)\.new\(\)", code):
            if treffer.group(1).startswith(daten_praefixe):
                erzeugungen.append((treffer.group(1), zeile_bei(code, treffer.start())))
        if not erzeugungen:
            continue
        gefunden = True
        name = klassen_name_lesen(code) or "-"
        print("%s (Klasse %s):" % (rel_pfad, name))
        for klasse, zeile in erzeugungen:
            print("    Zeile %4d: %s.new()  ->  Datenobjekt %s" % (zeile, klasse, klasse))
    if not gefunden:
        print("keine Datenobjekt-Erzeugungen gefunden")
    print("=" * 78)


# --------------------------------------------------------------------------
# Prüfkategorie determinismus
# --------------------------------------------------------------------------

def pruefe_determinismus(dateien):
    for pfad, code in dateien:
        rel_pfad = pfad.relative_to(PROJEKT_STAMM)
        name = klassen_name_lesen(code) or ""
        for treffer in _sammle_zufallsfundstellen(code, name):
            fehler("E012", rel_pfad, zeile_bei(code, treffer.start()),
                   "Verbotener Zufallsaufruf '%s' in '%s'; Zufall läuft nur in "
                   "Kern_Zufall innerhalb einer Mutation und wird als Zustand "
                   "festgehalten" % (treffer.group(0).strip(), name or rel_pfad))
        if "extends Kern_Mutationsschema" in code:
            if "start_zustand" not in code:
                fehler("E014", rel_pfad, zeile_von(code, "class_name"),
                       "Mutationsschema '%s' legt keine Startzustände fest; ohne "
                       "Startzustand läuft keine Mutation" % name)
            pruefe_matrix_zuordnung(pfad, rel_pfad, code, name)


def pruefe_matrix_zuordnung(pfad, rel_pfad, code, schema_name):
    matrix_pfad_treffer = re.search(r'MATRIX_PFAD\s*:?=\s*"res://([^"]+)"', code)
    if matrix_pfad_treffer is None:
        return
    matrix_datei = PROJEKT_STAMM / matrix_pfad_treffer.group(1)
    if not matrix_datei.is_file():
        fehler("E019", rel_pfad, zeile_von(code, "MATRIX_PFAD"),
               "Mutationsmatrix '%s' fehlt auf der Festplatte" % matrix_pfad_treffer.group(1))
        return
    try:
        gelesen = matrix_datei.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        fehler("E019", rel_pfad, zeile_von(code, "MATRIX_PFAD"),
               "Mutationsmatrix '%s' ist nicht als UTF-8 lesbar" % matrix_pfad_treffer.group(1))
        return
    zuordnung_in_code = _matrix_zuordnung_aus_code(code)
    klassen_im_ordner = set()
    for nachbar in pfad.parent.glob("*.gd"):
        try:
            klassen_im_ordner.add(klassen_name_lesen(nachbar.read_text(encoding="utf-8")))
        except OSError:
            continue
    klassen_im_ordner.discard(None)
    for mut_name, klasse in sorted(zuordnung_in_code.items()):
        if klasse not in klassen_im_ordner:
            fehler("E013", rel_pfad, zeile_von(code, '"%s"' % mut_name),
                   "Schema '%s': Mutation '%s' ist der Klasse '%s' zugeordnet, "
                   "aber es gibt keine solche Mutations-Klasse im selben Ordner" %
                   (schema_name, mut_name, klasse))


# --------------------------------------------------------------------------
# Prüfkategorie pfade: alle res://-Einträge müssen relativ und existent sein
# --------------------------------------------------------------------------

PFAD_ZIEL_ENDUNGEN = (".svg", ".png", ".json", ".tscn", ".gd", ".ogg",
                      ".wav", ".mp3", ".ttf", ".otf", ".tres")


def pruefe_pfade(dateien):
    for pfad, code in dateien:
        rel_pfad = pfad.relative_to(PROJEKT_STAMM)
        for treffer in re.finditer(r'"(res://[^"]+)"', code):
            pruefe_res_pfad(treffer.group(1), rel_pfad, code, treffer.start())
    for tscn_pfad in sorted(PROJEKT_STAMM.rglob("*.tscn")):
        rel_pfad = tscn_pfad.relative_to(PROJEKT_STAMM)
        try:
            inhalt = tscn_pfad.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            fehler("E005", rel_pfad, 1, "Szenendatei ist nicht als UTF-8 lesbar")
            continue
        for treffer in re.finditer(r'path="(res://[^"]+)"', inhalt):
            pruefe_res_pfad(treffer.group(1), rel_pfad, inhalt, treffer.start())
    for json_pfad in sorted(PROJEKT_STAMM.rglob("*.json")):
        if ".godot" in json_pfad.parts:
            continue
        rel_pfad = json_pfad.relative_to(PROJEKT_STAMM)
        try:
            inhalt = json_pfad.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for treffer in re.finditer(r'"([^"]*\.(?:svg|png|json|tscn|ogg|wav))"', inhalt):
            wert = treffer.group(1)
            if wert.startswith("res://"):
                pruefe_res_pfad(wert, rel_pfad, inhalt, treffer.start())
            else:
                fehler("E015", rel_pfad, zeile_bei(inhalt, treffer.start()),
                       "Pfad-Eintrag '%s' ist nicht projektrelativ im Format res://" % wert)


def pruefe_res_pfad(pfad_angabe, rel_pfad, code, position):
    zeile = zeile_bei(code, position)
    if not pfad_angabe.startswith("res://"):
        fehler("E015", rel_pfad, zeile,
               "Pfad-Eintrag '%s' ist nicht projektrelativ im Format res://" % pfad_angabe)
        return
    relativ = pfad_angabe[len("res://"):]
    ziel = PROJEKT_STAMM / relativ
    if not ziel.is_file():
        fehler("E015", rel_pfad, zeile,
               "Pfad-Eintrag '%s' existiert nicht" % pfad_angabe)


# --------------------------------------------------------------------------
# Prüfkategorie registries
# --------------------------------------------------------------------------

ASSET_SCHLUESSEL = ("textur_pfad", "sheet_pfad", "icon_pfad", "asset")


def _json_asset_vorhanden(wert: str) -> bool:
    if not wert.startswith("res://"):
        return False
    return (PROJEKT_STAMM / wert[len("res://"):]).is_file()


def _eintrag_hat_asset(wort: dict) -> bool:
    for schluessel in ASSET_SCHLUESSEL:
        wert = str(wort.get(schluessel, ""))
        if wert != "" and _json_asset_vorhanden(wert):
            return True
    return False


def pruefe_registries(dateien):
    # E022: Preflight-Gate — jede Registry, die Objekte oder Tiere hält, muss
    # je Eintrag auf ein gültiges Asset zeigen (res://*.svg/.png/.tres).
    # Ohne Asset ist der Eintrag im Generator ungültig. Fehlt die SVG, wird
    # zur Laufzeit ein Platzhalter erzeugt (Kern_AssetPruefer), im Preflight
    # aber als E022 gemeldet, damit der fehlende Grafik-Baustein bewusst
    # ergänzt wird. Kern_-Registries (reine Logik/Modifikatoren) sind vom
    # Asset-Zwang ausgenommen.
    for pfad, code in dateien:
        rel_pfad = pfad.relative_to(PROJEKT_STAMM)
        name = klassen_name_lesen(code) or ""
        if not re.match(r"^[A-Za-z0-9]+_Registry", name):
            continue
        quellen = re.findall(r'"res://([^"]+\.json)"', code)
        if not quellen:
            continue
        for quelle_rel in quellen:
            quelle_text = f'"res://{quelle_rel}"'
            treffer = re.search(re.escape(quelle_text), code)
            if treffer is None:
                treffer = re.search(r'"res://[^"]+\.json"', code)
            if treffer is None:
                continue
            quelle_datei = PROJEKT_STAMM / quelle_rel
            if not quelle_datei.is_file():
                fehler("E019", rel_pfad, zeile_bei(code, treffer.start()),
                       "Registry '%s': Quelle '%s' fehlt" % (name, quelle_rel))
                continue
            try:
                inhalt = quelle_datei.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                fehler("E019", rel_pfad, zeile_bei(code, treffer.start()),
                       "Registry '%s': Quelle '%s' ist nicht als UTF-8 lesbar" %
                       (name, quelle_rel))
                continue
            import json as _json
            try:
                daten = _json.loads(inhalt)
            except ValueError as lauf_fehler:
                fehler("E019", rel_pfad, zeile_bei(code, treffer.start()),
                       "Registry '%s': Quelle '%s' ist kein gültiges JSON (%s)" %
                       (name, quelle_rel, lauf_fehler))
                continue
            if name.startswith("Tier_") and not isinstance(daten, dict):
                fehler("E019", rel_pfad, zeile_bei(code, treffer.start()),
                       "Registry '%s': Quelle '%s' muss ein Objekt mit Tierarten sein" %
                       (name, quelle_rel))
            if name.startswith(("Objekt_", "Natur_", "Gebaeude_", "Welt_")) and not isinstance(daten, list):
                fehler("E019", rel_pfad, zeile_bei(code, treffer.start()),
                       "Registry '%s': Quelle '%s' muss eine Liste von Katalog-Einträgen sein" %
                       (name, quelle_rel))
            asset_pflicht = not name.startswith("Kern_")
            if isinstance(daten, list) and asset_pflicht:
                ids = [str(eintrag.get("id")) for eintrag in daten
                       if isinstance(eintrag, dict) and "id" in eintrag]
                doppelt = sorted({eintrag for eintrag in ids if ids.count(eintrag) > 1})
                if doppelt:
                    fehler("E019", rel_pfad, zeile_bei(code, treffer.start()),
                           "Registry '%s': Quelle '%s' enthält doppelte ids: %s" %
                           (name, quelle_rel, ", ".join(doppelt)))
                for eintrag in daten:
                    if not isinstance(eintrag, dict):
                        continue
                    eintrag_id = str(eintrag.get("id", "?"))
                    if not _eintrag_hat_asset(eintrag):
                        fehler("E022", rel_pfad, zeile_bei(code, treffer.start()),
                               "Registry '%s': Eintrag '%s' in '%s' zeigt auf kein gültiges Asset (res://*.svg/.png); "
                               "im Generator ungültig — SVG ergänzen oder Platzhalter erzeugen lassen (core/assets/platzhalter.svg)" %
                               (name, eintrag_id, quelle_rel))
            elif isinstance(daten, list):
                ids = [str(eintrag.get("id")) for eintrag in daten
                       if isinstance(eintrag, dict) and "id" in eintrag]
                doppelt = sorted({eintrag for eintrag in ids if ids.count(eintrag) > 1})
                if doppelt:
                    fehler("E019", rel_pfad, zeile_bei(code, treffer.start()),
                           "Registry '%s': Quelle '%s' enthält doppelte ids: %s" %
                           (name, quelle_rel, ", ".join(doppelt)))
            if isinstance(daten, dict) and asset_pflicht:
                for eintrag_id, eintrag in daten.items():
                    if not isinstance(eintrag, dict):
                        continue
                    if not _eintrag_hat_asset(eintrag):
                        fehler("E022", rel_pfad, zeile_bei(code, treffer.start()),
                               "Registry '%s': Eintrag '%s' in '%s' zeigt auf kein gültiges Asset (res://*.svg/.png); "
                               "im Generator ungültig — SVG ergänzen oder Platzhalter erzeugen lassen (core/assets/platzhalter.svg)" %
                               (name, eintrag_id, quelle_rel))


# --------------------------------------------------------------------------
# Prüfkategorie pyramide + biome: Einheitlichkeit der RT Pyramide
# --------------------------------------------------------------------------

def pruefe_pyramide(dateien):
    # E023: Keine doppelte faktor -> ticks Berechnung.
    # Erlaubt ist nur Kern_Weltuhr.ticks_aus_faktor oder Delegation dorthin.
    # Jede andere Formel mit TICK_RATE_HZ und 10.0 gilt als Duplikat.
    tainted: list[tuple] = []
    for pfad, code in dateien:
        rel = pfad.relative_to(PROJEKT_STAMM)
        normalisiert = str(rel).replace("\\", "/")
        if normalisiert == "core/weltuhr.gd":
            continue
        if "ticks_aus_faktor" in code and "Kern_Weltuhr.ticks_aus_faktor" in code:
            # Reine Delegation ist erlaubt, keine eigene Formel daneben.
            if re.search(r"TICK_RATE_HZ\s*\*|\*\s*10\.0|clampf\s*\(\s*faktor", code) and "Kern_Weltuhr" not in re.search(r".*TICK_RATE_HZ.*", code).group(0) if re.search(r"TICK_RATE_HZ", code) else False:
                pass
        # Hart: Eigene Formel mit TICK_RATE_HZ und Faktor Skalierung außerhalb der Weltuhr.
        if re.search(r"Kern_Weltuhr\.TICK_RATE_HZ", code) and "Kern_Weltuhr.ticks_aus_faktor" not in code:
            for treffer in re.finditer(r"Kern_Weltuhr\.TICK_RATE_HZ", code):
                zeile = code[max(0, treffer.start() - 80):treffer.end() + 40]
                if "ticks_aus_faktor" not in zeile:
                    tainted.append((rel, zeile_bei(code, treffer.start())))
    for rel, zeile in tainted:
        fehler("E023", rel, zeile,
               "RT Pyramide: Eigene ticks Berechnung mit TICK_RATE_HZ ausserhalb von Kern_Weltuhr.ticks_aus_faktor. Nur die Weltuhr rechnet zentral, alle anderen delegieren.")
    # E024: Biome muessen als Mutation wirken.
    hat_biom_registry = any("Welt_BiomRegistry" in c for _, c in dateien)
    hat_biom_mutation = any("Welt_BiomMutation" in c for _, c in dateien)
    if not hat_biom_registry or not hat_biom_mutation:
        fehler("E024", "world/data/biome.json", 1,
               "Biom Pflicht: Biome muessen als Welt_BiomRegistry und Welt_BiomMutation als Mutationsmaschine existieren und nur als Zustand wirken.")
    else:
        biom_json = PROJEKT_STAMM / "world" / "data" / "biome.json"
        if not biom_json.is_file():
            fehler("E024", "world/data/biome.json", 1, "Biom Pflicht: Datei world/data/biome.json fehlt.")
    # E023: System Trennung — Tier_Status darf keine hart codierte Tier-ID Weiche enthalten.
    for pfad, code in dateien:
        rel = pfad.relative_to(PROJEKT_STAMM)
        if "tier_status" in str(rel).lower() and '"baer"' in code and "match" in code.lower():
            if 'tier_id == "baer"' in code or "tier_id == 'baer'" in code:
                fehler("E023", rel, zeile_von(code, '"baer"'),
                       "RT Pyramide: Tier_Status enthaelt hart codierte Tier-ID Weiche. Trigger und Folgezustand muessen rein aus Registry ausloeser und logik_id kommen.")


# --------------------------------------------------------------------------
# Prüfkategorie shinon: Root Gate shinon/commit_msg.txt mechanisch
# --------------------------------------------------------------------------

def pruefe_shinon():
    try:
        import importlib.util as _ilu2
        import sys as _sys2
        _pfad2 = PROJEKT_STAMM / "shinon" / "shinon_gate.py"
        _spez2 = _ilu2.spec_from_file_location("_shinon_gate_lauf", str(_pfad2))
        _mod2 = _ilu2.module_from_spec(_spez2)
        _sys2.modules[_spez2.name] = _mod2
        _spez2.loader.exec_module(_mod2)
        ShinonGate = _mod2.ShinonGate
    except Exception as lauf_fehler:
        fehler("E000", "shinon/shinon_gate.py", 1,
               f"Shinon Gate nicht importierbar: {lauf_fehler}")
        return
    gate = ShinonGate()
    for befund in gate.pruefen():
        fehler(befund.code, befund.datei, befund.zeile, befund.text)
    # E035 und E036 werden ebenfalls ueber das shinon Modul geprueft, granular je Klasse.
    try:
        _rm_pfad = PROJEKT_STAMM / "shinon" / "shinon_readme_pruefer.py"
        _rm_spez = _ilu2.spec_from_file_location("_shinon_readme_lauf", str(_rm_pfad))
        _rm_mod = _ilu2.module_from_spec(_rm_spez)
        _sys2.modules[_rm_spez.name] = _rm_mod
        _rm_spez.loader.exec_module(_rm_mod)
        for befund in _rm_mod.ShinonReadmePruefer().pruefen():
            fehler(befund.code, befund.datei, befund.zeile, befund.text)
    except Exception as lauf_fehler:
        fehler("E000", "shinon/shinon_readme_pruefer.py", 1,
               f"Shinon Readme Pruefer nicht importierbar: {lauf_fehler}")
    try:
        _st_pfad = PROJEKT_STAMM / "shinon" / "shinon_steuerung_pruefer.py"
        _st_spez = _ilu2.spec_from_file_location("_shinon_steuerung_lauf", str(_st_pfad))
        _st_mod = _ilu2.module_from_spec(_st_spez)
        _sys2.modules[_st_spez.name] = _st_mod
        _st_spez.loader.exec_module(_st_mod)
        for befund in _st_mod.ShinonSteuerungPruefer().pruefen():
            fehler(befund.code, befund.datei, befund.zeile, befund.text)
    except Exception as lauf_fehler:
        fehler("E000", "shinon/shinon_steuerung_pruefer.py", 1,
               f"Shinon Steuerung Pruefer nicht importierbar: {lauf_fehler}")


# --------------------------------------------------------------------------
# Prüfkategorie godot
# --------------------------------------------------------------------------

def godot_lauf(godot_befehl):
    if shutil.which(godot_befehl) is None:
        fehler("E018", "godot", 0,
               "Godot wurde als '%s' nicht gefunden; --godot-befehl verwenden" % godot_befehl)
        return
    befehl = [godot_befehl, "--headless", "--path", str(PROJEKT_STAMM), "--quit-after", "120"]
    try:
        ergebnis = subprocess.run(befehl, capture_output=True, text=True,
                                  encoding="utf-8", errors="replace", timeout=300)
    except subprocess.TimeoutExpired:
        fehler("E018", "godot", 0, "Godot-Lauf hat das Zeitlimit von 300 Sekunden überschritten")
        return
    ausgabe = (ergebnis.stdout or "") + (ergebnis.stderr or "")
    fundzeilen = []
    for zeile in ausgabe.splitlines():
        zugehoerig = zeile.strip()
        if any(muster in zugehoerig for muster in GODOT_FEHLER_MUSTER):
            if zugehoerig not in fundzeilen:
                fundzeilen.append(zugehoerig)
    for zeile in fundzeilen:
        if "Parse Error" in zeile or "SCRIPT ERROR" in zeile:
            fehler("E016", "godot", 0, zeile)
        elif any(muster in zeile for muster in ("Could not find", "not declared",
                                                "Cannot infer", "Could not resolve",
                                                "Could not parse", "Attempt to open script",
                                                "unknown")):
            fehler("E017", "godot", 0, zeile)
        else:
            fehler("E018", "godot", 0, zeile)


# --------------------------------------------------------------------------
# Hauptprogramm
# --------------------------------------------------------------------------

ALLE_KLASSEN = set()


def hauptprogramm():
    global ALLE_KLASSEN
    parser = argparse.ArgumentParser(description="Preflight des Projekts")
    parser.add_argument("--kategorie", action="append", default=[],
                        help="nur diese Prüfkategorie ausführen (%s)" %
                             ", ".join(sorted(PRUEFKATEGORIEN)))
    parser.add_argument("--ohne-godot", action="store_true",
                        help="Godot-Lauf überspringen")
    parser.add_argument("--godot-befehl", default="godot",
                        help="Befehl oder Pfad der Godot-Engine (Standard: godot)")
    argumente = parser.parse_args()

    unbekannt = [k for k in argumente.kategorie if k.lower() not in PRUEFKATEGORIEN]
    if unbekannt:
        print("E000: unbekannte Prüfkategorie(n): %s; erlaubt: %s" %
              (", ".join(unbekannt), ", ".join(sorted(PRUEFKATEGORIEN))))
        return 2
    gewaehlt = {k.lower() for k in argumente.kategorie} or set(PRUEFKATEGORIEN)
    aktive_codes = {code for kategorie in gewaehlt
                    for code in PRUEFKATEGORIEN[kategorie]}
    godot_aktiv = "godot" in gewaehlt and not argumente.ohne_godot

    print("Prüfkategorien: %s" % ", ".join(sorted(gewaehlt)))
    probleme = selbsttest()
    if probleme:
        print("E000: Preflight-Selbsttest fehlgeschlagen:")
        for problem in probleme:
            print("  - %s" % problem)
        return 2
    print("E000: Selbsttest bestanden (keine False Truth)")

    dateien = lies_dateien()
    ALLE_KLASSEN = {klassen_name_lesen(code) for _, code in dateien}
    ALLE_KLASSEN.discard(None)

    if "klassen" in gewaehlt:
        pruefe_klassen(dateien)
    if "trennung" in gewaehlt:
        pruefe_trennung(dateien)
    if "determinismus" in gewaehlt:
        pruefe_determinismus(dateien)
    if "pfade" in gewaehlt:
        pruefe_pfade(dateien)
    if "registries" in gewaehlt:
        pruefe_registries(dateien)
    if "shinon" in gewaehlt:
        pruefe_shinon()
    if "pyramide" in gewaehlt or "biome" in gewaehlt or "einheitlich" in gewaehlt:
        pruefe_pyramide(dateien)
    if godot_aktiv:
        godot_lauf(argumente.godot_befehl)

    if "daten" in gewaehlt:
        gib_dateninventar_aus(dateien)

    gefiltert = [eintrag for eintrag in FEHLER if eintrag[0] in aktive_codes]
    print("Klassen gesamt: %d; GDScript-Dateien: %d" % (len(ALLE_KLASSEN), len(dateien)))
    if "shinon" in gewaehlt and any(eintrag[0].startswith("E03") for eintrag in gefiltert):
        print("SHINON GATE: blockiert — shinon/commit_msg.txt verletzt E030 bis E034.")
        print("Regel: Ganze nummerierte bildliche Saetze ohne Banner und ohne Bullet. Siehe AGENTS.md Regel 5.")
    if gefiltert:
        print("BEFUNDE (%d):" % len(gefiltert))
        for code, datei, zeile, text in sorted(gefiltert):
            print("  %s | %s:%s | %s" % (code, datei, zeile, text))
        return 1
    print("PREFLIGHT OK: keine Befunde in den gewählten Kategorien")
    return 0


if __name__ == "__main__":
    sys.exit(hauptprogramm())
