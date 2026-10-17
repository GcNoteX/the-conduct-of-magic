class_name DisenchantStep
extends Resource

## One planned step of a disenchant (see DisenchantBoard): cut a committed line, dissolve a
## material for runes, or pull out an enchantment whose lines are all cut.
## A plan is an ordered list of these, kept on the item's GraphState until it's committed.

enum Kind { CUT, DISSOLVE, PULL_OUT }

@export var kind: Kind = Kind.CUT
## CUT: the node keys at the two ends of the line (see InscriptionBoard)
@export var a: String = ""
@export var b: String = ""
## DISSOLVE: the material, held in the item's plan until the commit uses it up
@export var material: EnchantmentMaterialDefinition
## PULL_OUT: the PlacementState id of the enchantment
@export var placement_id: int = 0


static func cut(from_key: String, to_key: String) -> DisenchantStep:
	var s := DisenchantStep.new()
	s.kind = Kind.CUT
	s.a = from_key
	s.b = to_key
	return s


static func dissolve(m: EnchantmentMaterialDefinition) -> DisenchantStep:
	var s := DisenchantStep.new()
	s.kind = Kind.DISSOLVE
	s.material = m
	return s


static func pull_out(id: int) -> DisenchantStep:
	var s := DisenchantStep.new()
	s.kind = Kind.PULL_OUT
	s.placement_id = id
	return s
