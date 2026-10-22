extends Node

## 📦 PlayerManager
## Responsible for managing the currently active player instance.
## This includes creating a new player, accessing their inventory,
## and safely adding/removing materials without directly touching
## the underlying Player object.

# Internal player instance (do not access directly outside this class)
var _player: Player = null


func _ready() -> void:
	if Mocker.is_mocking:
		_player = Mocker.player


# ────────────────────────────────────────────────
# 🧍 PLAYER MANAGEMENT
# ────────────────────────────────────────────────


## Creates a new player instance.
## This is typically called when starting a new game or loading a save file.
func new_player() -> void:
	_player = Player.new()
	print("✅ New player created.")


## Uses an existing player instance (e.g. one built from a DemoSetup).
func set_player(p: Player) -> void:
	_player = p


## Returns the current player instance.
## Use this for read-only operations or when player reference is needed.
func get_player() -> Player:
	return _player


## Returns true if a player instance is active.
func has_player() -> bool:
	return _player != null


# ────────────────────────────────────────────────
# 💎 MATERIAL INVENTORY OPERATIONS
# ────────────────────────────────────────────────


## Adds a given amount of material to the player's inventory.
## Delegates to Player, which ignores a null material.
func add_material(material: EnchantmentMaterialDefinition, amount: int = 1) -> void:
	if not _player:
		push_warning("⚠️ No active player — cannot add material.")
		return
	_player.add_material(material, amount)


## Removes a given amount of material from the player's inventory.
## Delegates to Player, which drops the entry once its count reaches 0.
func remove_material(material: EnchantmentMaterialDefinition, amount: int = 1) -> void:
	if not _player:
		push_warning("⚠️ No active player — cannot remove material.")
		return
	_player.remove_material(material, amount)


## Returns a copy of the player's material inventory.
## This prevents external scripts from directly modifying it.
func get_inventory() -> Dictionary:
	if not _player:
		push_warning("⚠️ No active player — returning empty inventory.")
		return {}
	return _player.material_inventory.duplicate(true)


# ────────────────────────────────────────────────
# 🧹 UTILITY / DEBUG
# ────────────────────────────────────────────────


## Clears the current player (for testing or resetting state).
func clear_player() -> void:
	_player = null
	print("Player cleared from manager.")
