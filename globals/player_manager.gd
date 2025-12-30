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

## Safely adds a given amount of material to the player's inventory.
## If no player exists, prints an error.
func add_material(material: EnchantmentMaterialDefinition, amount: int = 1) -> void:
	if not _player:
		push_warning("⚠️ No active player — cannot add material.")
		return

	if material not in _player.material_inventory:
		_player.material_inventory[material] = 0

	_player.material_inventory[material] += amount
	#print("Added %d × %s" % [amount, str(material.material_id)])
	#print(get_inventory())

## Removes a given amount of material from the player's inventory.
## If the amount exceeds what is owned, it will clamp to 0 and issue a warning.
func remove_material(material: EnchantmentMaterialDefinition, amount: int = 1) -> void:
	if not _player:
		push_warning("⚠️ No active player — cannot remove material.")
		return

	if material not in _player.material_inventory:
		push_warning("⚠️ Tried to remove material the player doesn't have: %s" % str(material))
		return

	var current_amount := _player.material_inventory[material]
	var new_amount := current_amount - amount

	if new_amount < 0:
		push_warning(
			"⚠️ Tried to remove more '%s' than available (%d > %d). Clamping to 0." % [
				str(material), amount, current_amount
			]
		)
		new_amount = 0

	_player.material_inventory[material] = new_amount
	print("Removed %d × %s (remaining: %d)" % [amount, str(material), new_amount])


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
