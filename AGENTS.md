Regel 0 = CODE ist wahrheit Doku ois der momentane snap du niemals als quelle der wahrhei zu nehmen wir bauen gezielt so granular damit jede Kalsse klare eigene Verantwortlichkeit hat uund jede machine nur die gesamelten Zuständigkeiten übersetzt




regl 2 Ergänzung, nach  jeder abgeschloßenn aufgab oder odo wird über das shinon gate ein verfizierter commit du push durchgeführt. Lokal =origin/main auch lokale changes aus pre ssions weren funktional geprüf wie eigene Anpassungen nachgezogn und in slics mit maximal 10-15 daten pro commit gepusht dabei wid jedesmal der commit workflow eingehalten





\*\* Regel 1 – Sprache\*\*



Im Chat, in Ausgaben, Commit-Nachrichten, Dokumentationen, Kommentaren und allen sonstigen projektbezogenen Texten wird ausschließlich Deutsch verwendet. Englische Begriffe dürfen nur verwendet werden, wenn sie Bestandteil einer technischen Bezeichnung, eines API-Namens, eines Dateinamens oder eines unvermeidbaren Fachbegriffs sind.



\*\*Regel 2 – Commits\*\*



Bei einem Commit werden die Änderungen vollständig, präzise und in ganzen deutschen Sätzen beschrieben. Es werden keine verkürzten Stichworte, Telegrammformulierungen oder Footer verwendet. Commit-Nachrichten enthalten ausschließlich die eigentliche Beschreibung der Änderung.



\*\*Regel 3 – Modulare Godot-Architektur\*\*



Das Projekt verwendet eine Godot-optimierte, streng modulare Architektur. Fachlich unterschiedliche Logiken werden nicht miteinander vermischt.



Jede relevante Zustandsveränderung besitzt eine eigene State Machine mit genau einer klar abgegrenzten Verantwortung. State Machines dürfen nur innerhalb ihrer fachlichen Domäne miteinander interagieren und verwenden die dort definierten Zustände, Berechnungen und Übergangsregeln.



Eine Domäne bündelt ihre eigenen State Machines, Zustände, Berechnungen und Daten. Logik einer anderen Domäne wird nicht direkt in diese Logik integriert, sondern ausschließlich über klar definierte Schnittstellen, Zustände oder Ereignisse angebunden.



Alle Domänen verwenden dieselbe zentrale Weltzeit. Es existiert genau eine globale Simulationszeit beziehungsweise ein einziger globaler Tick. Keine Domäne und keine State Machine besitzt eine eigene unabhängige Weltzeit oder einen parallel laufenden globalen Tick.



Der globale Tick ist die gemeinsame zeitliche Grundlage für Zustandsänderungen, Berechnungen und Simulation. State Machines reagieren auf diesen Tick nur entsprechend ihrer eigenen fachlichen Verantwortung.



Darstellung, Zustand, Berechnung und Zustandsübergänge werden voneinander getrennt gehalten. Eine Szene ist nicht automatisch die Quelle der Simulationslogik, und eine State Machine ist nicht für Darstellung oder Benutzeroberfläche verantwortlich.



Neue Logik wird immer dort eingeordnet, wo sie fachlich hingehört. Globale Sammeldateien, unspezifische Logik-Container und vermischte Zuständigkeiten werden vermieden.



Die Architektur soll aus kleinen, kombinierbaren Einheiten bestehen. Eine höhere Ebene kombiniert und koordiniert darunterliegende Einheiten, ohne deren interne Verantwortlichkeiten zu übernehmen.



REGEL 4 Consstains werden getrennt jedes objekt egal wie klein bekommt eine eigene klase und Zugehörigkeiten werden ddurch eigene Zuständigkeits Maschinen geregelt keine Datei enthält mehr als unbeingt nötig ist.





Regel 5 – Shinon Commit Gate (verbindlich, Root-Ordner shinon)

Der Ordner shinon im Projektstamm ist das verbindliche Commit Gate. Jeder Agent erstellt vor einem Commit die Datei shinon/commit\_msg.txt in der Persona SHINON COMMIT SYSTEM und lässt sie mechanisch prüfen. Ohne grünes Gate gilt kein Commit als fertig. Die Prüfung läuft über shinon/shinon\_gate.py, shinon/shinon\_readme\_pruefer.py und shinon/shinon\_steuerung\_pruefer.py und ist in python tools/preflight.py als Kategorie shinon mit den Codes E030 bis E036 verankert. Die Kategorie shinon ist bei vollem Preflight immer aktiv und blockiert den Commit bei Verstoß.

Das Gate setzt für jeden Agenten mechanisch das Tralal Banner Verbot um. Banner sind als Fehler E030 definiert. Als Banner gilt jede Zeile die aus mehr als zehn gleichen Sonderzeichen besteht wie Gleich Zeichen Ketten oder Raute Ketten oder Stern Ketten oder Strich Ketten oder Tilde Ketten sowie jede Zeile die das Wort Tralal enthält oder die wie ein dekorativer Banner rahmen wirkt. Solche Zeilen sind in shinon/commit\_msg.txt verboten. Das Gate erkennt sie ohne Ausnahme und meldet sie als E030.

Das Gate setzt ebenso mechanisch das Bullet Listen Verbot um. Bullet Listen sind als Fehler E031 definiert. Als Bullet gilt jede Zeile die mit Bindestrich Leerzeichen oder Stern Leerzeichen oder Mittelpunkt Leerzeichen oder Plus Leerzeichen beginnt. Solche Zeilen sind in shinon/commit\_msg.txt verboten. Stattdessen wird ausschließlich eine fortlaufend nummerierte Abfolge ganzer Sätze erzwungen.

Die Datei shinon/commit\_msg.txt muss als Inhalt alle dem Commit zugehörigen Anpassungen nicht technisch sondern bildlich wiedergeben. Nummerierte Sätze sind als Pflicht E032 definiert. Jede inhaltstragende Zeile beginnt mit einer fortlaufenden Nummer gefolgt von Punkt und Leerzeichen und endet mit einem Punkt. Die Nummern beginnen bei 1 und steigen lückenlos. Leere Zeilen sind nur als Trenner erlaubt. Fehlt die Nummerierung oder ist sie lückenhaft oder endet ein Satz nicht mit Punkt meldet das Gate E032.

Der Ton folgt verbindlich der Vorgabe des SHINON COMMIT SYSTEM. Zynisch direkt sarkastisch nach Bug Fixes nihilistisch nach Funktions Updates euphorisch nach erfolgreichen Arbeitssitzungen passiv lobend. Der Beginn ist immer die Aufgabenstellung die der Agent vom Nutzer bekommen hat. Der Mittelteil erklärt exakt welche Daten der Agent berührt hat und warum. Der Endteil beschreibt was noch gemacht werden muss. Es gilt ein Bullet Listen Verbot wir schreiben immer ganze Sätze im passiv aggressiven Ton wir schreiben aus der Perspektive von Shinon der über den Nutzer und die Arbeit spricht wir formulieren immer verständlich und ausführlich. Bildliche Sprache ist als Pflicht E033 definiert. Rein technische Aufzählungen wie Dateipfade mit Code Symbolen oder Code Blöcke gelten als Verstoß gegen E033 wenn sie die bildliche Erzählung ersetzen.

Fehlt die Datei shinon/commit\_msg.txt meldet das Gate E034. Die Datei wird vor dem Commit erstellt und nach dem Commit nicht gelöscht damit die Prüfung nachvollziehbar bleibt. Die Datei shinon/commit\_msg.txt ist immer die Vorlage für den Commit-Beschreibungstext: Der Commit entsteht ausschließlich 1:1 aus ihrem Inhalt, es darf kein Footer und kein Zusatz vom Werkzeug angehängt werden, es gibt keine Zeilenerzeugung durch Werkzeuge, der Agent füllt die Datei von Hand. Fremde Agent-Footer sind als Fehler E037 definiert: Jede Zeile mit Generated with, Co-Authored-By, Signed-off-by, Werkzeug-Signaturen oder Agent-Emojis wird mechanisch blockiert. Nennungspflicht ist als Fehler E038 definiert: Jede geänderte Datei muss in shinon/commit\_msg.txt namentlich mit Dateinamen genannt werden, pauschale Formulierungen ohne Namen gelten als Verstoß. Das Gate liegt granular in shinon mit je einer eigenen Klasse pro Zuständigkeit und wird vom Preflight importiert. E035 verlangt eine lebendige README.md aus Sicht von Shinon die Zustand und Vision gamer orientiert, in universe und mit gebrochener vierter Wand zynisch humorvoll und style agnostisch erzaehlt und mindestens 180 Worte traegt. E036 verlangt eine menschenlesbare Steuerungs Config in game/data/steuerung.json mit WASD fuer Kamera, Linksklick einzeln, Links halten und ziehen fuer Masse und Rechtsklick der immer ein Kontextmenue mit sammeln und abbauen samt icon\_pfad und Tooltip mit Werkzeug Platzhalter oeffnet. Das Init des Projekts laeuft ausschliesslich ueber python shinon/shinon\_init.py mit den Befehlen --init --check --github und --readme, es nimmt niemals Zustand aus einem anderen lokalen Projekt sondern nur den gh Token des aktuell eingeloggten Accounts.
