# -*- coding: utf-8 -*-
"""Sonden Vertrag. Eigene Zuständigkeit: Muster und Modi der Sonden."""

import re

SONDE_FUND_MUSTER = re.compile(r"SONDE-(FEHLER|WIDERSPRUCH|FEHLT|ABWEICHUNG)")
SONDE_VERTRAG_OK = re.compile(r"SONDE:.*OK")
SZENARIO_DECKT_MUSTER = re.compile(r"^[^:]+:.+$")
OCR_BILD_MUSTER = re.compile(r"sonden_bilder/.*\.png")
ERLAUBTE_MODI = {"headless", "fenster"}
ERLAUBTE_SCHRITT_ARTEN = {
    "ding_platzieren",
    "ding_entfernen_bei",
    "snapshot_speichern",
    "snapshot_laden",
    "lager_fuellen",
    "bauen_anfordern",
    "einheit_im_blick",
    "einheit_marsch",
    "einheit_marsch_delta",
    "klick_links",
    "job_vergeben",
    "klick_rechts",
    "drag",
    "maus_bewegen",
    "ticks_pumpen",
    "anim_frame",
    "kette_frame",
}
