# priority_queue.gd
class_name MapPriorityQueue
extends RefCounted

# Define type order — earlier means higher priority
var PRIORITY_ORDER = [
	MagicNode,
	MagicLine,
	EnchantmentNode,
	EnchantmentLine,
]

var _queues: Dictionary = {}  # maps class_name -> Array

func _init():
	for t in PRIORITY_ORDER:
		_queues[t] = []

# Add an item to the appropriate type queue
func push(item: Object) -> void:
	var t = item.get_class()
	if not _queues.has(t):
		_queues[t] = []
	_queues[t].append(item)

# Remove and return the next item based on priority and insertion order
func pop() -> Object:
	for t in PRIORITY_ORDER:
		var q: Array = _queues[t]
		if q.size() > 0:
			return q.pop_front()
	return null  # all empty

# Look at the current front item without removing it
func peek() -> Object:
	for t in PRIORITY_ORDER:
		var q: Array = _queues[t]
		if q.size() > 0:
			return q[0]
	return null

# Remove a specific item from its queue (e.g., when it exits cursor range)
func remove(item: Object) -> void:
	var t = item.get_class()
	if _queues.has(t):
		_queues[t].erase(item)

# Check if the queue has no items
func is_empty() -> bool:
	for q in _queues.values():
		if q.size() > 0:
			return false
	return true

# Completely clear all queues
func clear() -> void:
	for t in _queues.keys():
		_queues[t].clear()

# Return all items in order of priority and insertion (for debugging)
func get_all() -> Array:
	var all_items: Array = []
	for t in PRIORITY_ORDER:
		all_items += _queues[t]
	return all_items

# Check if a specific item exists anywhere in the queue
func contains(item: Object) -> bool:
	var t = item.get_class()
	if _queues.has(t):
		return _queues[t].has(item)
	return false
