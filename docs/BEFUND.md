# BEFUND 2026-09-10 (geprüft und abgearbeitet am 2026-09-11)

Dieses Dokument wurde gegen den Code geprüft und abgearbeitet. Jede Behauptung trägt das Ergebnis der Prüfung, widerlegte Aussagen sind als widerlegt markiert und stehen nicht mehr als offene Arbeit im Raum.

## 1. Behauptung zur Scene-Hierarchie: widerlegt

Behauptet war, die Szenen welt.tscn und karten_editor.tscn deklarierten ihre Knoten ohne unique_name_in_owner, obwohl die Skripte sie per Prozent-Referenz ansprechen, und deshalb liefere @onready null.

Prüfung am Code: Beide Szenen tragen unique_name_in_owner = true bei genau den Knoten, die ihre Skripte ansprechen. welt.tscn hat 14 solche Knoten und deckt alle zehn Referenzen aus welt.gd ab (Karte, Tiere, Kamera, HUD, AuswahlRechteck, KontextMenue, ZurueckKnopf, WarumKnopf, WarumFenster, WarumText). karten_editor.tscn hat 11 solche Knoten und deckt alle neun echten Referenzen ab (Karte, Kamera, KategorienLeiste, ElementFluss, EntfernenKnopf, StatusLabel, SpeichernKnopf, ZurueckKnopf, DialogSpeichern, NamenFeld); die drei übrigen Treffer der Suche waren die Format-Platzhalter d, dx und s aus einem Status-Text und keine Knotenreferenzen.

Beweis: Beide Szenen wurden headless mit der Projekt-Engine gestartet. Es gab keine Auflösefehler, und beide _ready-Funktionen greifen unmittelbar auf die Referenzen zu (welt.gd auf Karte, Kamera, HUD, KontextMenue, karten_editor.gd auf NamenFeld); eine null-Referenz hätte dort einen Laufzeitfehler geworfen. Die Szenen starten fehlerfrei, alle Referenzen sind non-null, es war keine Änderung an den Szenen nötig.

## 2. Echte Fehler, die die Prüfung stattdessen gefunden hat: behoben

Erster Fehler: kern_signal_bus.gd baute den Pfad zum Autoload als absoluten Pfad auf. Die Modifikator-Maschine ruft den Bus bereits in ihrem _init, und Maschinen entstehen als Feld-Initialisierer von Managern, die selbst Feld-Initialisierer der Welt-Szene sind. In diesem Moment liegt der Szenenbaum noch nicht aktiv vor, Godot verbietet absolute Pfade außerhalb des Baums, und der Fehler Can't use get_node with absolute paths from outside the active scene tree erschien beim Start der Welt zweimal (Bau-Maschine und Produktions-Maschine). Die Suche läuft jetzt über den relativen Namen vom Wurzelknoten mit Null-Wächter; der Kopfkommentar erklärt die Bau-Phase. Der Welt-Start ist danach fehlerfrei.

Zweiter Fehler: karten_editor.gd wies einem Label theme_override_font_sizes als Wörterbuch zu. Godot 4 kennt keinen setzbaren Wörterbuch-Eintrag für Schriftgrößen; der Aufruf schlug als Script-Fehler fehl. Der Override läuft jetzt über die öffentliche Theme-API add_theme_font_size_override mit font_size 22. Der Editor-Start ist danach fehlerfrei.

## 3. Was erhalten bleibt

Die Knoten und die Skripte bleiben vollständig erhalten. Die Arbeitsweise mit @onready und Prozent-Referenzen bleibt unverändert. Es wurden keine neuen Systeme, Knoten oder Skripte angelegt.

## 4. Testnachweis nach der Änderung

Beide Szenen starten headless ohne Laufzeitfehler, alle Prozent-Referenzen sind non-null und die Szenen sind bedienbar. Der Preflight bleibt grün, der Warnungs-Scan bleibt grün und der Beweislauf bleibt grün.

## 5. Nebenbefund zur UID-Klärung

Die vier Skripte ohne Begleiter (Ui_EinheitPanel, Ui_TierPanel, einheit_panel, tier_panel) sind lebendig: welt.gd lädt beide Panels-Szenen per preload, und diese erzeugen ihre Übersetzer. Ein Engine-Import hat ihre Begleiter erzeugt; sie sind als Import-Artefakte von der Projekt-.gitignore ausgeschlossen und damit kein Repo-Inhalt. Fünf verwaiste Begleiter aus Moves und Löschungen (Timeline-Move, Ressourcen-Umbenennung, Orchestrator_Basis, kompilier_sweep) waren nie im Git-Index und wurden lokal entfernt; die Gegenprüfung findet keine Waisen mehr.
