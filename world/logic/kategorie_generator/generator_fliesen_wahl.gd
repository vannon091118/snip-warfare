extends RefCounted
class_name Welt_GeneratorFliesenWahl
## Fliesen-Wahl-Maschine des Generators: Prozentuale Fliesen-Verteilung
## passend zum Biom, bricht die monotone Standardkachel und erzeugt sofort
## optische Differenzierung. Tiefer = mehr Fels/Geröll, weniger organisches.

## Kategorie logik: Ziehung je Biom und Z-Ebene.

func ziehe_fliese(biom_id: String, zufall: Kern_Zufall, z_ebene: int = 0) -> String:
	var wurf := int(zufall.naechste_zahl() % 100)

	# Tiefen-Modifikator: Je tiefer (negativer), desto mehr Fels/Erz, weniger organisches
	var tiefe := absi(z_ebene)  # 0, 1, 2, 3, 4
	var fels_bonus := tiefe * 8      # +8% Fels pro Ebene tiefer
	var geroell_bonus := tiefe * 5   # +5% Geröll pro Ebene tiefer
	var erde_malus := tiefe * 6      # -6% organische Böden pro Ebene tiefer

	match biom_id:
		"gemaaessigt":
			# Oberfläche: wiese 55, waldboden 25, boden 20
			# Z-1: wiese 49, waldboden 22, boden 14, geroell +5, fels +8
			# Z-2: wiese 43, waldboden 19, boden 8, geroell +10, fels +16
			if wurf < 55 - erde_malus:
				return "wiese"
			elif wurf < 80 - erde_malus:
				return "waldboden"
			elif wurf < 85 - erde_malus + geroell_bonus:
				return "geroell"
			elif wurf < 95 - erde_malus + geroell_bonus + fels_bonus:
				return "fels"
			else:
				return "boden"
		"steppe":
			# Oberfläche: boden 45, acker 30, sand 25
			# Tiefer: mehr fels/geroell, weniger sand/acker
			if wurf < 45 - erde_malus:
				return "boden"
			elif wurf < 75 - erde_malus:
				return "acker"
			elif wurf < 85 - erde_malus + geroell_bonus:
				return "geroell"
			elif wurf < 95 - erde_malus + geroell_bonus + fels_bonus:
				return "fels"
			else:
				return "sand"
		"tundra":
			# Oberfläche: boden 45, geroell 30, fels 25
			# Tiefer: noch mehr fels/geroell
			if wurf < 45 - erde_malus:
				return "boden"
			elif wurf < 75 - erde_malus + geroell_bonus:
				return "geroell"
			elif wurf < 95 - erde_malus + geroell_bonus + fels_bonus:
				return "fels"
			else:
				return "geroell"
		_:
			# Fallback: tiefeabhängig
			if wurf < 50 - erde_malus:
				return "boden"
			elif wurf < 70 - erde_malus + geroell_bonus:
				return "geroell"
			else:
				return "fels"
