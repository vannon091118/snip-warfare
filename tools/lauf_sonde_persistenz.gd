extends SceneTree
## Sonde: Benennt den echten Unterschied nach dem Speicher-Rundlauf des
## Welt-Modells, Schluessel fuer Schluessel, statt nur "nicht identisch".

func _initialize() -> void:
	var modell := Welt_Model.new()
	var generator := Welt_Generator.new()
	generator.welt_erzeugen(modell, 12345, "gemaaessigt")
	var original := modell.nach_woerterbuch()
	var runde := Welt_Model.new()
	runde.aus_woerterbuch(original)
	var zurueck := runde.nach_woerterbuch()
	for schluessel: String in original.keys():
		if str(original[schluessel]) != str(zurueck.get(schluessel)):
			print("UNTERSCHIED bei '%s'" % schluessel)
			_zeige(original[schluessel], zurueck.get(schluessel))
	print("SONDE FERTIG")
	quit()

func _zeige(a: Variant, b: Variant) -> void:
	if typeof(a) == TYPE_ARRAY and typeof(b) == TYPE_ARRAY:
		var liste_a: Array = a
		var liste_b: Array = b
		print("  laenge %d vs %d" % [liste_a.size(), liste_b.size()])
		for i in mini(liste_a.size(), liste_b.size()):
			if str(liste_a[i]) != str(liste_b[i]):
				print("  [%d] A=%s" % [i, str(liste_a[i])])
				print("  [%d] B=%s" % [i, str(liste_b[i])])
				return
		print("  kein Elementunterschied gefunden")
		return
	if typeof(a) == TYPE_DICTIONARY and typeof(b) == TYPE_DICTIONARY:
		var da: Dictionary = a
		var db: Dictionary = b
		print("  schluessel %d vs %d" % [da.size(), db.size()])
		for k: String in da.keys():
			if str(da[k]) != str(db.get(k)):
				print("  [%s] A=%s" % [k, str(da[k])])
				print("  [%s] B=%s" % [k, str(db.get(k))])
				return
		print("  kein Feldunterschied gefunden")
		return
	print("  A=%s" % str(a))
	print("  B=%s" % str(b))
