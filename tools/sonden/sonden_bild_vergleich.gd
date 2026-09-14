extends RefCounted
class_name Sonden_BildVergleich
## Eigene Zuständigkeit: Bilder mechanisch vergleichen, nie interpretieren.
## Der Vergleicher liefert Zahlen — Weissanteil, Regionsdelta, Heizbild — und
## uebernimmt weder das Speichern noch das Melden. Damit bleibt der Laeufer
## fuer die Reihenfolge zustaendig und dieser hier fuer die Messung.

const RASTER := 3

static func weiss_anteil(bild: Image) -> float:
	## Anteil fast weisser, entsaettigter Pixel als Deckungsmass.
	if bild == null:
		return 1.0
	var breite := bild.get_width()
	var hoehe := bild.get_height()
	if breite <= 0 or hoehe <= 0:
		return 1.0
	var schritt := maxi(breite * hoehe / 4000, 1)
	var weiss := 0
	var gesamt := 0
	for i in range(0, breite * hoehe, schritt):
		var c := bild.get_pixel(i % breite, i / breite)
		gesamt += 1
		if c.v > 0.85 and c.s < 0.15:
			weiss += 1
	return float(weiss) / float(maxi(gesamt, 1))

static func dunkel_anteil(bild: Image, schwelle: float = 0.16) -> float:
	## Anteil fast schwarzer Pixel. Ein Bild, das zum Grossteil schwarz ist,
	## zeigt dem Spieler nichts — genau das wird hier messbar.
	if bild == null:
		return 1.0
	var breite := bild.get_width()
	var hoehe := bild.get_height()
	if breite <= 0 or hoehe <= 0:
		return 1.0
	var schritt := maxi(breite * hoehe / 4000, 1)
	var dunkel := 0
	var gesamt := 0
	for i in range(0, breite * hoehe, schritt):
		var c := bild.get_pixel(i % breite, i / breite)
		gesamt += 1
		if maxf(c.r, maxf(c.g, c.b)) < schwelle:
			dunkel += 1
	return float(dunkel) / float(maxi(gesamt, 1))


static func regionen(a: Image, b: Image) -> Array[float]:
	## Mittleres Delta je Rasterfeld: zeigt, WO sich etwas bewegt hat.
	var ergebnis: Array[float] = []
	for i in Sonden_BildVergleich.RASTER * Sonden_BildVergleich.RASTER:
		ergebnis.append(0.0)
	if a == null or b == null:
		return ergebnis
	var breite := mini(a.get_width(), b.get_width())
	var hoehe := mini(a.get_height(), b.get_height())
	if breite <= 0 or hoehe <= 0:
		return ergebnis
	var r := Sonden_BildVergleich.RASTER
	for feld_y in r:
		for feld_x in r:
			var summe := 0.0
			var zaehler := 0
			var y0 := feld_y * hoehe / r
			var y1 := (feld_y + 1) * hoehe / r
			var x0 := feld_x * breite / r
			var x1 := (feld_x + 1) * breite / r
			for y in range(y0, y1, 8):
				for x in range(x0, x1, 8):
					var ca := a.get_pixel(x, y)
					var cb := b.get_pixel(x, y)
					summe += abs(ca.r - cb.r) + abs(ca.g - cb.g) + abs(ca.b - cb.b)
					zaehler += 1
			if zaehler > 0:
				ergebnis[feld_y * r + feld_x] = summe / float(zaehler)
	return ergebnis

static func gesamt(a: Image, b: Image) -> float:
	## Ein Zahlenwert fuer den Vorher-Nachher-Vergleich zweier Bilder.
	var felder := Sonden_BildVergleich.regionen(a, b)
	if felder.is_empty():
		return 0.0
	var summe := 0.0
	for f in felder:
		summe += f
	return summe / float(felder.size())

static func heizbild(a: Image, b: Image) -> Image:
	## Rot heisst veraendert, Blau heisst gleich: das Artefakt zum Nachsehen.
	var breite := mini(a.get_width(), b.get_width())
	var hoehe := mini(a.get_height(), b.get_height())
	var out := Image.create(breite, hoehe, false, Image.FORMAT_RGB8)
	for y in hoehe:
		for x in breite:
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			var d: float = abs(ca.r - cb.r) + abs(ca.g - cb.g) + abs(ca.b - cb.b)
			out.set_pixel(x, y, Color(d, 0.0, 1.0 - d))
	return out
