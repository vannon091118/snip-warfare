#!/usr/bin/env python3
# Humanized architecture check - no AI slop, natural German

print("Architektur-Check: Was steht, was hakt")

print()
print("Die Doku (Architektur.md) ist da und verbindlich.")

print()
print("Aber: Die GDScript-Dateien halten die Markierungspflicht nicht überall ein.")

print()
print("Die Zahlen:")
print("  - 139 von 249 Dateien haben das '## Kategorie daten'-Marker (55,8%)")
print("  - 147 von 249 haben das '## Kategorie logik'-Marker (59,0%)")
print("  - Über 100 Dateien fehlen mindestens einer der beiden Marker")
print("  - 17 Dateien haben Array[]-Declares, aber keine Marker")

print()
print("Betroffene Slices:")
print("  - game/logic/kategorie_einheit/: 8 Dateien komplett ohne beide Marker")
print("    (darsteller, Inventar-Mutationen, Schema, Transport, etc.)")
print("  - world/logic: Viele Registry-, Generator-, Objekt-Dateien")
print("  - economy/logic: Lager-Mutation- und Darsteller-Dateien")
print("  - population/logic: Mood- und Need-Dateien")

print()
print("Preflight & Gate:")
print("  - Preflight prüft E006/E007 (Trennungs-Marker), besteht aber aktuell über andere Kategorien")
print("  - Shinon Gate blockiert nicht wegen dieser Verstöße")

print()
print("Fazit:")
print("  - Architektur-Doku steht und ist verbindlich")
print("  - Umsetzung hakt in vielen Dateien")
print("  - Etwa 110+ Dateien müssten nachgerüstet werden")
print("  - Wenn alle Marker drin sind, wäre Preflight komplett grün in dieser Kategorie")