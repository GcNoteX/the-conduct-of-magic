class_name MagicLine
extends MapLine
## A straight line the player draws between two MapNodes. Takes its bounded identity from the
## nodes at its ends.
##
## When a MagicLine overlaps with:
## - EnchantmentLine of EnchantmentGrid -> Nothing
## - EnchantmentNode of EnchantmentGrid -> Invalid except owner (This is on Coder to not happen)
## - MagicLine of EnchantmentGrid -> Destroy MagicLine
## - EnchantmentLine of Other EnchantmentGrid -> Invalid
## - EnchantmentNode of Other EnchantmentGrid -> Invalid
## - MagicLine of Other EnchantmentGrid -> Okay
## - MagicNode of Item Map -> Invalid


func _ready() -> void:
	_initialize_line()


func update_bounded_identity() -> void:
	# Collect possible identities using a dictionary as a pseudo-set
	var identities := {}

	if start:
		if start.can_share_identity:
			identities[start.bounded_identity] = true
	if end:
		if end.can_share_identity:
			identities[end.bounded_identity] = true

	# Evaluate results
	var keys := identities.keys()

	if keys.has(null):
		keys.erase(null)

	if keys.size() > 1:
		push_error(
			(
				"%s connected between %s and %s with mismatched identities %s"
				% [self, start, end, str(keys)]
			)
		)

	if keys.size() > 0:
		bounded_identity = keys[0]  # Use the first identity deterministically
	else:
		bounded_identity = null
