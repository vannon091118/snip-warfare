extends Job_Basis
class_name Job_Graben
## Job zum Graben: Zielt auf Fels-Tiles (z_ebene 0), schädigt deren Leben.
## Bei 0 Leben wird das Tile entfernt und die Ebene darunter (Z-1) enthüllt.
## Alle Werte stehen zentral in game/data/job_config.json.

func ziel_typ() -> ZielTyp:
	return ZielTyp.OBJEKT

func _passt_zu_objekt_fallback(element_id: String) -> bool:
	# Zielt auf Fels-Tiles und Geröll als abbaubare Hindernisse
	return element_id == "fels" or element_id == "geroell"

func graben_ausfuehren(model: Welt_Model, x: int, y: int, z_ebene: int = 0) -> bool:
	# Hauptfunktion: wird vom Job-System aufgerufen wenn Einheit gräbt
	var tile_id := model.fliese(x, y, z_ebene)
	if tile_id != "fels" and tile_id != "geroell":
		return false
	
	# Schaden aus Konfiguration
	var schaden := int(konfiguration.get("graben_schaden", 25))
	
	# Leben anwenden (initialisiert bei Generierung aus Katalog)
	var neues_leben := model.tile_leben_schaden(x, y, z_ebene, schaden)
	
	if neues_leben <= 0:
		# Tile wurde entfernt -> Decke-entfernt Signal ausstoßen		var pos := Vector2(x * model.kachel_groesse + model.kachel_groesse / 2.0,
						  y * model.kachel_groesse + model.kachel_groesse / 2.0)
		var bus := Kern_SignalBus.bus()
		if bus != null and bus.has_signal("decken_entfernt"):
			bus._emit_decke_entfernt(pos, z_ebene)
		return true
	return false

func tile_leben_initialisieren_fuer_kachel(model: Welt_Model, x: int, y: int, z_ebene: int) -> void:
	# Wird bei Chunk-Generierung aufgerufen: Initialisiert Leben aus Katalog
	var tile_id := model.fliese(x, y, z_ebene)
	if tile_id != "fels" and tile_id != "geroell":
		return
	var registry := Welt_Registry.new()
	var kachel_eintrag := registry.finde_objekt(tile_id)
	var max_leben := 100
	if kachel_eintrag != null and kachel_eintrag.schluessel_daten.has("leben"):
		max_leben = int(kachel_eintrag.schluessel_daten["leben"])
	model.tile_leben_initialisieren(x, y, z_ebene, max_leben)