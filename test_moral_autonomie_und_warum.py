# -*- coding: utf-8 -*-
"""Vertragstests für Moral (CP-8.2/14.4), Autonomie (CP-6.4), Timeline (CP-8.1) und BauPanel (CP-7.1).

Verifiziert am Code:
- Pop_MoralInstanz lädt moral_regeln.json, sperrt Kannibalismus und nennt Ersatzhandlungen.
- Einheit_AutonomieMaschine liest autonomie.json und vergibt Jobs über den Manager-Ruf.
- Die Verhaltens-Maschine blockiert die Kannibalen-Jagd bei Verbot und meldet die
  Blockade an die Timeline, damit das Warum-Fenster sie erzählen kann.
- Das BauPanel zeigt gesperrte Gebäude ausgegraut mit Sperrstufe statt sie zu verstecken.
- Die Panels lesen nur bei Sichtbarkeit (kein dauerndes Polling, CP-7.4).
"""
import json
import pathlib

PROJEKT = pathlib.Path(__file__).resolve().parent


def _lies(rel: str) -> str:
    return (PROJEKT / rel).read_text(encoding="utf-8")


def _json(rel: str):
    return json.loads(_lies(rel))


def test_moral_regeln_pool_traeigt_grundsaetze_und_ersatzhandlungen():
    """Der Datenpool kennt den Kannibalismus-Schalter und eine Ersatzhandlung je Blockade."""
    pool = _json("world/data/moral_regeln.json")
    grundsaetze = pool["grundsaetze"]
    assert grundsaetze["kannibalismus_erlaubt"] is False, "Kannibalismus startet verboten"
    blockaden = {regel["bei_blockade"] for regel in pool["ersatzhandlungen"]}
    assert "kannibalismus_verboten" in blockaden, "Keine Ersatzhandlung für das Moral-Verbot"
    for regel in pool["ersatzhandlungen"]:
        assert regel["aktion"], "Ersatzhandlung ohne Aktion ist ein leerer Auftrag"


def test_moral_instanz_sperrt_verhalten_und_nennt_ersatz():
    """Pop_MoralInstanz lädt den Pool, beantwortet darf_verhalten und liefert Ersatzregeln."""
    code = _lies("population/logic/moral/pop_moral_instanz.gd")
    assert "class_name Pop_MoralInstanz" in code
    assert "moral_regeln.json" in code, "Moral liest nicht aus dem Datenpool"
    assert "func darf_verhalten" in code, "Keine Zielwahl-Frage der Moral"
    assert "func ersatz_regel_fuer_blockade" in code, "Keine Ersatzregel-Suche"
    assert "kannibalismus" in code, "Kannibalismus ist kein Moral-Fall"


def test_verhaltens_maschine_befragt_die_moral_vor_der_tat():
    """Die Kannibalen-Entscheidung läuft durch das Moral-Gate, nicht daran vorbei."""
    verhalten = _lies("game/logic/kategorie_einheit/einheit_verhaltens_maschine.gd")
    assert "darf_verhalten" in verhalten, "Keine Moral-Frage vor der Tat"
    assert "kannibalismus" in verhalten, "Verbot prüft nicht das Kannibalismus-Verhalten"


def test_moral_blockade_wird_an_die_timeline_gemeldet():
    """CP-8.1: Die Verweigerung wird gebucht, damit das Warum-Fenster sie zeigen kann."""
    verhalten = _lies("game/logic/kategorie_einheit/einheit_verhaltens_maschine.gd")
    verdrahtung = _lies("game/logic/kategorie_einheit/einheit_verdrahtung.gd")
    manager = _lies("game/logic/kategorie_einheit/einheit_manager.gd")
    assert "eintrag_anhaengen" in verhalten, "Blockade wird nicht gebucht"
    assert "ersatzhandlung_fuer" in verhalten, "Buchung nennt keine Ersatzhandlung"
    assert '"timeline"' in verdrahtung, "Verdrahtung reicht die Timeline nicht in die Maschine"
    assert "timeline" in manager, "Manager-Vertrag trägt die Timeline nicht"


def test_autonomie_pool_traegt_prioritaeten_als_daten():
    """Reihenfolge und Suchradius stehen in autonomie.json, nicht im Code."""
    pool = _json("game/data/autonomie.json")
    schritte = pool["schritte"]
    assert len(schritte) >= 2, "Zu wenige Autonomie-Schritte"
    prioritaeten = [int(schritt["prioritaet"]) for schritt in schritte]
    assert prioritaeten == sorted(prioritaeten), "Prioritäten sind nicht aufsteigend"
    job_ids = {str(schritt["job_id"]) for schritt in schritte}
    bekannte_jobs = set(_json("game/data/job_config.json").keys())
    assert job_ids <= bekannte_jobs, f"Unbekannte Jobs im Autonomie-Pool: {job_ids - bekannte_jobs}"


def test_autonomie_maschine_vergibt_ueber_den_manager_ruf():
    """Die Maschine liest den Pool und vergibt denselben Manager-Job wie der Spieler."""
    code = _lies("game/logic/kategorie_einheit/einheit_autonomie_maschine.gd")
    assert "class_name Einheit_AutonomieMaschine" in code
    assert "autonomie.json" in code, "Autonomie liest nicht aus dem Datenpool"
    assert "func autonom_fuer" in code, "Kein Autonomie-Einstieg je Einheit"
    assert "job_vergeben" in code, "Autonomie vergibt nicht über den Manager-Ruf"
    verdrahtung = _lies("game/logic/kategorie_einheit/einheit_verdrahtung.gd")
    assert "_autonomie.einrichten" in verdrahtung, "Autonomie ist nicht verdrahtet"


def test_verhaltens_maschine_ruft_autonomie_als_fallback():
    """Ohne Verhalten und ohne Opfer landet die Einheit in der Autonomie, nicht im Nichts."""
    verhalten = _lies("game/logic/kategorie_einheit/einheit_verhaltens_maschine.gd")
    assert "_autonomie_fuer" in verhalten, "Kein Autonomie-Fallback"
    assert verhalten.count("_autonomie_fuer(index)") >= 3, "Fallback fehlt in mindestens einem Pfad"


def test_bau_panel_zeigt_gesperrte_eintraege_mit_sperrstufe():
    """CP-7.1: Gesperrte Gebäude sind sichtbar, ausgegraut, mit Stufe im Text und Tooltip."""
    logik = _lies("ui/logic/kategorie_ui/ui_bau_panel.gd")
    szene = _lies("ui/scenes/panels/bau_panel.gd")
    assert "Gesperrt bis Stufe" in logik, "Tooltip nennt die Sperrstufe nicht"
    assert "continue" not in logik.split("for definition")[1].split("ergebnis.append")[0], \
        "Gesperrte Einträge werden noch versteckt"
    assert "btn.disabled = gesperrt" in szene, "Gesperrte Knöpfe sind noch wählbar"
    assert "modulate" in szene, "Gesperrte Knöpfe sind nicht ausgegraut"
    assert "Stufe %d" in szene, "Sperrstufe steht nicht am Knopf"
    assert 'if not gesperrt:' in szene, "Gesperrte Knöpfe dürfen bau_gewaehlt nicht auslösen"


def test_panels_lesen_nur_bei_sichtbarkeit():
    """CP-7.4: Unsichtbare Panels kosten keinen Tick; set_process folgt der Sichtbarkeit."""
    for pfad in ("ui/scenes/panels/einheit_panel.gd", "ui/scenes/panels/tier_panel.gd"):
        code = _lies(pfad)
        assert "set_process(is_visible_in_tree())" in code, f"{pfad} pollt blind weiter"
        prozess = code.split("func _process")[1]
        assert "is_visible_in_tree()" in prozess, f"{pfad} liest ohne Sichtbarkeit"


def test_warum_fenster_liest_aus_der_timeline():
    """Das Warum-Fenster bleibt Timeline-Verbraucher und zeigt die gebuchten Begründungen."""
    hud = _lies("ui/scenes/hud/hud_status_anzeige.gd")
    assert "timeline_anzeigen" in hud, "HUD nimmt keine Timeline-Buchungen an"
    assert "_begruendungen" in hud, "Warum-Fenster hat keinen Begründungs-Speicher"
    welt = _lies("world/scenes/welt.gd")
    assert "_timeline.eintrag_neu.connect" in welt, "Timeline-Einträge erreichen das HUD nicht"


def test_moral_instanz_traegt_schalter_metadaten():
    """Die Moral-Domäne besitzt Label und Tooltip; der JSON-Pool nennt keine UI-Texte."""
    moral = _lies("population/logic/moral/pop_moral_instanz.gd")
    assert "SCHALTER_TEXTE" in moral, "Keine Schalter-Metadaten in der Moral-Domäne"
    assert "kannibalismus_erlaubt" in moral, "Kannibalismus-Schalter trägt keinen Text"
    assert "func schalter_ids" in moral, "Keine Schalter-Liste für das Fenster"
    pool = _json("world/data/moral_regeln.json")
    for schalter_id in ("kannibalismus_erlaubt", "tiere_bevorzugt", "bindungsobjekt_geschuetzt", "verhungern_erlaubt"):
        assert schalter_id in pool["grundsaetze"], f"Schalter {schalter_id} fehlt im Datenpool"


def test_manager_reicht_den_moral_griff_durch():
    """Der geschlossene Schnittpunkt: lesen und setzen über den Einheit_Manager."""
    manager = _lies("game/logic/kategorie_einheit/einheit_manager.gd")
    assert "func moral_grundsatz_lesen" in manager, "Kein Lese-Griff am Manager"
    assert "func moral_grundsatz_setzen" in manager, "Kein Setz-Griff am Manager"
    verdrahtung = _lies("game/logic/kategorie_einheit/einheit_verdrahtung.gd")
    assert "func moral_grundsatz" in verdrahtung, "Verdrahtung reicht den Lese-Ruf nicht"
    assert "func moral_grundsatz_aendern" in verdrahtung, "Verdrahtung reicht den Setz-Ruf nicht"


def test_grundsatz_fenster_hat_uebersetzer_und_szene():
    """UI-Logik und Dialog existieren getrennt nach dem Übersetzer-Muster."""
    logik = _lies("ui/logic/kategorie_ui/ui_grundsatz_panel.gd")
    szene = _lies("ui/logic/kategorie_ui/ui_grundsatz_fenster.gd")
    assert "class_name Ui_GrundsatzPanel" in logik, "Keine UI-Logik des Fensters"
    assert "func eintraege_ermitteln" in logik, "Übersetzer liefert keine Einträge"
    assert "moral_grundsatz_lesen" in logik, "Logik umgeht den Manager-Schnittpunkt"
    assert "class_name Ui_GrundsatzFenster" in szene, "Keine Dialog-Szene"
    assert "CheckButton" in szene, "Fenster baut keine Schalter"
    assert "about_to_popup.connect" in szene, "Fenster liest den Stand nicht beim Öffnen"


def test_welt_szene_verdrahtet_grundsatz_fenster_in_die_leiste():
    """Das Fenster hängt an der UI-Ebene und die Fenster-Leiste trägt seinen Knopf."""
    welt = _lies("world/scenes/welt.gd")
    aufbau = _lies("world/logic/kategorie_welt/welt_ui_aufbau.gd")
    assert "grundsatz_fenster_bauen" in aufbau, "Kein Bau-Schritt in der UI-Spitze"
    assert "_ui_aufbau.grundsatz_fenster_bauen" in welt, "Die Szene hängt das Fenster nicht an"
    assert '"id": "grundsatz"' in welt, "Fenster-Leiste kennt keinen Grundsatz-Knopf"
    assert "grundsatz_fenster_umschalten" in aufbau, "Kein Toggle-Weg für das Fenster"
