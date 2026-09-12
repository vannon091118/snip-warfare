# -*- coding: utf-8 -*-
"""Prüfkategorie pyramide und biome (E023, E024): Einheitlichkeit der
RT Pyramide, zentrale Ticks-Rechnung und Biom-Mutationspflicht."""

import re

from .kern import PROJEKT_STAMM, fehler, zeile_von


def pruefe_pyramide(dateien):
    # E023: Keine doppelte faktor -> ticks Berechnung.
    # Erlaubt ist nur Kern_Weltuhr.ticks_aus_faktor oder Delegation dorthin.
    tainted = []
    for pfad, code in dateien:
        rel = pfad.relative_to(PROJEKT_STAMM)
        normalisiert = str(rel).replace("\\", "/")
        if normalisiert == "core/logic/clock/weltuhr.gd":
            continue
        # Hart: Eigene Formel mit TICK_RATE_HZ und Faktor Skalierung außerhalb der Weltuhr.
        if re.search(r"Kern_Weltuhr\.TICK_RATE_HZ", code) and "Kern_Weltuhr.ticks_aus_faktor" not in code:
            for treffer in re.finditer(r"Kern_Weltuhr\.TICK_RATE_HZ", code):
                zeile = code[max(0, treffer.start() - 80):treffer.end() + 40]
                if "ticks_aus_faktor" not in zeile:
                    tainted.append((rel, zeile_bei_helfer(code, treffer.start())))
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


def zeile_bei_helfer(code, position):
    return code.count("\n", 0, position) + 1
