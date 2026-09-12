# -*- coding: utf-8 -*-
"""Prüfkategorie registries (E019, E020, E022): Registry-Quellen müssen
existieren, gültiges JSON tragen und auf echte Assets zeigen."""

import json as _json
import re

from .kern import PROJEKT_STAMM, fehler, zeile_bei, klassen_name_lesen

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
            asset_pflicht = not name.startswith(("Kern_", "Orchestrator_"))
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
            # Reine Logik-Registry ohne Asset-Pflicht: keine E022.
