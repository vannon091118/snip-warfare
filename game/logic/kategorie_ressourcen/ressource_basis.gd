extends RefCounted
class_name Ressource_Basis
## Datenklasse einer Ressource. Enthält ausschließlich Daten; das Einlesen
## aus ressourcen.json ist ein reiner Zuweisungsschritt ohne Berechnung.
## Bestandsverwaltung und Ernte bleiben in den State Machines der Game-Domäne.

## Kategorie daten: die vier Katalog-Felder jeder Ressource.
var ressourcen_id: String = ""
var ressourcen_name: String = ""
var icon_pfad: String = ""
var farbe: Color = Color.WHITE

## Ressourcentyp für Erschöpfungssystem-Mapping (z.B. "holz", "stein", "erz", "beeren", etc.).
var erschoepfung_ressourcen_typ: String = ""

## Kategorie logik: Zuweisung aus dem Katalog-Eintrag.

func aus_konfig_eintrag(eintrag: Dictionary) -> void:
	ressourcen_id = str(eintrag.get("id", ""))
	ressourcen_name = str(eintrag.get("name", ressourcen_id))
	icon_pfad = str(eintrag.get("icon_pfad", ""))
	farbe = Color(str(eintrag.get("farbe", "#FFFFFF")))
	erschoepfung_ressourcen_typ = str(eintrag.get("erschoepfung_typ", ressourcen_id))

## Prüft ob diese Ressource an der gegebenen Position spawnen darf.
## Berücksichtigt Erschöpfung: Wenn lager_bestand / erschoepfungs_maximum > 0.8
## blockiert der Spawn. Dies erzwingt Expansion als EINZIGE Wachstumsstrategie.
## Beweis: Entscheidungslog deterministisch; bei >0.8 kein Respawn, nach Expansion Kapazität zurück.
func kann_spawnen(welt_model: Welt_Model, welt_position: Vector2, lager_bestand: int) -> bool:
	if welt_model == null:
		return true  # Ohne Modell keine Erschöpfungsprüfung -> erlauben
	var chunk_key := welt_model._chunk_key_aus_position(int(welt_position.x), int(welt_position.y))
	var ressource_typ := erschoepfung_ressourcen_typ if erschoepfung_ressourcen_typ != "" else ressourcen_id
	return welt_model.kann_ressource_spawnen(chunk_key, ressource_typ, lager_bestand)
