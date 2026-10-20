class_name PaletteLayout
extends Control

## Base for the experimental layouts that hold the palette cards (sheet 0004).
## The table builds the cards and hands them over; a layout only decides where they sit.

## Where the table should put this layout
enum Slot { OVERLAY, BOTTOM, LEFT }


func slot() -> Slot:
	return Slot.OVERLAY


## Replaces the cards shown, grouped into enchantments and materials
func set_cards(_enchantments: Array[PaletteCard], _materials: Array[PaletteCard]) -> void:
	pass


## Called when any card starts a drag, so a layout can get out of the way
func on_drag_started() -> void:
	pass


## Keyboard input the table passes on; returns true when the layout used it
func handle_key(_event: InputEventKey) -> bool:
	return false


func _clear(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
