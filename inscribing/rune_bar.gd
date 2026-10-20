class_name RuneBar
extends HBoxContainer

## Shows the runes the player would hold at the end of the disenchant plan: one coloured chip and
## count per rune type, in the same colours as the chips on the board's lines.

var _counts: Array[Label] = []


func _init() -> void:
	add_theme_constant_override("separation", 14)
	var title := Label.new()
	title.text = "Runes"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	for i in RuneSet.NAMES.size():
		var chip := Panel.new()
		chip.custom_minimum_size = Vector2(18, 18)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var style := StyleBoxFlat.new()
		style.bg_color = BoardView.RUNE_COLORS[i]
		style.set_corner_radius_all(9)
		style.border_color = Color.BLACK
		style.set_border_width_all(1)
		chip.add_theme_stylebox_override("panel", style)
		add_child(chip)
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 18)
		add_child(label)
		_counts.append(label)
	show_runes(RuneSet.new())


func show_runes(runes: RuneSet) -> void:
	var counts := runes.to_array()
	for i in counts.size():
		_counts[i].text = "%s %d" % [RuneSet.NAMES[i], counts[i]]
