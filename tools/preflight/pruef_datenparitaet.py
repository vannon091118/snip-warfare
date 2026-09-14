# -*- coding: utf-8 -*-
"""Prüfkategorie datenparitaet (E040): Dünner Aufrufer über Sammler."""

import re

from .kern import PROJEKT_STAMM, fehler
from .schwellwert_sammler import sammle_json_schwellwerte


def _sammle_json_schwellwerte():
    return sammle_json_schwellwerte()


def pruefe_datenparitaet(dateien) -> None:
    """E040: Harte Schwellen, die Pool-Werte duplizieren, blockieren."""
    json_werte, wert_keywords = _sammle_json_schwellwerte()
    if not json_werte:
        return
    zu_pruefen = set(json_werte.keys())
    fallback_muster = re.compile(r"RUECKFALL|Fallback|fallback|default|Notfall", re.I)
    delegations_muster = re.compile(r"_schwellwert_von|takt_minuten|tag_minuten|nacht_minuten|verbrauch_je_takt|ticks_aus_minuten|ticks_aus_faktor|mod_fuer|schwellwert")
    lit_muster = re.compile(r"(?<![A-Za-z0-9_\"])(-?\d+(?:\.\d+)?)(?![A-Za-z0-9_\"])")
    for pfad, code in dateien:
        rel = str(pfad.relative_to(PROJEKT_STAMM)).replace("\\", "/")
        if rel.startswith("tools/") or rel.startswith("addons/"):
            continue
        if not rel.endswith(".gd"):
            continue
        zeilen = code.splitlines()
        for idx, zeile in enumerate(zeilen, start=1):
            if zeile.lstrip().startswith("#"):
                continue
            bereinigt = re.sub(r'"[^"]*"', '""', zeile)
            bereinigt = re.sub(r"'[^']*'", "''", bereinigt)
            for m in lit_muster.finditer(bereinigt):
                raw = m.group(1)
                try:
                    wert = float(raw)
                except ValueError:
                    continue
                if wert not in zu_pruefen:
                    continue
                kws = wert_keywords.get(wert, set())
                kontext_text = zeile.lower()
                if idx > 1:
                    kontext_text = (zeilen[idx - 2] + "\n" + zeile).lower()
                if kws and not any(kw in kontext_text for kw in kws):
                    continue
                if fallback_muster.search(kontext_text):
                    continue
                if delegations_muster.search(zeile):
                    continue
                quellen = "; ".join(json_werte[wert][:2])
                fehler("E040", rel, idx, f"Hart codierter Wert {raw} dupliziert Pool ({quellen}); Registry lesen oder RUECKFALL markieren.")
