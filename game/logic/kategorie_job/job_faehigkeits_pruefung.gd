extends RefCounted
class_name Job_FaehigkeitsPruefung
## Prueft, ob ein Job zu einer Einheit passt: Verletzungen blockieren den Job,
## und die Tragekraft muss reichen. Die Grenzwerte stehen in der Konfiguration,
## die Aussagen ueber den Koerper liefert die Vital-Maschine.


static func kann(konfiguration: Dictionary, job_id: String, vital: Einheit_VitalStatus) -> bool:
	if vital == null:
		return false
	for mod in vital.aktive_modifikatoren:
		if mod.blockiert_job(job_id):
			return false
	var mindest_tragekraft := int(konfiguration.get("mindest_tragekraft", 0))
	var basis_tragekraft := int(konfiguration.get("basis_tragekraft", 10))
	return vital.effektive_tragekraft(basis_tragekraft) >= mindest_tragekraft
