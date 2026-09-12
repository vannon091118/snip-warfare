# -*- coding: utf-8 -*-
"""Erzeugt das Klasseninventar fuer INDEX.md: scannt class_name je Domaene.

Niemals AGENTS.md ueberschreiben. Schreibt nur den Inventar-Abschnitt von
INDEX.md neu, alles davor bleibt Handpflege. Idempotent und ohne Seiteneffekte.
"""

import re
import sys
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent
INDEX_PFAD = PROJEKT_STAMM / "INDEX.md"

DOMAENEN = [
    ("core", "Kern_", "core/"),
    ("world/generator", "Welt_", "world/logic/kategorie_generator/"),
    ("world/welt", "Welt_", "world/logic/kategorie_welt/"),
    ("world/objekt", "Objekt_/Gebaeude_", "world/logic/kategorie_objekt/"),
    ("world/tier", "Tier_", "world/logic/kategorie_tier/"),
    ("world/orchestrator", "Orchestrator_", "world/logic/kategorie_orchestrator/"),
    ("game/einheit", "Einheit_", "game/logic/kategorie_einheit/"),
    ("game/job", "Job_", "game/logic/kategorie_job/"),
    ("game/ressourcen", "Resource_", "game/logic/kategorie_ressourcen/"),
    ("population", "Pop_", "population/"),
    ("economy", "Lager_", "economy/"),
    ("ui", "Ui_", "ui/"),
    ("shinon", "Shinon_", "shinon/"),
    ("tools", "-", "tools/"),
]

MARKER_START = "<!-- INVENTAR:START -->"
MARKER_ENDE = "<!-- INVENTAR:ENDE -->"


def inventar_sammeln() -> dict:
    inventar: dict[str, list[tuple[str, str]]] = {}
    for domain, _praefix, ordner in DOMAENEN:
        inventar[domain] = []
        pfad = PROJEKT_STAMM / ordner
        if not pfad.exists():
            continue
        for gd in sorted(pfad.rglob("*.gd")):
            try:
                text = gd.read_text(encoding="utf-8")
            except Exception:
                continue
            treffer = re.search(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", text, re.M)
            if treffer:
                relativ = str(gd.relative_to(PROJEKT_STAMM)).replace("\\", "/")
                inventar[domain].append((treffer.group(1), relativ))
    return inventar


def inventar_text(inventar: dict) -> str:
    zeilen = [MARKER_START, "", "## 4. Klasseninventar (auto-generiert)", "", "_Quelle: `python tools/index_generieren.py` — scannt `class_name` je Domaene._", ""]
    gesamt = sum(len(v) for v in inventar.values())
    zeilen.append(f"_Stand: {gesamt} Klassen mit `class_name` in {len(inventar)} Domaenen._")
    zeilen.append("")
    for domain, praefix, ordner in DOMAENEN:
        eintraege = inventar.get(domain, [])
        zeilen.append(f"### {domain} — Prefix `{praefix}` — `{ordner}` ({len(eintraege)})")
        zeilen.append("")
        if not eintraege:
            zeilen.append("_keine `class_name`-Klassen_")
        else:
            zeilen.append("| Klasse | Datei |")
            zeilen.append("| --- | --- |")
            for name, pfad in sorted(eintraege):
                zeilen.append(f"| `{name}` | `{pfad}` |")
        zeilen.append("")
    zeilen.append(MARKER_ENDE)
    return "\n".join(zeilen) + "\n"


def hauptprogramm() -> int:
    inventar = inventar_sammeln()
    block = inventar_text(inventar)
    if not INDEX_PFAD.exists():
        print(f"INDEX.md fehlt: {INDEX_PFAD}", file=sys.stderr)
        return 2
    text = INDEX_PFAD.read_text(encoding="utf-8")
    if MARKER_START in text and MARKER_ENDE in text:
        vor = text[: text.index(MARKER_START)]
        nach = text[text.index(MARKER_ENDE) + len(MARKER_ENDE):]
        # Normalisiere Uebergaenge auf genau einen Leerabsatz.
        vor = vor.rstrip() + "\n\n" if vor.strip() else ""
        nach = nach.lstrip("\n")
        nach = "\n" + nach if nach else "\n"
        INDEX_PFAD.write_text(vor + block + nach, encoding="utf-8")
    else:
        # Haenge Inventar an.
        if not text.endswith("\n"):
            text += "\n"
        INDEX_PFAD.write_text(text + "\n" + block, encoding="utf-8")
    print(f"Inventar geschrieben: {sum(len(v) for v in inventar.values())} Klassen in {INDEX_PFAD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(hauptprogramm())
