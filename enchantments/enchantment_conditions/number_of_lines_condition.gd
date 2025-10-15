class_name NumberOfLinesConditon
extends EnchantmentCondition

## The number of MagicEdges that has to be connected to the holder of this condition
@export var number_of_lines: int = 0 

func is_fulfilled() -> bool:
	#TODO: Would need references to a map and stuff to actually make work.
	return true
