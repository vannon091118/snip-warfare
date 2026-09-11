# -*- coding: utf-8 -*-
"""TDD RED-Test für G1/G2: Objekt-Faktoren und logik_id ohne Verbraucher.

Verlangt am Code: Der fachliche Faktor eines Weltobjekts oder Tieres
(faktor × basis_faktor der Logik aus kern_logik.json) fließt über den
Einheiten-Manager in die Arbeitszeit des Jobs, und jede logik_id aus dem
Katalog löst sich über die geteilte Kern_LogikRegistry auf. Vorher waren
effektive_logik, effektiver_modifikator und der Objekt-Faktor tote Felder
ohne einen einzigen Aufrufer.
"""
import pathlib
import re

PROJEKT = pathlib.Path(__file__).resolve().parent


def _lies(rel: str) -> str:
    return (PROJEKT / rel).read_text(encoding="utf-8")


def _json(rel: str):
    import json
    return json.loads(_lies(rel))


KERN_LOGIK = _json("core/data/kern_logik.json")
ELEMENT_KATALOG = _json("world/data/element_katalog.json")
TIER_VERHALTEN = _json("world/data/tier_verhalten.json")


def test_jede_logik_id_loest_sich_in_der_logik_registry_auf():
    """G2-Datenparität: Jede referenzierte logik_id existiert in kern_logik.json."""
    fehlend = []
    for eintrag in ELEMENT_KATALOG:
        logik_id = eintrag.get("logik_id", "")
        if logik_id and logik_id not in KERN_LOGIK:
            fehlend.append("objekt:%s->%s" % (eintrag.get("id"), logik_id))
    for tier_id, eintrag in TIER_VERHALTEN.items():
        logik_id = eintrag.get("logik_id", "")
        if logik_id and logik_id not in KERN_LOGIK:
            fehlend.append("tier:%s->%s" % (tier_id, logik_id))
    assert fehlend == [], "logik_id ohne Logik-Eintrag: %s" % fehlend


def test_logik_registry_hat_geteilte_instanz_mit_faktor_leser():
    """G2-Verdrahtung: geteilte Registry wie das Modifikator-Vorbild."""
    quelltext = _lies("core/logic/kern_logik_registry.gd")
    assert "static func geteilte()" in quelltext, \
        "Kern_LogikRegistry braucht eine geteilte Instanz nach Modifikator-Vorbild"
    assert "func faktor_fuer(" in quelltext, \
        "Kern_LogikRegistry braucht einen Faktor-Leser über logik_id"


def test_objekt_und_tier_basis_exponieren_den_effektiven_faktor():
    """G1: Der Objekt-Faktor (eigen × Logik-Basisfaktor) wird sichtbar exponiert."""
    objekt = _lies("world/logic/kategorie_objekt/objekt_basis.gd")
    assert "func effektiver_faktor()" in objekt, \
        "Objekt_Basis braucht effektiver_faktor als einzige Faktor-Wahrheit"
    tier = _lies("world/logic/kategorie_tier/tier_basis.gd")
    assert "func effektiver_faktor()" in tier, \
        "Tier_Basis braucht denselben effektiven Faktor"


def test_job_basisklasse_nimmt_den_zielfaktor_in_die_zeit_auf():
    """G1-Verbraucher: harvest_zeit_ticks teilt durch den Zielfaktor."""
    quelltext = _lies("game/logic/kategorie_job/job_basis.gd")
    assert "func ziel_faktor_setzen(" in quelltext, \
        "Job_Basis braucht eine Ziel-Faktor-Eingabe vom Manager"
    zeit = re.search(r"func harvest_zeit_ticks.*?(?=\n\tfunc |\Z)", quelltext, re.S)
    assert zeit is not None
    assert "ziel_faktor" in zeit.group(0), \
        "Die Arbeitszeit muss durch den Ziel-Faktor geteilt werden"


def test_manager_setzt_den_zielfaktor_bei_jedem_job_start():
    """G1-Verdrahtung: Der Manager liest den effektiven Faktor des Ziels."""
    quelltext = _lies("game/logic/kategorie_einheit/einheit_manager.gd")
    assert quelltext.count("ziel_faktor_setzen") >= 3, \
        "Direkte Vergabe, Queue-Start und Loop-Fortsetzung brauchen den Zielfaktor"
    such = _lies("game/logic/kategorie_einheit/einheit_ziel_suche.gd")
    assert "func ziel_faktor_fuer(" in such, \
        "Die Ziel-Suche ist der Lesepfad zum Faktor des Ziels"


def test_laufbeweis_prueft_die_verdrahtung_als_verhalten():
    """Der Laufbeweis muss den Faktorpfad als Verhalten nachweisen."""
    lauf = _lies("tools/lauf_pruefung_welt.gd")
    assert "effektiver_faktor" in lauf, \
        "Der Laufbeweis kennt den effektiven Faktor nicht"
    assert "ziel_faktor_setzen" in lauf, \
        "Der Laufbeweis prüft die Job-Zeit mit Zielfaktor nicht"
