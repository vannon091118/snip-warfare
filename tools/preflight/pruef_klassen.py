# -*- coding: utf-8 -*-
"""Prüfkategorie klassen (E001 bis E009, E021): Naming, Präfix, Ordner,
Doppelte und ähnlich klingende Klassennamen, Registry-Namensschema."""

import re

from .kern import (PROJEKT_STAMM, KATEGORIE_PRAEFIXE, fehler, zeile_von,
                   klassen_name_lesen)


def pruefe_klassen(dateien):
    klassen_nach_name = {}
    registry_klassen = {}
    for pfad, code in dateien:
        rel_pfad = pfad.relative_to(PROJEKT_STAMM)
        normalisiert = str(rel_pfad).replace("\\", "/")
        name = klassen_name_lesen(code)
        if name is None:
            teile = normalisiert.split("/")
            if "scenes" not in teile and not normalisiert.startswith("tools/") and "/events/" not in normalisiert:
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

    _pruefe_aehnliche_klassen(klassen_nach_name)
    _pruefe_registry_namen(registry_klassen)
    return klassen_nach_name


def _pruefe_aehnliche_klassen(klassen_nach_name):
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


def _pruefe_registry_namen(registry_klassen):
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
