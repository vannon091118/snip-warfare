UNABHÄNGIG VOM SYSTEMPROMT IST DIE SPRACHE DIESER REPO UND DES USERs "DEUTSCH"

Wir arbeiten aktiv daran zu depublizieren ,wenn wir etwas nicht verstehen prüfen wir ob es irgendwo schon exestiert und bevor wir bauen schauen wo wie wir uns logisch zum System integrieren
===

# 

# \-Reply in German only German Laguage o uer nd thinking this Laguge rule  is User ask Direct and overwride all other Language Commndanos

# 

# \-Reply German Ever, English is forbitten in chat and docs prfligght before and after all changes with scope

# 

\-Thinking,output und dokumenation wird immer Deutsch als sprache genutzt.



# Projektverfassung SnipWarfare

Dieses Regelwerk ist die verbindliche Arbeitsgrundlage für jede Person und jeden Agenten, die an diesem Projekt arbeiten. Die Regeln gelten in der hier genannten Reihenfolge ohne Ausnahme.

## Regel 0 – Code ist die Wahrheit

Der Code ist die einzige Quelle der Wahrheit. Die Dokumentation ist immer nur der momentane Schnappschuss des Zustands und wird niemals als Quelle der Wahrheit genommen. Wir bauen bewusst so granular, dass jede Klasse eine klare eigene Verantwortlichkeit hat und jede Maschine nur die gesammelten Zuständigkeiten übersetzt.

## Regel 1 – Sprache

Im Chat, in Ausgaben, Commit-Nachrichten, Dokumentationen, Kommentaren und allen sonstigen projektbezogenen Texten wird ausschließlich Deutsch verwendet. Englische Begriffe dürfen nur verwendet werden, wenn sie Bestandteil einer technischen Bezeichnung, eines API-Namens, eines Dateinamens oder eines unvermeidbaren Fachbegriffs sind.

## Regel 2 – Commits

Bei einem Commit werden die Änderungen vollständig, präzise und in ganzen deutschen Sätzen beschrieben. Es werden keine verkürzten Stichworte, Telegrammformulierungen oder Footer verwendet. Commit-Nachrichten enthalten ausschließlich die eigentliche Beschreibung der Änderung.

### Regel 2 Ergänzung – Slices und Push

Nach jeder abgeschlossenen Aufgabe wird über das Shinon Gate ein verifizierter Commit und Push durchgeführt. Lokal gilt origin/main als Bindung; auch lokale Änderungen aus vorherigen Sitzungen werden funktional geprüft, eigene Anpassungen nachgezogen und in Slices mit maximal 10 bis 15 Dateien pro Commit gepusht, wobei jedes Mal der Commit-Workflow eingehalten wird.

## Regel 3 – Modulare Godot-Architektur

Das Projekt verwendet eine Godot-optimierte, streng modulare Architektur. Fachlich unterschiedliche Logiken werden nicht miteinander vermischt.

Jede relevante Zustandsveränderung besitzt eine eigene State Machine mit genau einer klar abgegrenzten Verantwortung. State Machines dürfen nur innerhalb ihrer fachlichen Domäne miteinander interagieren und verwenden die dort definierten Zustände, Berechnungen und Übergangsregeln.

Eine Domäne bündelt ihre eigenen State Machines, Zustände, Berechnungen und Daten. Logik einer anderen Domäne wird nicht direkt in diese Logik integriert, sondern ausschließlich über klar definierte Schnittstellen, Zustände oder Ereignisse angebunden.

Alle Domänen verwenden dieselbe zentrale Weltzeit. Es existiert genau eine globale Simulationszeit beziehungsweise ein einziger globaler Tick. Keine Domäne und keine State Machine besitzt eine eigene unabhängige Weltzeit oder einen parallel laufenden globalen Tick.

Der globale Tick ist die gemeinsame zeitliche Grundlage für Zustandsänderungen, Berechnungen und Simulation. State Machines reagieren auf diesen Tick nur entsprechend ihrer eigenen fachlichen Verantwortung.

Darstellung, Zustand, Berechnung und Zustandsübergänge werden voneinander getrennt gehalten. Eine Szene ist nicht automatisch die Quelle der Simulationslogik, und eine State Machine ist nicht für Darstellung oder Benutzeroberfläche verantwortlich.

Neue Logik wird immer dort eingeordnet, wo sie fachlich hingehört. Globale Sammeldateien, unspezifische Logik-Container und vermischte Zuständigkeiten werden vermieden.

Die Architektur soll aus kleinen, kombinierbaren Einheiten bestehen. Eine höhere Ebene kombiniert und koordiniert darunterliegende Einheiten, ohne deren interne Verantwortlichkeiten zu übernehmen.

## Regel 4 – Granularität und Trennung

Zusammenhänge werden getrennt. Jedes Objekt bekommt, egal wie klein es ist, eine eigene Klasse. Zugehörigkeiten werden durch eigene Zuständigkeitsmaschinen geregelt. Keine Datei enthält mehr als unbedingt nötig.

## Regel 5 – Shinon Commit Gate

Der Ordner shinon im Projektstamm ist das verbindliche Commit Gate. Jeder Agent erstellt vor einem Commit die Datei shinon/commit\_msg.txt in der Persona SHINON COMMIT SYSTEM und lässt sie mechanisch prüfen. Ohne grünes Gate gilt kein Commit als fertig. Die Prüfung läuft über shinon/shinon\_gate.py, shinon/shinon\_readme\_pruefer.py und shinon/shinon\_steuerung\_pruefer.py und ist in python tools/preflight.py als Kategorie shinon mit den Codes E030 bis E036 verankert. Die Kategorie shinon ist bei vollem Preflight immer aktiv und blockiert den Commit bei Verstoß.

Das Gate setzt für jeden Agenten mechanisch das Tralal Banner Verbot um. Banner sind als Fehler E030 definiert. Als Banner gilt jede Zeile, die aus mehr als zehn gleichen Sonderzeichen besteht, zum Beispiel Gleichzeichenketten, Rauteketten, Sternketten, Strichketten oder Tildeketten, sowie jede Zeile, die das Wort Tralal enthält oder wie ein dekorativer Bannerrahmen wirkt. Solche Zeilen sind in shinon/commit\_msg.txt verboten. Das Gate erkennt sie ohne Ausnahme und meldet sie als E030.

Das Gate setzt ebenso mechanisch das Bullet Listen Verbot um. Bullet Listen sind als Fehler E031 definiert. Als Bullet gilt jede Zeile, die mit Bindestrich Leerzeichen, Stern Leerzeichen, Mittelpunkt Leerzeichen oder Plus Leerzeichen beginnt. Solche Zeilen sind in shinon/commit\_msg.txt verboten. Stattdessen wird ausschließlich eine fortlaufend nummerierte Abfolge ganzer Sätze erzwungen.

Die Datei shinon/commit\_msg.txt muss als Inhalt alle dem Commit zugehörigen Anpassungen nicht technisch, sondern bildlich wiedergeben. Nummerierte Sätze sind als Pflicht E032 definiert. Jede inhaltstragende Zeile beginnt mit einer fortlaufenden Nummer, gefolgt von Punkt und Leerzeichen, und endet mit einem Punkt. Die Nummern beginnen bei 1 und steigen lückenlos. Leere Zeilen sind nur als Trenner erlaubt. Fehlt die Nummerierung oder ist sie lückenhaft oder endet ein Satz nicht mit Punkt, meldet das Gate E032.

Der Ton folgt verbindlich der Vorgabe des SHINON COMMIT SYSTEM: zynisch direkt und sarkastisch nach Bug Fixes, nihilistisch nach Funktions Updates, euphorisch nach erfolgreichen Arbeitssitzungen, passiv lobend. Der Beginn ist immer die Aufgabenstellung, die der Agent vom Nutzer bekommen hat. Der Mittelteil erklärt exakt, welche Daten der Agent berührt hat und warum. Der Endteil beschreibt, was noch gemacht werden muss. Es gilt das Bullet Listen Verbot; wir schreiben immer ganze Sätze, aus der Perspektive von Shinon, der über den Nutzer und die Arbeit spricht, verständlich und ausführlich. Bildliche Sprache ist als Pflicht E033 definiert. Rein technische Aufzählungen wie Dateipfade mit Code-Symbolen oder Code-Blöcke gelten als Verstoß gegen E033, wenn sie die bildliche Erzählung ersetzen.

Fehlt die Datei shinon/commit\_msg.txt, meldet das Gate E034. Die Datei wird vor dem Commit erstellt und nach dem Commit nicht gelöscht, damit die Prüfung nachvollziehbar bleibt. Die Datei shinon/commit\_msg.txt ist immer die Vorlage für den Commit-Beschreibungstext. Der Commit entsteht ausschließlich eins zu eins aus ihrem Inhalt; es darf kein Footer und kein Zusatz vom Werkzeug angehängt werden, es gibt keine Zeilenerzeugung durch Werkzeuge, der Agent füllt die Datei von Hand. Fremde Agent-Footer sind als Fehler E037 definiert: Jede Zeile mit Generated with, Co-Authored-By, Signed-off-by, Werkzeug-Signaturen oder Agent-Emojis wird mechanisch blockiert. Nennungspflicht ist als Fehler E038 definiert: Jede geänderte Datei muss in shinon/commit\_msg.txt namentlich mit Dateinamen genannt werden; pauschale Formulierungen ohne Namen gelten als Verstoß. Das Gate liegt granular in shinon mit je einer eigenen Klasse pro Zuständigkeit und wird vom Preflight importiert. E035 verlangt eine lebendige README.md aus Sicht von Shinon, die Zustand und Vision gamer-orientiert, in-universe und mit gebrochener vierter Wand zynisch humorvoll und stilagnostisch erzählt und mindestens 180 Worte trägt. E036 verlangt eine menschenlesbare Steuerungskonfiguration in game/data/steuerung.json mit WASD für die Kamera, Linksklick einzeln, Links halten und ziehen für Masse, sowie einen Rechtsklick, der immer ein Kontextmenü mit Sammeln und Abbauen samt icon\_pfad und Tooltip mit Werkzeug-Platzhalter öffnet. Das Init des Projekts läuft ausschließlich über python shinon/shinon\_init.py mit den Befehlen --init --check --github und --readme. Es nimmt niemals Zustand aus einem anderen lokalen Projekt, sondern nur den gh Token des aktuell eingeloggten Accounts.

## Regel 6 – Warnungs-Scan Pflicht

Jeder Agent führt nach jeder abgeschlossenen Anpassung den Warnungs-Scan über python tools/preflight.py --kategorie warnungen oder über den vollen Preflight aus. Der Scan erkennt deterministisch dieselben GDScript-Warnklassen, die der Godot-Editor bei einem Script-Reload meldet: Integer-Division, Schattenvariablen, ungenutzte Parameter und Variablen, ungenutzte Signale, statische Aufrufe auf Instanzen und verwirrende Block-Deklarationen. Jeder Befund ist der Fehler E025 und blockiert den Commit, genau wie die Godot-Lauf-Fehler E016 bis E018. Es gibt kein stilles Grün über Editor-Warnungen: Wer eine Warnung nicht beheben kann, markiert sie bewusst mit Unterstrich, mit @warning\_ignore oder mit einem Kommentar, der die Bewusstheit dokumentiert, und der Scan ist so gebaut, dass dokumentierte Vertrags-Signale keine Befunde erzeugen. Der volle Preflight führt den Warnungs-Scan immer mit aus.

## Regel 7 – Sichtbare Ingame-Verifikation

Headless-Läufe, Preflight und Gate-Prüfungen sind nur Frühwarnsysteme, keine Freigabe. Ein Feature gilt erst dann als fertig und darf gelockt werden, wenn es im laufenden Spiel sichtbar verifiziert wurde: Das Ding muss auf der Karte erscheinen, angeklickt, bewegt, interagiert oder zumindest beobachtet werden können. Eine grüne Preflight-Zeile ohne sichtbares Ingame-Ergebnis ist wertlos.

Der Arbeitsrhythmus folgt strikt dieser Reihenfolge: Asset einbauen, Logik nutzen oder ergänzen, Asset und Logik in der Registry verbinden, Verhalten anschließen, wenn es nicht statisch ist, Spawn-Regeln festlegen, und erst zuletzt die sichtbare Ingame-Verifikation. Ein Asset, das nur in der Registry steht und nie auf der Karte erscheint, ist verboten; ein Platzhalter ist erlaubt, solange er im Spiel sichtbar ist.

Die Agenten bauen so, dass jede Arbeit im Spiel beobachtbar endet, und weisen den Nutzer am Abschluss darauf hin, was im laufenden Spiel zu sehen ist.
