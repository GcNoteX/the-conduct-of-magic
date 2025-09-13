class_name EnchantmentReader
extends Node

@export var map: EnchantmentMap
@export var is_debug_vertexes: bool = true
 
var enchantments: Array[Enchantment] = []
var max_tier_read: int = 2

func _ready() -> void:
	map.updated.connect(evaluate_enchantment)
	await map.map_initialized
	evaluate_enchantment()

func evaluate_enchantment() -> void:
	enchantments.clear()
	
	for socket in map.sockets:
		var n = len(_get_stable_edges(socket))
		
		if n == 0:
			socket.clear_debugger()
		if n >= 1 and n <= max_tier_read:
			var fn_name = "evaluate_tier%d" % n
			if has_method(fn_name):
				var e = call(fn_name, socket)
				enchantments.append(e)
				if n == 1:
					var d: Tier1Debugger = Tier1Debugger.new()
					# Custom debugging code for tier 1
					socket.plug_debugger(d)
				elif n == 2:
					var d: Tier2Debugger = Tier2Debugger.new()
					# Custom debugging code for tier 2
					d.mid_vector = _get_middle_vector(socket)
					socket.plug_debugger(d)
				elif n == 3:
					var d = load("res://utilities/tier3_debugger.gd")
					# Custom debugging code for tier 3
					socket.plug_debugger(d)
				elif n == 4:
					var d = load("res://utilities/tier4_debugger.gd")
					# Custom debugging code for tier 4
					socket.plug_debugger(d)
				elif n == 5:
					var d = load("res://utilities/tier5_debugger.gd")
					# Custom debugging code for tier 5
					socket.plug_debugger(d)
				elif n == 6:
					var d = load("res://utilities/tier6_debugger.gd")
					# Custom debugging code for tier 6
					socket.plug_debugger(d)
				elif n == 7:
					var d = load("res://utilities/tier7_debugger.gd")
					# Custom debugging coe for tier 7
					socket.plug_debugger(d)

	
	print("=======")
	for enchantment in enchantments:
		print(enchantment)
	print("=======")

func evaluate_tier1(s: Socket) -> Enchantment:
	var edge = _get_stable_edges(s)[0]
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
		return Roughness.new()
	elif deg < 67.5:
		return Lightness.new()
	elif deg < 112.5:
		return Sharpness.new()
	elif deg < 157.5:
		return Brittleness.new()
	elif deg < 202.5:
		return Smoothness.new()
	elif deg < 247.5:
		return Heaviness.new()
	elif deg < 292.5:
		return Bluntness.new()
	elif deg < 337.5:
		return Toughness.new()
	return UnknownEnchantment.new()

func evaluate_tier2(s: Socket) -> Enchantment:
	var stable_edges = _get_stable_edges(s)
	
	# Must have exactly 2 edges
	if stable_edges.size() != 2:
		push_warning("Socket does not have exactly 2 stable edges")
		return null

	# Step 1: Get outgoing direction vectors
	var dirs := []
	for edge in stable_edges:
		var other: Socket
		if edge.starting_socket == s:
			other = edge.ending_socket
		else:
			other = edge.starting_socket

		# Direction from s to other socket, Y-flipped
		var dir = ((other.position - s.position) * Vector2(1, -1)).normalized()
		dirs.append(dir)

	# Step 2: Compute smaller angle between vectors
	var angle_deg = rad_to_deg(dirs[0].angle_to(dirs[1]))
	if angle_deg > 180:
		angle_deg = 360 - angle_deg  # smallest angle

	# Determine angle type
	var angle_type: String
	if angle_deg < 80:
		angle_type = "Acute"
	elif angle_deg <= 100:
		angle_type = "Right"
	elif angle_deg >= 170:
		angle_type = "Colinear"
	else:
		angle_type = "Obtuse"

	# Step 3: Determine orientation
	var orientation: String
	if angle_type != "Colinear":
		# Mid direction between vectors
		var mid_dir = ((dirs[0] + dirs[1]) * 0.5).normalized()
		if mid_dir.x >= 0 and mid_dir.y <= 0:
			orientation = "NE"
		elif mid_dir.x <= 0 and mid_dir.y <= 0:
			orientation = "NW"
		elif mid_dir.x >= 0 and mid_dir.y >= 0:
			orientation = "SE"
		else:
			orientation = "SW"
	else:
		# Colinear orientation
		var avg_dir = ((dirs[0] + dirs[1]) * 0.5).normalized()
		if abs(avg_dir.x) < 0.5:  # mostly vertical
			orientation = "Vertical"
		elif abs(avg_dir.y) < 0.5:  # mostly horizontal
			orientation = "Horizontal"
		elif avg_dir.x * avg_dir.y > 0:
			orientation = "Diagonal1"
		else:
			orientation = "Diagonal2"

	# Step 4: Map to enchantments
	match angle_type:
		"Acute":
			match orientation:
				"NE": return Loudness.new()
				"NW": return Silentness.new()
				"SE": return EnhanceTaste.new()
				"SW": return SuppressTaste.new()
		"Obtuse":
			match orientation:
				"NE": return Reflectiveness.new()
				"NW": return Dullness.new()
				"SE": return EnhanceSmell.new()
				"SW": return SuppressSmell.new()
		"Right":
			match orientation:
				"NE": return FireResistance.new()
				"NW": return WaterResistance.new()
				"SE": return WindResistance.new()
				"SW": return EarthResistance.new()
		"Colinear":
			match orientation:
				"Vertical": return FireConductivity.new()
				"Horizontal": return WaterConductivity.new()
				"Diagonal1": return WindConductivity.new()
				"Diagonal2": return EarthConductivity.new()
	return UnknownEnchantment.new()

func evaluate_tier3(_s: Socket) -> Enchantment:
	print("Evaluating tier 3")
	return UnknownEnchantment.new()

func evaluate_tier4(_s: Socket) -> Enchantment:
	print("Evaluating tier 4")
	return UnknownEnchantment.new()

func evaluate_tier5(_s: Socket) -> Enchantment:
	print("Evaluating tier 5")
	return UnknownEnchantment.new()

func evaluate_tier6(_s: Socket) -> Enchantment:
	print("Evaluating tier 6")
	return UnknownEnchantment.new()

func evaluate_tier7(_s: Socket) -> Enchantment:
	print("Evaluating tier 7")
	return UnknownEnchantment.new()

## Returns the middle vector (normalized) between two outgoing edges of a socket
func _get_middle_vector(s: Socket) -> Vector2:
	# Step 1: Get outgoing direction vectors
	var dirs := []
	for edge in s.connected_edges:
		var other: Socket
		if edge.starting_socket == s:
			other = edge.ending_socket
		else:
			other = edge.starting_socket

		# Direction from s to other socket, Y-flipped
		var dir = ((other.position - s.position) * Vector2(1, -1)).normalized()
		dirs.append(dir)

	# Step 2: Compute smaller angle between vectors
	var angle_deg = rad_to_deg(dirs[0].angle_to(dirs[1]))
	if angle_deg > 180:
		angle_deg = 360 - angle_deg  # smallest angle
		
	return ((dirs[0] + dirs[1]) * 0.5).normalized()

func _get_stable_edges(s: Socket) -> Array[MagicEdge]:
	var c: Array[MagicEdge] = []
	for edge in s.connected_edges:
		if edge.starting_socket and edge.ending_socket:
			c.append(edge)
	return c
