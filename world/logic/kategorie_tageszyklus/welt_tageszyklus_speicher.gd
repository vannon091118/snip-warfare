extends RefCounted
class_name Welt_TagesZyklusSpeicher
## Persistenz des Tageszyklus: Eine eigene Zuständigkeit neben Takt und
## Darstellung. Sie kennt nur das Format der gespeicherten Werte und gibt sie
## sauber geklemmt zurück; der Zustand selbst bleibt in der Tageszyklus-Maschine.


static func sichern(tick_in_takt: int, helligkeit: float, phase: int) -> Dictionary:
	## Der Speicherstand des Tageszyklus, als reine Daten.
	return {"tick_in_takt": tick_in_takt, "helligkeit": helligkeit, "phase": phase}


static func laden(daten: Dictionary) -> Dictionary:
	## Liest einen Speicherstand und klemmt jeden Wert in seinen gültigen Bereich.
	return {
		"tick_in_takt": int(daten.get("tick_in_takt", 0)),
		"helligkeit": clampf(float(daten.get("helligkeit", 1.0)), 0.0, 1.0),
		"phase": clampi(int(daten.get("phase", 0)), 0, 3),
	}
