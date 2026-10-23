class_name CommissionSlip
extends Resource

## What a customer asks for: the enchantment, the item it goes on, and what they offer to pay.

@export var customer_name: String = ""
@export var kingdom: String = ""
@export var enchantment: Enchantment
@export var item: EnchantableItemDefinition
@export var payment: int = 0
