# priority_queue.gd
class_name MapPriorityQueue
extends RefCounted

# Use actual class references for priority.
# These should be class_names or preloaded script types that exist at runtime.
# Example: if you used `class_name MagicNode` in magic_node.gd, MagicNode is usable here.
var PRIORITY_ORDER = [
	MagicNode,
	MagicLine,
	EnchantmentNode,
	EnchantmentLine,
]

# _queues is an Array of Arrays. _queues[i] corresponds to PRIORITY_ORDER[i].
var _queues: Array = []

func _init():
	_queues.clear()
	for i in PRIORITY_ORDER.size():
		_queues.append([])  # make a queue for each priority
	# also add a fallback queue for unknown types (lowest priority)
	_queues.append([])

# Add an item to the appropriate type queue
func push(item: Object) -> void:
	# Find the first priority type that matches the item
	for i in PRIORITY_ORDER.size():
		var t = PRIORITY_ORDER[i]
		if typeof(item) == typeof(t):
			_queues[i].append(item)
			return
	# fallback: put into last queue
	_queues[_queues.size() - 1].append(item)
	#print("Added to fallback queue: ", item)

# Remove and return the next item based on priority and insertion order
func pop() -> Object:
	for q in _queues:
		if q.size() > 0:
			return q.pop_front()
	return null  # all empty

# Look at the current front item without removing it
func peek() -> Object:
	for q in _queues:
		if q.size() > 0:
			return q[0]
	return null

# Remove a specific item from whichever queue it sits in
func remove(item: Object) -> void:
	for q in _queues:
		q.erase(item)

# Check if the queue has no items
func is_empty() -> bool:
	for q in _queues:
		if q.size() > 0:
			return false
	return true

# Completely clear all queues
func clear() -> void:
	for q in _queues:
		q.clear()

# Return all items in order of priority and insertion (for debugging)
func get_all() -> Array:
	var all_items: Array = []
	for q in _queues:
		all_items += q
	return all_items

# Check if a specific item exists anywhere in the queue
func contains(item: Object) -> bool:
	for q in _queues:
		if q.has(item):
			return true
	return false
