extends SceneTree
## Beweislauf der Karten-Identität (Regel 9): Dieselben Eingaben muessen
## dieselbe Karte hervorbringen, byte-identisch, unabhaengig von Instanz und
## Reihenfolge. Der Lauf erzeugt dieselbe Welt dreimal aus getrennten
## Generator- und Modell-Instanzen, haengt vor dem dritten Lauf fremde
## Zufallsziehungen an und fragt zuletzt die Bytewahrheit: Jede Karte wird
## über den echten World-Speicher als JSON auf die Festplatte geschrieben,
## die Datei-Bytes werden gelesen und verglichen. Ein Vergleich über str()
## waere nur eine Wortwahrheit; dieser Lauf liest, was im Spielstand eines
## Spielers wirklich stünde. Ein negativer Beweis gehört dazu: Ein anderer
## Seed muss andere Bytes erzeugen, sonst bewiese ein nie fallender Zeuge
## nichts.
## Aufruf: godot --headless --path . --script tools/lauf_pruefung_determinismus.gd

const PRUEF_SEED := 12345
const ANDERER_SEED := 54321
const PRUEF_BIOM := "gemaaessigt"
const PRUEF_NAME := "determinismus_beweis"


func _initialize() -> void:
	_beweisen()


func _beweisen() -> void:
	var fehler := 0
	var rundlauf := Welt_Speicher.new()
	# 1) Doppelgenerierung aus getrennten Instanzen. Weder Generator noch
	#    Modell werden geteilt: Jede Karte entsteht aus ihrem eigenen
	#    Zustand, so wie zwei Spielsitzungen es auch tun wuerden.
	var modell_eins := Welt_Model.new()
	var modell_zwei := Welt_Model.new()
	var generator_eins := Welt_Generator.new()
	var generator_zwei := Welt_Generator.new()
	if not generator_eins.welt_erzeugen(modell_eins, PRUEF_SEED, PRUEF_BIOM):
		print("FEHLER: Erster Generierungslauf scheiterte")
		fehler += 1
	if not generator_zwei.welt_erzeugen(modell_zwei, PRUEF_SEED, PRUEF_BIOM):
		print("FEHLER: Zweiter Generierungslauf scheiterte")
		fehler += 1
	# 2) Wortwahrheit: Objektzahlen und ganze Woerterbuecher muessen
	#    uebereinstimmen, bevor die Bytewahrheit gefragt wird. Sie ist der
	#    erste Zeuge, nicht der einzige.
	if modell_eins.objekt_anzahl() != modell_zwei.objekt_anzahl():
		print("FEHLER: Objektzahlen weichen ab (%d gegen %d)" % [
			modell_eins.objekt_anzahl(), modell_zwei.objekt_anzahl()])
		fehler += 1
	var wort_eins := str(modell_eins.nach_woerterbuch())
	var wort_zwei := str(modell_zwei.nach_woerterbuch())
	if wort_eins != wort_zwei:
		print("FEHLER: Woerterbuecher weichen ab")
		fehler += 1
	# 3) Bytewahrheit: Beide Karten laufen als World unter demselben Namen
	#    durch den echten Speicher. Der zweite Lauf ueberschreibt die Datei
	#    des ersten, wie ein zweiter Spielstand unter gleichem Namen es
	#    taete; gelesen werden die Bytes von der Festplatte.
	var bytes_eins := _beweis_bytes_speichern_und_lesen(rundlauf, modell_eins)
	var bytes_zwei := _beweis_bytes_speichern_und_lesen(rundlauf, modell_zwei)
	if bytes_eins.is_empty() or bytes_zwei.is_empty():
		print("FEHLER: Eine der Beweis-Dateien fehlt auf der Festplatte")
		fehler += 1
	elif bytes_eins.size() != bytes_zwei.size():
		print("FEHLER: World-JSON-Laengen weichen ab (%d gegen %d Bytes)" % [
			bytes_eins.size(), bytes_zwei.size()])
		fehler += 1
	elif bytes_eins != bytes_zwei:
		var ab_stelle := _erste_abweichung(bytes_eins, bytes_zwei)
		print("FEHLER: World-JSON weicht ab (erste Stelle %d: %d gegen %d)" % [
			ab_stelle, bytes_eins[ab_stelle], bytes_zwei[ab_stelle]])
		fehler += 1
	else:
		print("OK: Beide Karten sind byte-identisch (%d Bytes World-JSON)" % bytes_eins.size())
	# 4) Reihenfolge-Unabhaengigkeit: Der dritte Lauf startet erst, nachdem
	#    ein fremder Kern_Zufall drei Zahlen gezogen hat. Die Karte darf
	#    von dieser Spieler-Spur nichts sehen, und auch hier gilt die
	#    Bytewahrheit, nicht nur das Woerterbuch.
	var fremd_spur := Kern_Zufall.new()
	fremd_spur.start_zustand_setzen(999999)
	for _ziehung in 3:
		fremd_spur.naechste_zahl()
	var modell_drei := Welt_Model.new()
	var generator_drei := Welt_Generator.new()
	if not generator_drei.welt_erzeugen(modell_drei, PRUEF_SEED, PRUEF_BIOM):
		print("FEHLER: Dritter Generierungslauf nach fremden Ziehungen scheiterte")
		fehler += 1
	elif str(modell_drei.nach_woerterbuch()) != wort_eins:
		print("FEHLER: Karte haengt an der Reihenfolge (fremde Ziehungen veraendern die Welt)")
		fehler += 1
	else:
		var bytes_drei := _beweis_bytes_speichern_und_lesen(rundlauf, modell_drei)
		if bytes_drei == bytes_eins:
			print("OK: Karte bleibt byte-identisch nach fremden Zufallsziehungen")
		else:
			print("FEHLER: Dritte Karte weicht in den Bytes ab (%d gegen %d Bytes)" % [
				bytes_drei.size(), bytes_eins.size()])
			fehler += 1
	# 5) Negativkontrolle: Ein anderer Seed muss andere Bytes erzeugen.
	#    Ein Zeuge, der nie faellt, beweist nichts; dieser Beweis zeigt,
	#    dass der Vergleich wirklich auf die Eingaben schaut.
	var modell_vier := Welt_Model.new()
	var generator_vier := Welt_Generator.new()
	generator_vier.welt_erzeugen(modell_vier, ANDERER_SEED, PRUEF_BIOM)
	var bytes_vier := _beweis_bytes_speichern_und_lesen(rundlauf, modell_vier)
	if bytes_eins.is_empty() or bytes_vier.is_empty():
		print("FEHLER: Beweis-Datei der Negativkontrolle fehlt")
		fehler += 1
	elif bytes_vier == bytes_eins:
		print("FEHLER: Verschiedene Seeds liefern byte-identische Karten, der Vergleich schaut nicht hin")
		fehler += 1
	else:
		print("OK: Anderer Seed ergibt andere Bytes (%d gegen %d Bytes), der Vergleich schaut hin" % [
			bytes_eins.size(), bytes_vier.size()])
	# 6) Sauberkeit: Die Beweis-Datei verschwindet wieder, damit der Lauf
	#    keine Spuren im Spielstand-Ordner hinterlaesst. Der Loesch-Beweis
	#    gilt nur, wenn sie danach wirklich weg ist.
	rundlauf.loeschen(PRUEF_NAME)
	if FileAccess.file_exists("user://".path_join(Welt_Speicher.ORDNER_NAME).path_join(PRUEF_NAME + ".json")):
		print("FEHLER: Beweis-Datei blieb auf der Festplatte liegen")
		fehler += 1
	if fehler == 0:
		print("ALLE DETERMINISMUS-PRUEFUNGEN GRUEN")
		quit(0)
	else:
		print("%d DETERMINISMUS-PRUEFUNGEN ROT" % fehler)
		quit(1)


func _beweis_bytes_speichern_und_lesen(rundlauf: Welt_Speicher, modell: Welt_Model) -> PackedByteArray:
	## Schreibt die Karte als World unter dem Beweis-Namen und liest die
	## Datei-Bytes zurueck. Der Weg ist der echte Spielstand-Weg: World-
	## Woerterbuch, JSON, Festplatte.
	var world := Welt_World.new()
	world.world_name = PRUEF_NAME
	world.map_hinzufuegen(modell, "karte_0", true)
	if not rundlauf.world_speichern(PRUEF_NAME, world):
		return PackedByteArray()
	var pfad := "user://".path_join(Welt_Speicher.ORDNER_NAME).path_join(PRUEF_NAME + ".json")
	var datei := FileAccess.open(pfad, FileAccess.READ)
	if datei == null:
		return PackedByteArray()
	var bytes := datei.get_buffer(datei.get_length())
	datei.close()
	return bytes


func _erste_abweichung(eins: PackedByteArray, zwei: PackedByteArray) -> int:
	## Erste abweichende Stelle benennen, damit die Fehlersuche nicht im
	## Nebel stochert.
	for i in eins.size():
		if eins[i] != zwei[i]:
			return i
	return -1
