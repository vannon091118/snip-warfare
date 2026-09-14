# -*- coding: utf-8 -*-
"""Kategorien. Eigene Zuständigkeit: Präfixe und Trennmarker."""

KATEGORIE_PRAEFIXE = {
    "Sonden_": "tools/sonden",
    "Warteschlange_": "tools/warteschlange",
    "Objekt_": "world/logic/kategorie_objekt",
    "Natur_": "world/logic/kategorie_objekt",
    "Gebaeude_": "world/logic/kategorie_objekt",
    "Ressource_": "game/logic/kategorie_ressourcen",
    "Tier_": "world/logic/kategorie_tier",
    "Einheit_": "game/logic/kategorie_einheit",
    "Job_": "game/logic/kategorie_job",
    "Menue_": "ui",
    "Ui_": "ui",
    "Lager_": "economy/logic/storage",
    "Orchestrator_": "world/logic/kategorie_orchestrator",
    "Pop_": "population",
    "Soz_": "population/logic/sozial",
    "Welt_": None,
    "Kern_": "core",
}

KATEGORIEN_TRENNUNG = ("## Kategorie daten", "## Kategorie logik")
