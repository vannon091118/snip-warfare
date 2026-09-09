extends Tier_Baer
class_name Tier_Eisbaer
## Kombinations-Beispiel: Wiederverwendung der Bären-Logik.
## Die Variante entsteht ausschließlich über Registry-Kombination,
## ohne neue Verhaltensklasse: SVG eisbär.svg + Logik baer_verfolgen
## + Modifikator aggressiv (Faktor 1.2). Keine neue Maschine nötig;
## der Faktor skaliert Zeit und Geschwindigkeit über die Weltuhr.

var eisbaer_modifikator_id: String = "aggressiv"
var eisbaer_faktor: float = 1.2
var eisbaer_logik_id: String = "baer_verfolgen"

func aus_verhalten_eintrag(eintrag: Dictionary) -> void:
	super.aus_verhalten_eintrag(eintrag)
	# Kombinationsfelder aus dem Katalog übernehmen; Defaults zeigen die Kombination.
	eisbaer_logik_id = logik_id if logik_id != "" else "baer_verfolgen"
	eisbaer_modifikator_id = modifikator_id
	eisbaer_faktor = faktor if faktor != 0.0 else 1.2
	# Sichtbare Felder angleichen, damit Renderer und Status dieselben Werte nutzen.
	baer_logik_id = eisbaer_logik_id
	baer_modifikator_id = eisbaer_modifikator_id
	baer_faktor = eisbaer_faktor
	logik_id = eisbaer_logik_id
	modifikator_id = eisbaer_modifikator_id
	faktor = eisbaer_faktor
