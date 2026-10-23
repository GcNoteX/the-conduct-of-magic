class_name CommissionCard
extends PanelContainer

## The customer's commission slip, pinned beside the board while you carve their item: who it is
## for, each enchantment they asked for (committed, planned or not started), the offer and what
## they would pay if they collected the item now.

const THEME := preload("res://counter/counter_theme.tres")
const DONE_COLOR := "#2f7a3a"
const PLANNED_COLOR := "#8a6a1c"
const MISSING_COLOR := "#a03028"

var _text: RichTextLabel


func _init() -> void:
	theme = THEME
	theme_type_variation = &"PaperPanel"
	_text = RichTextLabel.new()
	_text.theme_type_variation = &"PaperText"
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.add_theme_font_size_override("normal_font_size", 18)
	_text.add_theme_font_size_override("bold_font_size", 20)
	add_child(_text)


## Shows a commission, or hides the card when the item isn't a customer's
func show_commission(c: Commission) -> void:
	visible = c != null
	if c == null:
		return
	var slip := c.visit.slip
	var text := "[b]Commission for %s[/b]\n" % slip.customer_name
	var progress := c.progress()
	for i in progress.size():
		text += "%s\n" % _line(slip.enchantments[i], progress[i])
	text += "Offers %dg. Pays [b]%dg[/b] if collected now." % [slip.payment, c.payout()]
	_text.text = text


func _line(e: Enchantment, state: Commission.Progress) -> String:
	match state:
		Commission.Progress.DONE:
			return "[color=%s]✓ %s[/color]" % [DONE_COLOR, e.enchantment_name]
		Commission.Progress.PLANNED:
			return "[color=%s]○ %s (planned)[/color]" % [PLANNED_COLOR, e.enchantment_name]
	return "[color=%s]✗ %s[/color]" % [MISSING_COLOR, e.enchantment_name]
