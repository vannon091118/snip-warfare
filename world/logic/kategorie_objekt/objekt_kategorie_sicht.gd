extends RefCounted
class_name Objekt_KategorieSicht
## Gefilterte Sicht der Objekt-Registry auf die Kategorien: Sie hält die
## Objekte je Kategorie und beantwortet die Kategorie-Fragen, ohne den
## Element-Katalog ein zweites Mal zu lesen.

var _objekte_nach_kategorie: Dictionary = {}

func leeren() -> void:
	_objekte_nach_kategorie.clear()

func merken(kategorie: String, objekt: Objekt_Basis) -> void:
	if not _objekte_nach_kategorie.has(kategorie):
		_objekte_nach_kategorie[kategorie] = []
	(_objekte_nach_kategorie[kategorie] as Array).append(objekt)

func der_kategorie(kategorie: String, alle: Array) -> Array[Objekt_Basis]:
	if _objekte_nach_kategorie.has(kategorie):
		var typisiert: Array[Objekt_Basis] = []
		for eintrag: Variant in _objekte_nach_kategorie[kategorie]:
			typisiert.append(eintrag as Objekt_Basis)
		return typisiert
	var gefundene: Array[Objekt_Basis] = []
	for objekt_ref: RefCounted in alle:
		var objekt := objekt_ref as Objekt_Basis
		if objekt != null and str(objekt.kategorie) == kategorie:
			gefundene.append(objekt)
	return gefundene

func kategorien(alle: Array) -> Array[String]:
	var gefundene: Array[String] = []
	for objekt_ref: RefCounted in alle:
		var objekt := objekt_ref as Objekt_Basis
		if objekt == null:
			continue
		var kategorie := str(objekt.kategorie)
		if not gefundene.has(kategorie):
			gefundene.append(kategorie)
	gefundene.sort()
	return gefundene
