# Fundliste: Ingame-Testbefunde (offen)

Dieses Protokoll listet Befunde aus den sichtbaren MCP-Testläufen (godot-acp, Developer-Profil, Sitzungen runtime_qa1 bis runtime_qa3, Datum 2026-09-10). Aufgenommen ist nur, was im laufenden Spiel beobachtet wurde und beim Testzeitpunkt noch nicht behoben war. Jeder Befund nennt den exakten Beobachtungsweg, die vermutete Ursache als Hypothese und den Abgrenzungsstand. Ein Befund ohne Beobachtungsweg ist hier verboten, ein Befund ohne Hypothese wird als Analyserest im Abschnitt Offene Fragen geführt. Verifiziert und inzwischen behoben ist gesondert am Ende aufgeführt, damit niemand Doppelarbeit baut.

## Befunde

### F-I01: Custom-MCP-Tools stehen nach dem Ablegen in mcp_tools nicht zur Verfügung

Beobachtung: Die Datei mcp_tools/qa_observer.gd liegt mit get_tool_defs() und dispatch_tool() im Projekt. Der Aufruf des Tools custom_qa_observer über den Atomic-Client an die laufende Spielinstanz antwortet mit Tool not found (JSON-RPC -32601), ohne dass das Spiel einen Parse-Fehler oder Skriptfehler im Log zeigt.

Hypothese: Der Registry-Zweig dispatcht Anfragen mit custom_-Präfix nur dann an McpCustomToolLoader, wenn das Feld _custom_loader belegt ist. Wird dieses Feld erst beim Start belegt und danach nie wieder aktualisiert, kennt die laufende Instanz neue Dateien in mcp_tools erst nach einem Neustart; ein echtes Hot-Reload fehlt. Zusätzlich prüft der Loader beim dispatch jeden Eintrag einzeln und behandelt Load-Fehler des eigenen Skripts still, sodass ein Parse-Fehler in der Tool-Datei unsichtbar als Unknown custom tool enden kann.

Abgrenzung: Dateiname, Methodennamen und Präfix stimmen exakt mit dem Loader-Vertrag überein. Kein Parse-Fehler im Godot-Log. Der Fehler tritt auf, ohne dass die Szene gewechselt wurde.

Nächster Analyseschritt: Lebenszyklus von _custom_loader in mcp_tool_registry.gd prüfen (Zeilen 455 bis 470), Zeitpunkt der discover_tools-Ausführung gegen den Datei-Zeitstempel stellen, und den stillen Fehl-Index der Discover-Schleife mit einer bewusst kaputten Testdatei beweisen.

### F-I02: runtime_eval kann keine Engine- und Autoload-Aufrufe ausführen

Beobachtung: Die Ausdrücke Engine.get_main_loop() != null und Engine.get_frames_drawn() > 0 antworten mit Runtime error: self can't be used because instance is null (not passed), während 1 + 1 und str(1) + 'x' regulär ausführen. Auch trivialste Ausdrücke über Autoloads schlagen fehl.

Hypothese: _rt_eval in mcp_runtime_tools.gd ruft Expression.execute([], null, true) mit Basisklasse null auf. Ein null-Basisklasse macht jeden Aufruf über ein Singleton oder einen Autoload unmöglich, weil dem Ausdruck die Instanz fehlt. Der Godot-Parser wertet Engine als Bezeichner nur auf, wenn eine Basisklasse existiert, deshalb resultiert ERR_INVALID_DATA statt einer Auswertung.

Abgrenzung: Der Aufruf ist im Developer-Profil freigeschaltet und wird nicht vom Contract-Gate blockiert. Der Parametername code ist korrekt, der Transport ist sauber (1 + 1 liefert {"result":2}). Der Fehler ist Auswertung, nicht Übertragung.

Nächster Analyseschritt: Eine gültige Basisklasse übergeben (zum Beispiel die Wurzel des SceneTree statt null), damit Engine und Autoloads im Ausdruck auflösbar werden. Die Änderung berührt genau eine Zeile im Addon, ist aber Upstream-Code und gehört deshalb auf die Findings-Liste für das MCP-Team statt eines stillen lokalen Patches.

### F-I03: E2E-Szenario-Historie verliert den Szenenzustand zwischen Läufen

Beobachtung: new_game_to_world läuft direkt nach dem Boot grün. Läuft danach pause_save_menu, endet es grün und lässt den Baum pausiert zurück. Ein unmittelbar folgendes new_game_to_world meldet start button found before click false, obwohl runtime_ux_scan die Szene Welt und die vollen HUD-Kontrollen zeigt.

Hypothese: Die Szenarien haben keinen gemeinsamen Zustands-Zurücksetzer. _ensure_main_menu geht davon aus, dass der Baum nach dem Menü-Klick aus dem Pausenmodus zurückkehrt, aber das Spiel behält get_tree().paused = true nur bei, wenn der Szenenwechsel durch die Pause-Hülle läuft. Das Addon hat einen force-unpause-Wächter, der erst NACH dem Menü-Klick greift und deshalb für den Folgelauf zu spät kommt. Der Folgelauf scheitert am find auf der Start-Schaltfläche, weil der Szenenscan bei pausiertem Baum keine neuen Steuerelemente sammelt oder weil die Szene bereits Welt ist und das Menü nicht mehr existiert.

Abgrenzung: Nach einem frischen Spielstart läuft new_game_to_world grün; der gleiche Lauf nach pause_save_menu schlägt reproduzierbar fehl. Der Scan selbst sieht die Welt und ihre Kontrollen, das Spiel ist funktional.

Nächster Analyseschritt: In _ensure_main_menu vor dem find einen Zustands-Zurücksetzer (unfreeze plus Hauptmenü-Prüfung) einziehen oder das Szenario um einen definierten Ausgangszustand ergänzen. Gehört auf die MCP-Team-Liste, weil es ein Szenario-Ordnungsproblem im Addon ist.

### F-I04: Spielübergreifende Pause des Baums hängt an der Pause-Hülle, nicht am Spielzustand

Beobachtung: Nach pause_save_menu meldet runtime_ux_scan die Szene Welt mit allen Kontrollen, ein Pause-Label steht sichtbar im Scan-Ergebnis, und der nachfolgende Szenario-Lauf scheitert wie in F-I03. Das Spiel selbst läuft nach einem Neustart fehlerfrei.

Hypothese: Welt_PauseMenue setzt get_tree().paused = true beim Öffnen und räumt bei _exit_tree oder nach dem Menü-Klick nicht selbst auf. Solange niemand den Wächter des Addons oder einen Neustart auslöst, bleibt die Welt als Szene stehen, aber jede neue Eingabe läuft gegen einen pausierten Baum. Die Rückkehr ins Hauptmenü über die Brücke läuft trotzdem, weil der Brückenknoten process_mode im Gegensatz zur Welt immer weiterläuft.

Abgrenzung: Das Verhalten ist reproduzierbar nach jedem pause_save_menu-Lauf. Nach Neustart fehlt es vollständig. Die Schaltflächen Speichern und Hauptmenü funktionieren im Pause-Menü selbst zuverlässig.

Nächster Analyseschritt: In Welt_PauseMenue._exit_tree ein schliessen-without-feedback ergänzen oder die Hauptmenü-Rückkehr über die Brücke mit einer garantierten Unpause koppeln. Das ist ein echter Spieler-Befund (ESC während Szenenwechsel könnte die Welt einfrieren) und gehört in die Spielreparatur, nicht in das Addon.

### F-I05: Objekt-Referenzpositionen im QA-Beobachter fehlen für Objekte ohne Renderer

Beobachtung: Beim ersten Klickversuch mit Pixel-Analyse wurde als Baumposition ein dunkler Bodencluster (570,346) gelesen, im Weltmodell lag dort aber Boden oder ein Objekt ohne eigenes Sprite. Der Click-Pipeline antwortete korrekt mit Hier gibt es nichts zu tun; die Pipeline selbst war also sauber, nur die Ziel-Koordinate war falsch.

Hypothese: Die Karte rendert Fliesen aus einer gemeinsamen Textur, während das Weltmodell die Objektliste als Daten führt. Ein QA-Beobachter, der nur aus Screenshots liest, kann Objekt- und Bodenpixel nicht zuverlässig trennen; ein Beobachter, der das Weltmodell liest, kann es. Die Lücke ist damit geschlossen, bleibt aber als Dokumentation für künftige Bild-Analysen stehen.

Abgrenzung: Der custom_qa_observer liest Objektpositionen direkt aus dem Weltmodell, nicht aus Pixeln. Die Pipeline runtime_ux_click antwortet mit einer klaren Meldung, wenn ein Klick ins Leere geht, das Spiel ist also nie unaufrichtig.

Nächster Analyseschritt: Keiner im Spiel; der Befund wird als Erinnerung dokumentiert, dass Bild-Analysen ohne Modell-Wahrheit für Klickziele verboten sind.

## Offene Fragen (ohne Hypothese)

None. Jeder Befund trägt eine Hypothese und einen Abgrenzungsstand.

## Während der Tests verifiziert und behoben

Diese Punkte waren während der Läufe offen und sind inzwischen im Code repariert, sie dürfen nicht als offene Befunde behandelt werden.

1. Parse-Fehler in mcp_e2e.gd (fehlender Tab in Zeile 151, Unexpected Indent in class body) war ein Upstream-Bug im godot-acp-Addon; behoben in der installierten Kopie und im lokalen ~/godot-acp-Klon.
2. E2E-Find-Schleife: Neun sync _find-Stellen riefen runtime_ux_find über den sync-Dispatch auf, der das Tool bewusst nur async ausliefert, sodass jeder Szenario-Find still fehlschlug; behoben durch Umstellung aller neun Stellen auf den async-Weg in beiden Kopien.
3. Integer-Division-Warnung in welt_generator.gd:95 (REGION_KANTE / CHUNK_GROESSE) war im eingehenden Upstream-Merge bereits als float-Division mit explizitem Cast repariert.
4. Pause-Menü-Sichtbarkeit: Die generische E2E-Prüfung sucht den Zwecknamen PauseMenu, die Kompositionsstelle trug ihn nicht; behoben durch setzten des Panel-Namens in Welt_PauseMenue._ready, sichtbar verifiziert über den grünen Lauf von pause_save_menu.
5. Stale Autoload-Pfad core/weltuhr.gd im Godot-Cache nach dem Weltuhr-Umzug nach core/logic/clock/; behoben durch zwei Import-Läufe, kein Quelltext betroffen.

## Report für das MCP-Team (godot-acp)

Gefunden im Addon godot-acp (vannon09118/godot-acp, installiert 2026-09-09, Version 1.0.0), verifiziert gegen die installierte Kopie und den ~/godot-acp-Klon:

1. mcp_e2e.gd Zeile 151: Fehlender Einzug vor var save := _find(start_label_save) bricht das Skript mit Unexpected Indent in class body. Reproduzierbar bei jedem Laden des Addons. Fix: Einzug korrigieren. In der installierten Kopie bereits geflickt, im Upstream noch offen.
2. Sync/Async-Vertrag: runtime_ux_find ist absichtlich async-only, aber neun Stellen in mcp_e2e.gd rufen es über den sync-Dispatch-Pfad auf, sodass jeder Szenario-Find still fehlschlägt (found=false). Fix: Alle Stellen auf _call_async umstellen. In beiden lokalen Kopien geflickt, im Upstream noch offen.
3. _rt_eval mit null-Basisklasse: Expression.execute([], null, true) macht Engine- und Autoload-Aufrufe unmöglich (self can't be used because instance is null). Fix: Eine lebende Basisklasse übergeben. Im Upstream offen.
4. Custom-Tool-Hot-Reload: mcp_tools-Skripte werden nur beim Registry-Load entdeckt; neu abgelegte Dateien brauchen einen Spielneustart. Zusätzlich schluckt die Discover-Schleife Load-Fehler still. Fix: Registry-Reload-Hook oder Datei-Wächter plus sichtbarer Fehler statt stiller Schluck. Im Upstream open.
5. Szenario-Zustandsrücksetzung: Szenarien teilen keinen Ausgangszustand; ein pause_save_menu-Lauf hinterlässt den Baum pausiert und bricht den nächsten Lauf. Fix: _ensure_main_menu um garantiertes Unfreeze ergänzen. Im Upstream offen.

## Grenze dieser Fundliste

Die Fundliste erhebt keinen Anspruch auf Vollständigkeit über alle Szenarien hinweg. Sie deckt die Läufe der Sitzungen runtime_qa1 bis runtime_qa3 auf Hauptmenü, Welt, Pause und dem ersten Produktionsversuch. Der QA-Beobachter custom_qa_observer ist noch nicht in der Laufzeit registriert (F-I01), deshalb sind Einheiten-, Objekt- und Lagerbeobachtungen dieser Sitzungen über runtime_ux_scan, runtime_get_scene_tree und die HUD-Zeilen beobachtet, nicht über den Beobachter.
