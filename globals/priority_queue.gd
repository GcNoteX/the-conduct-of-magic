class_name PriorityQueue
extends RefCounted

"""
Tracks hovered objects for a cursor and hands back the most important one.
- set_priority_order() takes classes, highest priority first (e.g. [MagicNode, MagicLine])
- push()/remove() as objects enter and leave the cursor
- peek() returns the most recently pushed object of the highest-priority class present
"""

var _order: Array = []
var _queues: Array[Array] = []

func set_priority_order(order: Array) -> void:
	_order = order
	_queues.clear()
	for i in order.size():
		_queues.append([])

func push(obj: Object) -> void:
	var i := _priority_of(obj)
	if i < 0:
		push_warning("PriorityQueue: %s matches no class in the priority order" % str(obj))
		return
	if obj in _queues[i]:
		return
	_queues[i].append(obj)

func remove(obj: Object) -> void:
	for q in _queues:
		q.erase(obj)

func peek() -> Object:
	for q in _queues:
		# Drop freed objects lazily
		while not q.is_empty() and not is_instance_valid(q.back()):
			q.pop_back()
		if not q.is_empty():
			return q.back()
	return null

func clear() -> void:
	for q in _queues:
		q.clear()

func _priority_of(obj: Object) -> int:
	for i in _order.size():
		if is_instance_of(obj, _order[i]):
			return i
	return -1
