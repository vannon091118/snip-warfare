extends SceneTree
## Sonde: Protokolliert den Arbeitsloop Schritt fuer Schritt, damit sichtbar
## wird, an welcher Stelle der Folgeauftrag verloren geht.

func _initialize() -> void:
	var modell := Welt_Model.new()
	modell.karte_erzeugen(8, 8, "boden")
	modell.objekt_hinzufuegen("baum", Vector2(200, 200))
	modell.objekt_hinzufuegen("baum", Vector2(600, 200))
	var manager := Einheit_Manager.new()
	manager.einrichten(modell, null, Einheit_Ressourcen.new())
	manager.einheit_hinzufuegen(Vector2(200, 200))
	manager.job_vergeben(0, "holzfaeller", Job_Basis.ZielTyp.OBJEKT, 0, Vector2(200, 200))
	var status: Einheit_Status = manager.einheit_status(0)
	print("START zustand=%d ziel=%d knoten=%d" % [status.zustand, status.aktuelles_ziel_index,
		status.job_loop_gefragt.get_connections().size()])
	for schritt in 260:
		manager._auf_tick(1, 1.0 / 24.0)
		if schritt % 20 == 0 or status.job == null:
			print("t=%d zustand=%d ziel=%d pos=%s job=%s" % [schritt, status.zustand,
				status.aktuelles_ziel_index, str(status.welt_position), str(status.job)])
	print("ENDE zustand=%d ziel=%d" % [status.zustand, status.aktuelles_ziel_index])
	quit()
