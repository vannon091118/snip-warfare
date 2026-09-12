extends RefCounted
class_name Job_ZeitRechnung
## Die Arbeitszeit eines Jobs als reine Rechnung. Sie kennt drei Quellen: den
## festen Wert aus der Konfiguration, den Faktor des Jobs und den Faktor seines
## Ziels. Faktor ueber eins heisst schneller, also kuerzere Zeit.


static func ticks_fuer_faktor(faktor: float) -> int:
	return Kern_Weltuhr.ticks_aus_faktor(faktor)


static func harvest_zeit_ticks(konfiguration: Dictionary, faktor: float, ziel_faktor: float) -> int:
	## Feste Zeit aus den Daten oder aus dem Faktor abgeleitet; danach skalieren
	## der Job-Faktor und der Ziel-Faktor dieselbe Basis, nie unter einen Tick.
	var basis := -1
	if konfiguration.has("faktor") and not konfiguration.has("harvest_zeit_ticks"):
		basis = ticks_fuer_faktor(faktor)
	elif konfiguration.has("harvest_zeit_ticks"):
		basis = int(konfiguration.get("harvest_zeit_ticks", 24))
	if basis < 0:
		basis = 24
	if konfiguration.has("faktor"):
		basis = maxi(int(round(float(basis) / faktor)), 1)
	return maxi(int(round(float(basis) / ziel_faktor)), 1)
