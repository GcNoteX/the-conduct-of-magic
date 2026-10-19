class_name Counter
extends Control

## The counter side of the day, where customers bring their commissions. For now a placeholder:
## one button stands in for accepting a customer's commission and hands over a demo item.

signal item_accepted(definition: EnchantableItemDefinition)

@export var demo_items: Array[EnchantableItemDefinition] = []

var _next_item: int = 0
var _accept_button: Button
var _status_label: Label


func _ready() -> void:
	_build_ui()


## Called when the counter becomes the active side
func resume() -> void:
	_accept_button.disabled = demo_items.is_empty()


## Called before the counter is frozen
func suspend() -> void:
	_status_label.text = ""


## Hands over the next demo item, as if its commission were accepted
func accept_next() -> void:
	if demo_items.is_empty():
		return
	var definition := demo_items[_next_item % demo_items.size()]
	_next_item += 1
	item_accepted.emit(definition)
	_status_label.text = (
		"Accepted a %s. It's waiting on the inscribing table." % definition.display_name
	)


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("1c1a17")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 480
	box.add_theme_constant_override("separation", 12)
	centre.add_child(box)

	var title := Label.new()
	title.text = "The counter"
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = (
		"Customers will come here with their commissions. For now, accept a demo commission "
		+ "and its item will be on the inscribing table."
	)
	box.add_child(note)
	_accept_button = Button.new()
	_accept_button.text = "Accept a demo commission"
	_accept_button.custom_minimum_size.y = 44
	_accept_button.pressed.connect(accept_next)
	box.add_child(_accept_button)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", Color("f0d68a"))
	box.add_child(_status_label)
