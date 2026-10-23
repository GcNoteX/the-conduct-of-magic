class_name SupplierPanel
extends PanelContainer

## Sells a supplier's materials for the player's money: one row per stone with how many the
## player holds, its price and a Buy button, under the player's purse. The counter shows it at
## catalogue prices and the inscribing table at a markup. It plays its own purchase sounds.

signal purchased(material: EnchantmentMaterialDefinition, price: int)
## Something to tell the player, like a purchase or why one failed
signal message(text: String)

const SFX_PURCHASE := &"purchase"
const SFX_ERROR := &"error"
const COIN_ART := preload("res://counter/art/coin.png")
const STONE_ART := preload("res://counter/art/stone.png")
const SOUNDS: Dictionary[StringName, AudioStream] = {
	SFX_PURCHASE: preload("res://counter/sounds/purchase.wav"),
	SFX_ERROR: preload("res://counter/sounds/error.wav"),
}

var player: Player
var catalogue: SupplierCatalogue
## Prices are the catalogue's times this, rounded up
var price_multiplier: float = 1.0

var _title: Label
var _money_label: Label
var _rows: GridContainer
var _sounds: SoundBank


func _init() -> void:
	_sounds = SoundBank.new()
	_sounds.sounds = SOUNDS
	add_child(_sounds)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)
	_title = Label.new()
	_title.text = "Supplier"
	_title.theme_type_variation = &"TagLabel"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var coin := TextureRect.new()
	coin.texture = COIN_ART
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.custom_minimum_size = Vector2(40, 40)
	header.add_child(coin)
	_money_label = Label.new()
	_money_label.theme_type_variation = &"MoneyLabel"
	header.add_child(_money_label)
	_rows = GridContainer.new()
	_rows.columns = 4
	_rows.add_theme_constant_override("h_separation", 14)
	_rows.add_theme_constant_override("v_separation", 10)
	box.add_child(_rows)


## Sets who buys, from what, at what markup, and the heading shown above the stones
func open(p: Player, c: SupplierCatalogue, multiplier: float, title: String) -> void:
	player = p
	catalogue = c
	price_multiplier = multiplier
	_title.text = title
	refresh()


func price_of(m: EnchantmentMaterialDefinition) -> int:
	return catalogue.price_of(m, price_multiplier)


## Buys one of a material; returns whether the player could afford it
func buy(m: EnchantmentMaterialDefinition) -> bool:
	var price := price_of(m)
	var mat_name := InscriptionBoard.material_name(m)
	if not player.spend(price):
		message.emit("You can't afford a %s (%dg)." % [mat_name, price])
		_sounds.play(SFX_ERROR)
		return false
	player.add_material(m)
	message.emit("Bought a %s for %dg." % [mat_name, price])
	_sounds.play(SFX_PURCHASE)
	refresh()
	purchased.emit(m, price)
	return true


## Redraws the purse, counts and prices, and greys out what the player can't afford
func refresh() -> void:
	if player == null or catalogue == null:
		return
	_money_label.text = "%dg" % player.money
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for m in catalogue.materials():
		var icon := TextureRect.new()
		icon.texture = STONE_ART
		icon.self_modulate = m.color
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_rows.add_child(icon)
		var mat_label := Label.new()
		mat_label.text = InscriptionBoard.material_name(m)
		mat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_rows.add_child(mat_label)
		var owned := Label.new()
		owned.text = "×%d" % player.get_material_count(m)
		owned.custom_minimum_size.x = 60
		_rows.add_child(owned)
		var price := price_of(m)
		var buy_button := Button.new()
		buy_button.text = "Buy %dg" % price
		buy_button.custom_minimum_size.x = 140
		buy_button.focus_mode = Control.FOCUS_NONE
		buy_button.disabled = price > player.money
		buy_button.pressed.connect(buy.bind(m))
		_rows.add_child(buy_button)
