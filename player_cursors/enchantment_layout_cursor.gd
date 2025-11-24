extends EnchantmentCursor
class_name EnchantmentLayoutCursor

var controlled_enchantment: EnchantmentGrid = null

func _ready() -> void:
	selection_manager.set_priority_order([
		EnchantmentBox,
		EnchantmentGrid
	])

func _physics_process(delta: float) -> void:
	if controlled_enchantment:
		controlled_enchantment.global_position = global_position

	if Input.is_action_just_pressed("left_click"):
		# Attempt to grab an Enchantment
		var obj = selection_manager.peek()
		if obj and obj.has_method("get_enchantment"):
			var e = obj.get_enchantment() as Enchantment
			if e is Enchantment:
				var e_grid = e.map.instantiate()
				EmapUpdateManager.add_to_enchantment_map(e_grid, global_position)
				controlled_enchantment = e_grid
			elif e == null:
				controlled_enchantment = null
			else:
				push_warning("get_enchantment() should return a MapItem or null!")
	
	if Input.is_action_just_released("left_click"):
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
