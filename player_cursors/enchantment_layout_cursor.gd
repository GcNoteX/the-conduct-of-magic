extends EnchantmentCursor
class_name EnchantmentLayoutCursor

var controlled_enchantment: EnchantmentGrid = null

func _ready() -> void:
	selection_manager.set_priority_order([
		EnchantmentBox,
		EnchantmentGrid
	])

func _physics_process(_delta: float) -> void:
	if controlled_enchantment:
		controlled_enchantment.global_position = global_position
		#print("\n=== ENCHANTMENT DEBUG ===")
		#print("Grid: ", controlled_enchantment, 
			#" | monitoring: ", controlled_enchantment.monitoring, 
			#" | monitorable: ", controlled_enchantment.monitorable)
#
		#print("--- Nodes ---")
		#for n in controlled_enchantment.enodes:
			#print("  Node: ", n, 
				#" | monitoring: ", n.monitoring,
				#" | monitorable: ", n.monitorable)
#
		#print("--- Lines ---")
		#for l in controlled_enchantment.elines:
			#print("  Line: ", l, 
				#" | monitoring: ", l.monitoring,
				#" | monitorable: ", l.monitorable)
#
		#print("=========================\n")


	if Input.is_action_just_pressed("left_click"):
		# Attempt to grab an Enchantment
		var obj = selection_manager.peek()
		if obj and obj.has_method("get_enchantment"):
			var e = obj.get_enchantment() as Enchantment
			if e is Enchantment:
				var e_grid = e.map.instantiate()
				EmapUpdateManager.add_to_enchantment_map(e_grid, global_position)
				controlled_enchantment = e_grid
				controlled_enchantment.disable_detection()
			elif e == null:
				controlled_enchantment = null
			else:
				push_warning("get_enchantment() should return a MapItem or null!")
	
	if Input.is_action_just_released("left_click"):
		if controlled_enchantment:
			controlled_enchantment.enable_detection()
		controlled_enchantment = null

func _on_area_entered(area: Area2D) -> void:
	if area is EnchantmentBoxArea:
		selection_manager.push(area.get_enchantment_box())
	if area is EnchantmentGrid:
		selection_manager.push(area)

func _on_area_exited(area: Area2D) -> void:
	if area is EnchantmentBoxArea:
		selection_manager.remove(area.get_enchantment_box())
	if area is EnchantmentGrid:
		selection_manager.remove(area)
