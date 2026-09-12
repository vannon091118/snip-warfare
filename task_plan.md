# Plan: Social-Unterdomäne — Ethik und Image je Bewohner

Version: V0.01

## Ziel
Eine modulare, datengetriebene Sozial-Unterdomäne, die je Bewohner zwei Wahrheiten misst: die **Ethik** (der echte Charakter, aus eigenen Taten gewachsen) und das **Image** (das Außenbild aus eigener Beobachtung plus Gehörtem, je Beobachter verschieden). Beide speisen das Mood-System über schmale Lese-Schnittstellen, ohne es umzubauen. Config-driven, ein globaler Tick, Performance durch Erinnerungs-Limit und getaktetes Gerede.

## Adversarial-Befund gegen die Projektverfassung (geprüft, korrigiert)
1. **Verfassungs-Fundament schlägt E012-Muster-Zwang:** Der Vertrag sagt: Der eingebaute hash() ist nur pro Engine-Version stabil; Hashwerte für Ableitung kommen nur aus Kern_Hash. Soz_* Dateien fallen unter das E012-BUILT-IN-HASH-Verbot und die ZEIT_SEED_MUSTER-Familie. Praxis: Keine eigenen Seeds im Soz-Code. Werte-Gleichheit (Ethik, Glaube) wird ohne RNG erreicht: Der Glaube ist ein reines Anhäufen von Gewichten, kein Würfeln. Gerede-Paare werden deterministisch per Index/Position berechnet, nicht gezogen. Wenn eine Zufalls-Schattierung nötig wird, nur via Kern_Zufall.abgeleitet_fuer() mit Tat-Identität als Seed (Weltzustand, nicht Uhr). Fazit: Plan passt, wenn Maschinen zustandsbasiert bleiben.
2. **Domänen-Grenzen (Regel 5) sauber:** Social ist Unterdomäne neben Population, nicht darunter. Jagd/Kannibalismus bleiben in der Ernte-Maschine und Verhaltens-Maschine; die Soz-Domäne hört nur auf deren Signale (Observer-Spitze), sie verändert keine Fremdlogik. Umgekehrt liest Pop_MoodMaschine über die Soz-Lese-Schnittstelle. Keine Diagonal-Schreibvorgänge.
3. **Präfix Soz_ in tools/preflight/kern.py (KATEGORIE_PRAEFIXE) eintragen** vor jeder Datei-Anlage, sonst wirft E001 beim ersten Preflight. Ordner sozial/ → Soz_, kein "Social"-Präfix, da E001 die Präfixe über die Tabelle prüft.
4. **KATEGORIE_PRAEFIXE-Verstoß vermeiden:** "Social" als Präfix kollidiert mit dem verfassungswidrigen Selbstbild "keine Logik ohne Verantwortung". Soz_ ist kurz, deutsch, eindeutig.
5. **E041 LOC-Grenze:** Jede Datei sofort unter 100 LOC planen; Manager ist nur Fassade, die zwei Maschinen tragen die Logik getrennt. Bei Überschreitung: Zerlegen, kein Nachlass-Eintrag.
6. **Globale Zeit:** Nur die Weltuhr-Ticks; die Soz-Domäne besitzt keinen eigenen Timer. Gerede-Takt als Zähler über auf_tick(nummer, delta).
7. **Index- und Shinon-Pflicht:** Nach Slice die Dateien in INDEX (tools/index_generieren.py) nachziehen, commit_msg.txt als Vorlage, max 10-15 Dateien pro Slice.
8. **Regel 9 Beweis:** Ein Beweislauf (tools/lauf_pruefung_sozial.gd) zeigt die Kette Tat → Zeugen → Glaube → Gerede → Blase als sichtbare Zustände, nicht nur als grüne Preflight-Zeile.

## Korrigierte Struktur
```
social/
  data/
    sozial_regeln.json        # Taten-Gewichte, Zeugen-Regeln, Gerede-Takt, Dämpfung, Image-Stufen, Reaktions-Anker
  logic/
    sozial_tat.gd             # Soz_Tat: Beobachtungs-Datenklasse (wer, was, wo, tick)
    sozial_ethik_ledger.gd    # Soz_EthikLedger: privater Kontostand + Ringpuffer (Tiefe aus Daten)
    sozial_image_glaube.gd    # Soz_ImageGlaube: {Wert, Konfidenz} eines Beobachters über ein Ziel
    sozial_zeugen_maschine.gd # Soz_ZeugenMaschine: Radius-Verteilung, füllt Glauben (u. Ledger des Täters)
    sozial_geraede_maschine.gd# Soz_GeraedeMaschine: getaktete Paar-Stichprobe, Dämpfung, Konfidenz-Grenzen
    sozial_manager.gd         # Soz_Manager: Fassade an der Weltuhr, Lese-Schnittstelle für Mood/Blase
```

## Phasen

### Phase 1 — Vertragstest zuerst (TDD, Status: in_progress)
- test_sozial_domäne.py schreibt die Verträge als Test: Tat → Glaube der Zeugen, Gerede → Dämpfung, Erinnerung begrenzt, Mood-Anker nur über Lesen, keine Zeitquelle im Soz-Code, keine E012-Muster, Schwellen nur im JSON.
- Der Test rotet zuerst, grüner Stand nach Phase 2.

### Phase 2 — Datenpool und Bausteine (Status: pending)
- sozial_regeln.json mit allen Zahlen (Gewichte, Radius, Erinnerungstiefe, Gerede-Takt, Dämpfung, Palette-Wechsel, Image-Stufen, Reaktions-Anker).
- Soz_Tat, Soz_EthikLedger (Ringpuffer), Soz_ImageGlaube als reine Daten-/Rechenklassen.

### Phase 3 — Maschinen (Status: pending)
- Soz_ZeugenMaschine: registriert Taten, verteilt im Radius, mischt Glauben ohne RNG.
- Soz_GeraedeMaschine: Zähler über den Weltuhr-Tick, kleine Paar-Stichprobe deterministisch per Index, Dämpfung pro Stufe, Konfidenz sinkt pro Übertrag.
- Soz_Manager: Fassade, Fassadenebene bleibt unter LOC-Grenze.

### Phase 4 — Anbindung an Population (Status: pending)
- Ein schmales Signal tat_geschehen an der Ernte-/Verhaltens-Maschine (Jagd, Kannibalismus-Fall),Soz_Manager hört nur zu.
- Pop_MoodMaschine liest Image/Ethik des Umfelds über die Manager-Schnittstelle und gewichtet den Reaktions-Anker aus sozial_regeln.json ein.
- Pop_Denkblase erzählt Image-Sprünge ("Ich halte ihn für...") als Observer, ohne Logik zu tragen.

### Phase 5 — Beweis und Verifikation (Status: pending)
- Headless-Beweislauf tools/lauf_pruefung_sozial.gd: drei Einheiten, eine Tat, Zeugen-Glaube sichtbar, Gerede-Träger-Paare sichtbar, Blase erzählt.
- Preflight grün (inkl. E001 mit Soz_ Präfix), Index-Familie und Statuszahlen nachziehen, Shinon-Slices (max 10-15 Dateien), Push nur wenn der Nutzer es verlangt.

## Performance-Regeln
- Zeugen-Radius klein (Daten).
- Erinnerungstiefe begrenzt: Ringpuffer verwirft Ältestes.
- Gerede: pro Takt nur eine Stichprobe von Paaren, kein O(n²)-Vollvergleich.
- Image nur als {Wert, Konfidenz} pro Paar (Beobachter, Ziel), keine Historie, keine Skalenexplosion.
- Registrierung neuer Einheiten über den Manager, keine Scans über die gesamte Welt pro Tick.

## Offene Fragen
- Sollen gebundene Tiere als Zeugen zählen? (Vorerst: nein; bindung.json kennt nur "wird von der Moral geschützt".)
- Image zwischen Einheiten verschiedener Karten? (Vorerst: nein, Karten-Grenze bleibt hart.)
- Dämpfung: Additiv oder multiplikativ? (Vorerst: multiplikativ aus Daten, einmal pro Stufe.)
