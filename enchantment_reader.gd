class_name EnchantmentReader
extends Node

@export var map: EnchantmentMap

var enchantments: Array[String] = []

func _ready() -> void:
	map.updated.connect(evaluate_enchantment)
	await map.map_initialized
	evaluate_enchantment()

func evaluate_enchantment() -> void:
	enchantments.clear()
	
	for socket in map.sockets:
		if len(socket.connected_edges) == 1:
			var edge = socket.connected_edges[0]
			var other: Socket
			var dir = Vector2.ZERO
			
			if edge.starting_socket == socket: # I want to always start from the socket
				other = edge.ending_socket
			else:
				other = edge.starting_socket
			
			print(other.position, socket.position)
			dir = ((other.position - socket.position) * Vector2(1, -1)).normalized()
			
			#var dir = (other.position - socket.position).normalized()
			
			
			
			enchantments.append(categorize_vector(dir))
			
			#if edge.starting_socket == socket: # Outgoing edge
				#enchantments.append(categorize_vector(edge.get_vector_from_line()))
			#else:
				#enchantments.append(categorize_vector(-1 * edge.get_vector_from_line()))
	for enchantment in enchantments:
		print(enchantment)
	print("=======")


func categorize_vector(vec: Vector2) -> String:
	if vec == Vector2.ZERO:
		return "Center"
	
	var angle := vec.angle() # radians, from +X axis, CCW
	var deg := rad_to_deg(angle)
	
	# Normalize to 0–360
	if deg < 0:
		deg += 360.0
	
	var dir: String = angle_to_direction(deg)
	print(vec , " -> ", dir, " degree:", deg, "radians:", rad_to_deg(angle))
	return dir
	
func angle_to_direction(deg: float) -> String:
	# 8 sectors, 45° each
	if deg >= 337.5 or deg < 22.5:
		return "E"
	elif deg < 67.5:
		return "NE"
	elif deg < 112.5:
		return "N"
	elif deg < 157.5:
		return "NW"
	elif deg < 202.5:
		return "W"
	elif deg < 247.5:
		return "SW"
	elif deg < 292.5:
		return "S"
	elif deg < 337.5:
		return "SE"
	return "Unkno````wn"
