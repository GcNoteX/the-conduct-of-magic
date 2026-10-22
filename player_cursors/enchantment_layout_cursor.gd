class_name EnchantmentLayoutCursor
extends EnchantmentCursor
## Cursor for the legacy play map that drags enchantments out of enchantment boxes onto the map,
## places them where they overlap nothing, and removes placed ones with a right-click.

var controlled_enchantment: EnchantmentGrid = null


func _ready() -> void:
	selection_manager.set_priority_order([EnchantmentBox, EnchantmentGrid])


func _physics_process(_delta: float) -> void:
	if controlled_enchantment:
		controlled_enchantment.global_position = global_position

	if Input.is_action_just_pressed("left_click"):
		# Attempt to grab an Enchantment
		## ONLY ALLOW GRAB IF NOT OVERLAPS
		var box := selection_manager.peek() as EnchantmentBox
		if box:
			var e := box.get_enchantment()
			if e:
				var e_grid: EnchantmentGrid = e.map.instantiate()
				EmapUpdateManager.add_to_enchantment_map(e_grid, global_position)
				controlled_enchantment = e_grid
				controlled_enchantment.disable_detection()
			else:
				controlled_enchantment = null

	if Input.is_action_just_released("left_click"):
		if controlled_enchantment:
			if controlled_enchantment.overlaps.size() == 0:
				controlled_enchantment.enable_detection()  # Essentiall placing it
			else:
				controlled_enchantment.kill_enchantment()
		controlled_enchantment = null

	if Input.is_action_just_pressed("right_click"):
		var grid := selection_manager.peek() as EnchantmentGrid
		if grid and grid.overlaps.size() == 0:
			grid.kill_enchantment()


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
