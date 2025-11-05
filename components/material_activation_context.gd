# material_activation_context.gd
class_name MaterialActivationContext
extends RefCounted

var start_node: MapNode # the starting node
var enchantment: Enchantment # local subgraph
var map: EnchantmentMap # global graph

func _init(s: MapNode = null, e: Enchantment = null, m: EnchantmentMap = null) -> void:
	self.start_node = s
	self.enchantment = e
	self.map = m
