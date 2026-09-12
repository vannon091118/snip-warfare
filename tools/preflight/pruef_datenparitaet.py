# -*- coding: utf-8 -*-
"""Prüfkategorie datenparitaet (E040): harte Schwellen, die einen Pool-Wert
duplizieren, werden mechanisch erkannt und blockieren."""

import json as _json
import re

from .kern import PROJEKT_STAMM, fehler


def _sammle_json_schwellwerte():
    """Liest alle Pools und sammelt Schwellwerte.

    Rückgabe: { wert_float: ["population/data/mood_modifikatoren.json:kaelte/schwellwert", ...] }.
    Nur Felder, die als Konfigurations-Schwelle gelten, werden verfolgt —
    reine Mengen/Geometrie bleiben ausserhalb. Fail-open: unlesbares JSON
    wird ignoriert, E019 meldet es ohnehin.
    """
    # Enge Auswahl: Nur echte Schwell- und Rhythmus-Schluessel, die eine zweite
    # Wahrheit im Code erzeugen wuerden. Faktoren wie 0/1 oder Geometrie wie
    # frame_breite/gewicht bleiben bewusst draussen, sonst ertrinkt das Gate
    # im Rauschen (siehe Inventur G3/G4).
    schluesel_mengen = {"schwellwert", "verbrauch_je_takt", "takt_minuten", "tag_minuten", "nacht_minuten"}
    # Zu jedem Schluessel gehoert ein semantisches Keyword-Set, damit nur
    # Zeilen im passenden fachlichen Kontext als Duplikat gelten — sonst
    # wuerde jede 3 oder 0.8 im ganzen Projekt als Schwelle zaehlen.
    schluessel_keywords = {
        "schwellwert": ["schwellwert", "schwelle", "kaelte", "hitze", "hunger", "waerme", "nahrung"],
        "verbrauch_je_takt": ["verbrauch", "je_takt", "verteilung", "takt", "nahrung"],
        "takt_minuten": ["takt_minuten", "takt", "rhythmus", "weltrhythmus"],
        "tag_minuten": ["tag_minuten", "tag", "rhythmus", "weltrhythmus"],
        "nacht_minuten": ["nacht_minuten", "nacht", "rhythmus", "weltrhythmus"],
    }
    ergebnis = {}
    wert_keywords = {}
    for p in sorted(PROJEKT_STAMM.rglob("*.json")):
        if ".godot" in p.parts or "addons" in p.parts:
            continue
        try:
            inhalt = p.read_text(encoding="utf-8")
            daten = _json.loads(inhalt)
        except Exception:
            continue
        rel = str(p.relative_to(PROJEKT_STAMM)).replace("\\", "/")

        def walk(v, pfad):
            if isinstance(v, dict):
                for k, val in v.items():
                    walk(val, pfad + [str(k)])
            elif isinstance(v, list):
                for i, val in enumerate(v):
                    walk(val, pfad + [str(i)])
            elif isinstance(v, (int, float)) and not isinstance(v, bool):
                if pfad and pfad[-1] in schluesel_mengen:
                    fv = float(v)
                    if any(seg.startswith("_dokumentation") for seg in pfad):
                        return
                    if fv == 0.0:
                        return
                    ergebnis.setdefault(fv, []).append(f"{rel}:{'/'.join(pfad)}")
                    # Sammle Keywords fuer diesen Wert ueber alle Quellen.
                    kws = schluessel_keywords.get(pfad[-1], [])
                    wert_keywords.setdefault(fv, set()).update(k.lower() for k in kws)
        walk(daten, [])
    return ergebnis, wert_keywords


def pruefe_datenparitaet(dateien) -> None:
    """E040: Mechanisch erkennt harte Schwellen, die einen Pool-Wert duplizieren.

    Jede Zahl, die in einem Pool als Schwellwert/Rhythmus steht,
    darf im Code nur noch als Fallback vorkommen — signalisiert durch
    einen Kommentar mit dem Stichwort RUECKFALL/Fallback/Notfall/default
    auf derselben Zeile oder der Zeile darueber — oder als erlaubter
    delegierter Lese-Pfad (`_schwellwert_von`, `takt_minuten()`, `ticks_aus_minuten`,
    `ticks_aus_faktor`, `mod_fuer`, `schwellwert`). Alles andere ist eine
    zweite Wahrheit. Werte wie 0/1 werden hier nicht verfolgt, um Rauschen
    zu vermeiden. Erlaubte Ausnahmen: `tools/` und `addons/` werden nicht
    geprueft. Ein Treffer gilt nur, wenn die Zeile (oder Vorzeile) den
    fachlichen Kontext des Schluessels enthaelt — sonst waere jede 3 im
    Projekt eine vermeintliche Schwelle.
    """
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
                # Kontext-Pruefung: Zeile muss den fachlichen Kontext des Wertes tragen.
                kws = wert_keywords.get(wert, set())
                kontext_text = zeile.lower()
                if idx > 1:
                    kontext_text = (zeilen[idx - 2] + "\n" + zeile).lower()
                if kws and not any(kw in kontext_text for kw in kws):
                    continue
                # Erlaubte Fallback-Signatur.
                if fallback_muster.search(kontext_text):
                    continue
                if delegations_muster.search(zeile):
                    continue
                quellen = "; ".join(json_werte[wert][:2])
                fehler("E040", rel, idx,
                       f"Hart codierter Zahlenwert {raw} dupliziert einen Pool-Wert ({quellen}); stattdessen Registry lesen (z. B. Pop_MoodModifikatorRegistry/_schwellwert_von oder Pop_NeedRegistry.takt_minuten/ticks_aus_minuten) oder als RUECKFALL markieren.")
