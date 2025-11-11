@tool
class_name Enchantment
extends Node2D

"""
- Holds the Enchantment in the form of a Map
"""

signal activated
signal deactivated

@export var enchant_name: String = "NULL"

@export var enodes: Array[EnchantmentNode] = []
@export var elines: Array[EnchantmentLine] = []

var is_activated: bool = false

@onready var tween: Tween = null

func _ready() -> void:
	add_to_group("enchantment")
	enodes.clear()
	elines.clear()

	for child in get_children():
		if child is EnchantmentNode:
			enodes.append(child)
		elif child is EnchantmentLine:
			elines.append(child)

	_initialize_enchantment()
	# prepare tween but don’t run yet
	tween = create_tween()
	tween.stop()  # we’ll restart it manually

func _initialize_enchantment() -> void:
	deactivate_enchantment() # Resetting ensures safe state
	update_enchantment()

func update_enchantment() -> void:
	"""
	Attempt to activate the enchantment
	"""
	print("Updating Enchantment")
	if Engine.is_editor_hint(): # I do not want to make material tool scripts for now, enchantment updating checks materials, so I will disable this
		return

	var activated_nodes = 0
	for node in enodes:
		var res = node.update_activation()
		if res: # True means update caused enode to activate
			activated_nodes += 1

	if activated_nodes >= enodes.size() and !is_activated:
		activate_enchantment()
	elif activated_nodes < enodes.size() and is_activated:
		deactivate_enchantment()


func activate_enchantment() -> void:
	print("Activating Enchantment")
	is_activated = true
	emit_signal("activated")
	_start_glow_animation()

func deactivate_enchantment() -> void:
	print("Deactivating Enchantment")
	is_activated = false
	emit_signal("deactivated")
	_stop_glow_animation()

# --- ✨ Glow Animation ---
func _start_glow_animation() -> void:
	if tween and tween.is_running():
		return

	# make a tween that loops
	tween = create_tween().set_loops()

	# pulse modulate from normal to bright white, then back
	tween.tween_property(self, "modulate", Color(1.6, 1.6, 1.6), 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_glow_animation() -> void:
	if tween:
		tween.kill()
	modulate = Color(1, 1, 1)  # reset to normal brightness
