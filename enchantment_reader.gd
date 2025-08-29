class_name EnchantmentReader
extends Node

@export var map: EnchantmentMap

var enchantments: Array[Enchantment] = []

func _ready() -> void:
	map.updated.connect(evaluate_enchantment)
	await map.map_initialized
	evaluate_enchantment()

func evaluate_enchantment() -> void:
	enchantments.clear()
	
	for socket in map.sockets:
		if len(socket.connected_edges) == 1:
			var e = evaluate_tier1(socket)
			enchantments.append(e)
	
	print("=======")
	for enchantment in enchantments:
		print(enchantment)
	print("=======")

func evaluate_tier1(s: Socket) -> Enchantment:
	print("Evaluating tier 1")
	var edge = s.connected_edges[0]
	var other: Socket
	var dir = Vector2.ZERO
	
	if edge.starting_socket == s: # I want to always start from the socket
		other = edge.ending_socket
	else:
		other = edge.starting_socket
	
	dir = ((other.position - s.position) * Vector2(1, -1)).normalized()
	#enchantments.append(_categorize_vector(dir))
	
	var angle := dir.angle() # radians, from +X axis, CCW
	var deg := rad_to_deg(angle)
	
	# Normalize to 0–360
	if deg < 0:
		deg += 360.0
	
	 #8 sectors, 45° each
	if deg >= 337.5 or deg < 22.5:
		return Loudness.new()
	elif deg < 67.5:
		return Lightness.new()
	elif deg < 112.5:
		return Sharpness.new()
	elif deg < 157.5:
		return Brittleness.new()
	elif deg < 202.5:
		return Softness.new()
	elif deg < 247.5:
		return Heaviness.new()
	elif deg < 292.5:
		return Dullness.new()
	elif deg < 337.5:
		return Toughness.new()
	return UnknownEnchantment.new()
	#print(vec , " -> ", dir, " degree:", deg, "radians:", rad_to_deg(angle))
	
func evaluate_tier2(s: Socket) -> void:
	print("Evaluating tier 2")

func evaluate_tier3(s: Socket) -> void:
	print("Evaluating tier 3")

func evaluate_tier4(s: Socket) -> void:
	print("Evaluating tier 4")

func evaluate_tier5(s: Socket) -> void:
	print("Evaluating tier 5")

func evaluate_tier6(s: Socket) -> void:
	print("Evaluating tier 6")

func evaluate_tier7(s: Socket) -> void:
	print("Evaluating tier 7")
