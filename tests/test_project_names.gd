extends Node

## Headless checks that the named constants in Groups and CollisionLayers match Project
## Settings: every group is declared under Global Groups and every layer has the expected name.
## Run: godot --headless --path . res://tests/test_project_names.tscn
## Exits with code 1 if any check fails.

const LAYER_NAMES := {
	CollisionLayers.ENCHANTMENT_MAP_COMP: "EnchantmentMapComp",
	CollisionLayers.CURSOR: "Cursor",
	CollisionLayers.ENCHANTMENT_GRID: "EnchantmentGrid",
	CollisionLayers.PHYSICAL_UI_ELEMENTS: "PhysicalUIElements",
	CollisionLayers.WORKSPACE_ZONE: "WorkspaceZone",
	CollisionLayers.WORKSPACE_OBJECT: "WorkSpaceObject",
}

var _failures := 0
var _checks := 0


func _ready() -> void:
	test_groups_are_declared()
	test_layers_are_named()
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func test_groups_are_declared() -> void:
	var constants: Dictionary = Groups.new().get_script().get_script_constant_map()
	check(not constants.is_empty(), "Groups has constants")
	for key: String in constants:
		var group: StringName = constants[key]
		check(
			ProjectSettings.has_setting("global_group/%s" % group),
			"group %s (Groups.%s) is declared in Project Settings" % [group, key]
		)


func test_layers_are_named() -> void:
	for layer: int in LAYER_NAMES:
		var setting := "layer_names/2d_physics/layer_%d" % layer
		check(
			ProjectSettings.get_setting(setting, "") == LAYER_NAMES[layer],
			"layer %d is named %s" % [layer, LAYER_NAMES[layer]]
		)
	check(CollisionLayers.bit(CollisionLayers.ENCHANTMENT_MAP_COMP) == 1, "layer 1 is bit 0")
	check(CollisionLayers.bit(CollisionLayers.ENCHANTMENT_GRID) == 1 << 2, "layer 3 is bit 2")
