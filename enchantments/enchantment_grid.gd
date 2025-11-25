@tool
class_name EnchantmentGrid
extends Area2D

"""
- The grid of an Enchantment in the form of a Map
"""

signal activated
signal deactivated

@export var enodes: Array[EnchantmentNode] = []
@export var elines: Array[EnchantmentLine] = []

var is_activated: bool = false
var overlaps: Array[Area2D]

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
	
	# Setup mask and layers
	collision_layer = 1 << 2
	collision_mask = (1 << 2) | (1 << 0)
	
	# Setup self signals so do not have to do it via scene
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
func _initialize_enchantment() -> void:
	deactivate_enchantment() # Resetting ensures safe state
	update_enchantment()

func update_enchantment() -> void:
	"""
	Attempt to activate the enchantment
	"""
	#print("Updating EnchantmentGrid")
	if Engine.is_editor_hint(): # I do not want to make material tool scripts for now, enchantment updating checks materials, so I will disable this
		return

	var activated_nodes = 0
	for node in enodes:
		node.update()
		if node.is_activated: # True means update caused enode to activate
			activated_nodes += 1

	if activated_nodes >= enodes.size() and !is_activated:
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
	#print("Activating EnchantmentGrid")
	is_activated = true
	emit_signal("activated")
	_start_glow_animation()

func deactivate_enchantment() -> void:
	#print("Deactivating EnchantmentGrid")
	is_activated = false
	emit_signal("deactivated")
	_stop_glow_animation()

"""
Animations
"""
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

"""
Area control
"""
func disable_detection():
	#_disable_area(self)

	for n in enodes:
		#print("disabling", n)
		n.disable_detection()

	for l in elines:
		#print("disabling", l)
		_disable_area(l)

func enable_detection():
	#_enable_area(self)

	for n in enodes:
		#print("Enabling" , n)
		n.enable_detection()

	for l in elines:
		#print("Enabling", l)
		_enable_area(l)

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
	if self.is_ancestor_of(a):
		return
	overlaps.append(a)
	#print(a)

func _on_area_exited(a: Area2D) -> void:
	if self.is_ancestor_of(a):
		return
	overlaps.erase(a)
	#print(a)
