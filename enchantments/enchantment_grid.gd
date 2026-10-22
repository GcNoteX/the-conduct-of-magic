@tool
class_name EnchantmentGrid
extends Area2D
## An enchantment placed on the legacy play map: a group of EnchantmentNodes joined by
## EnchantmentLines. It activates once every one of its nodes is activated.

signal activated
signal deactivated

## The grid's EnchantmentNode children, gathered in _ready. Runtime state.
var enodes: Array[EnchantmentNode] = []
## The grid's EnchantmentLine children, gathered in _ready. Runtime state.
var elines: Array[EnchantmentLine] = []
var is_activated: bool = false
var overlaps: Array[Area2D]

@onready var tween: Tween = null


func _ready() -> void:
	add_to_group(Groups.ENCHANTMENT)
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

	# Setup mask and layers
	collision_layer = CollisionLayers.bit(CollisionLayers.ENCHANTMENT_GRID)
	collision_mask = (
		CollisionLayers.bit(CollisionLayers.ENCHANTMENT_GRID)
		| CollisionLayers.bit(CollisionLayers.ENCHANTMENT_MAP_COMP)
	)

	# Setup self signals so do not have to do it via scene
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


## Attempt to activate the enchantment
func update_enchantment() -> void:
	# I do not want to make material tool scripts for now, enchantment updating checks
	# materials, so I will disable this
	if Engine.is_editor_hint():
		return

	var activated_nodes := 0
	for node in enodes:
		node.update()
		if node.is_activated:  # True means update caused enode to activate
			activated_nodes += 1

	if activated_nodes >= enodes.size() and not is_activated:
		activate_enchantment()
	elif activated_nodes < enodes.size() and is_activated:
		deactivate_enchantment()


func kill_enchantment() -> void:
	for line in elines:
		line.kill_line()
	for node in enodes:
		node.kill_node()
	queue_free()


func activate_enchantment() -> void:
	is_activated = true
	activated.emit()
	_start_glow_animation()


func deactivate_enchantment() -> void:
	is_activated = false
	deactivated.emit()
	_stop_glow_animation()


# Area control


func disable_detection() -> void:
	for n in enodes:
		n.disable_detection()

	for l in elines:
		_disable_area(l)


func enable_detection() -> void:
	for n in enodes:
		n.enable_detection()

	for l in elines:
		_enable_area(l)


func _initialize_enchantment() -> void:
	deactivate_enchantment()  # Resetting ensures safe state
	update_enchantment()


# Animations


# --- ✨ Glow Animation ---
func _start_glow_animation() -> void:
	if tween and tween.is_running():
		return

	# make a tween that loops
	tween = create_tween().set_loops()

	# pulse modulate from normal to bright white, then back
	var brighten := tween.tween_property(self, "modulate", Color(1.6, 1.6, 1.6), 0.6)
	brighten.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var dim := tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.6)
	dim.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_glow_animation() -> void:
	if tween:
		tween.kill()
	modulate = Color(1, 1, 1)  # reset to normal brightness


func _disable_area(a: Area2D) -> void:
	a.monitoring = false
	a.monitorable = false
	for shape in a.get_children():
		if shape is CollisionShape2D:
			shape.disabled = true


func _enable_area(a: Area2D) -> void:
	a.monitoring = true
	a.monitorable = true
	for shape in a.get_children():
		if shape is CollisionShape2D:
			shape.disabled = false


func _on_area_entered(a: Area2D) -> void:
	if is_ancestor_of(a):
		return
	overlaps.append(a)


func _on_area_exited(a: Area2D) -> void:
	if is_ancestor_of(a):
		return
	overlaps.erase(a)
