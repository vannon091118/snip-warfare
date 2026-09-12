extends Label
class_name Menue_Unterschrift
## Der Erzähler unter der Bühne: Er zeigt den Untertitel des aktuellen
## Events und blendet ihn sanft ein und aus. Genau eine Verantwortung:
## Text sichtbar machen und wieder vergessen. Keine Ablauflogik.

const BLANDE_DAUER := 0.6

## Kategorie logik: Einblenden, Halten, Ausblenden.

func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 22)
	add_theme_color_override("font_color", Color("#F5EFDC"))
	add_theme_color_override("font_shadow_color", Color("#2B24198F"))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 2)
	modulate.a = 0.0

func zeige(unterschrift: String, dauer_ticks: int) -> void:
	# Ein laufender Blend-Tween wird abgebrochen, damit schnelle Folgen
	# nicht gegeneinander arbeiten.
	for alt: Tween in get_tree().get_processed_tweens():
		if alt != null and alt.is_valid() and alt.has_meta("unterschrift"):
			alt.kill()
	var halt := Kern_Weltuhr.sekunden_aus_ticks(dauer_ticks) - BLANDE_DAUER
	modulate.a = 0.0
	self.text = unterschrift
	var tween := create_tween()
	tween.set_meta("unterschrift", true)
	tween.tween_property(self, "modulate:a", 1.0, BLANDE_DAUER)
	tween.tween_interval(maxf(halt, 0.2))
	tween.tween_property(self, "modulate:a", 0.0, BLANDE_DAUER)
