class_name ItemDefinition
extends Resource
## Data shared by every copy of an item: its id, display name and inventory sprite

@export var id: StringName
@export var display_name: String = ""
@export_category("Inventory")
@export var inventory_sprite_normal: Texture2D
