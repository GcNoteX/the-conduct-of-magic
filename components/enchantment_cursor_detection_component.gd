class_name EnchantmentCursorDetectionComponent
extends Area2D

"""
This component is used to detect EnchantmentCursor type objects
and actions done alongside position of EnchantmentCursor
"""

signal hovered_over(s: EnchantmentCursorDetectionComponent)
signal unhovered_over(s: EnchantmentCursorDetectionComponent)
signal entered_selecting(s: EnchantmentCursorDetectionComponent)
signal exited_selecting(s: EnchantmentCursorDetectionComponent)


func _on_area_entered(area: Area2D) -> void:
	if area is EnchantmentCursor:
		emit_signal("hovered_over", self)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			emit_signal("entered_selecting", self)

func _on_area_exited(area: Area2D) -> void:
	if area is EnchantmentCursor:
		emit_signal("unhovered_over", self)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			emit_signal("exited_selecting", self)
