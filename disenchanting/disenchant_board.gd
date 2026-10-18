# gdlint: disable=max-public-methods
# A rules facade the view, the table and the checker query from many angles.
class_name DisenchantBoard
extends RefCounted

## The rules of disenchanting one item. Pure logic, no drawing, so it can be tested headless.
## It reads the item's committed carvings through an InscriptionBoard, and keeps its plan on the
## item's GraphState so leaving the item and coming back keeps it.
## - Removing an enchantment means cutting every line in its chain, then pulling it out.
##   Its chain is its own lines, its lines to magic nodes and the magic-to-magic lines
##   chained to it.
## - A line costs the edge runes of both its end nodes, added together. A material puts the same
##   runes on every line at its node; each magic node has its own fixed set (HexMapDefinition).
## - When a node's last line is cut, the node is freed and pays out its harvest runes, once.
## - Dissolving a material gives its dissolve runes. You start with no runes.
## - Any cut you can afford is allowed; there's no other order rule.
## - A plan is an ordered list of DisenchantSteps, replayed from no runes to show the runes after
##   each step. The first step that can't be done blocks the rest.
## - Planned dissolves hold their material in the item: planning one takes it out of the inventory
##   and undoing it gives it back. Committing uses it up.
## - A commit has to be whole: every enchantment it cuts into is fully cut and pulled out.
##   Pulled-out enchantments leave their cells free.


## What replaying one step does
class Outcome:
	extends RefCounted

	var step: DisenchantStep
	## What the step cost
	var spent := RuneSet.new()
	## What the step gave: a dissolve's runes, or the harvest of the nodes a cut freed
	var gained := RuneSet.new()
	## The runes held after the step (unchanged when the step can't be done)
	var runes := RuneSet.new()
	## Node keys this cut freed
	var freed: Array[String] = []
	## "" when the step can be done, otherwise why not
	var error := ""
	## True when an earlier step can't be done, so this one never gets its turn
	var after_blocked := false


var board: InscriptionBoard
var state: GraphState

var _edges: Dictionary = {}  ## edge key -> {a, b, cells, placement}
var _node_edges: Dictionary = {}  ## node key -> Array[String] of edge keys
var _chains: Dictionary = {}  ## placement id -> Array[String] of edge keys


func _init(inscription_board: InscriptionBoard) -> void:
	board = inscription_board
	state = board.state
	_rebuild()


#
# ── Lines and their runes ────────────────────────
#
## The key of the line between two nodes, the same whichever end comes first. `which` tells apart
## lines joining the same two nodes (an enchantment's shape can have more than one), from 0.
static func edge_key(a: String, b: String, which := 0) -> String:
	var key := "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]
	return key if which == 0 else "%s#%d" % [key, which]


## The key of the line a CUT step cuts
static func step_edge_key(s: DisenchantStep) -> String:
	return edge_key(s.a, s.b, s.line)


## Every committed line, by edge key
func edges() -> Array[String]:
	var out: Array[String] = []
	out.assign(_edges.keys())
	return out


func has_edge(key: String) -> bool:
	return _edges.has(key)


func edge_ends(key: String) -> Array[String]:
	return [_edges[key].a, _edges[key].b]


## The line's cells from one end node to the other, both included
func edge_cells(key: String) -> Array[Vector2i]:
	return _edges[key].cells


func edge_placement(key: String) -> PlacementState:
	return _edges[key].placement


## The committed lines at a node
func node_edges(node_key: String) -> Array[String]:
	var out: Array[String] = []
	out.assign(_node_edges.get(node_key, []))
	return out


## The runes a node puts on every line at it
func node_edge_runes(node_key: String) -> RuneSet:
	if board.is_magic(node_key):
		return board.map.edge_runes_at(board.node_cell(node_key))
	var m := board.node_material(node_key)
	return RuneSet.copy_of(m.edge_runes if m else null)


## The runes a node gives back when its last line is cut
func node_harvest_runes(node_key: String) -> RuneSet:
	if board.is_magic(node_key):
		return board.map.harvest_runes_at(board.node_cell(node_key))
	var m := board.node_material(node_key)
	return RuneSet.copy_of(m.harvest_runes if m else null)


## What cutting a line costs: both its end nodes' edge runes, added together
func edge_cost(key: String) -> RuneSet:
	return node_edge_runes(_edges[key].a).plus(node_edge_runes(_edges[key].b))


## The committed enchantments on the item
func carvings() -> Array[PlacementState]:
	return board.committed_placements()


## Every line that has to be cut before the enchantment can be pulled out
func chain(p: PlacementState) -> Array[String]:
	var out: Array[String] = []
	out.assign(_chains.get(p.id, []))
	return out


func find_carving(placement_id: int) -> PlacementState:
	for p in carvings():
		if p.id == placement_id:
			return p
	return null


## A short player-facing name for a node, like "Kindle's Fire stone" or "magic node 3"
func node_label(node_key: String) -> String:
	if board.is_magic(node_key):
		return "magic node %d" % board.map.magic_node_number(board.node_cell(node_key))
	var p := board.node_placement(node_key)
	return (
		"%s's %s"
		% [
			p.enchantment.enchantment_name,
			InscriptionBoard.material_name(board.node_material(node_key))
		]
	)


## A full name for a node, like "Kindle node 1 (Fire stone)" or "magic node 3". Enchantment nodes
## count from 1 in the enchantment's own order; magic nodes use the numbers drawn on the board.
func node_name(node_key: String) -> String:
	if board.is_magic(node_key):
		return node_label(node_key)
	var p := board.node_placement(node_key)
	return (
		"%s node %d (%s)"
		% [
			p.enchantment.enchantment_name,
			node_key.get_slice(":", 2).to_int() + 1,
			InscriptionBoard.material_name(board.node_material(node_key))
		]
	)


## A full name for a line, like "Kindle node 1 (Fire stone) to magic node 3"
func edge_name(key: String) -> String:
	var ends := edge_ends(key)
	return "%s to %s" % [node_name(ends[0]), node_name(ends[1])]


## A short player-facing description of a step, like "Cut Kindle's Fire stone to magic node"
func describe_step(s: DisenchantStep) -> String:
	match s.kind:
		DisenchantStep.Kind.CUT:
			return "Cut %s to %s" % [node_label(s.a), node_label(s.b)]
		DisenchantStep.Kind.DISSOLVE:
			return "Dissolve %s" % InscriptionBoard.material_name(s.material)
		_:
			var p := find_carving(s.placement_id)
			return "Pull out %s" % (p.enchantment.enchantment_name if p else "an enchantment")


#
# ── Replaying a plan ─────────────────────────────
#
## The outcome of each step of the item's plan
func outcomes() -> Array[Outcome]:
	return replay(state.disenchant_plan)


## Replays `steps` from no runes. Steps after the first one that can't be done are marked
## after_blocked and don't change anything.
func replay(steps: Array[DisenchantStep]) -> Array[Outcome]:
	var out: Array[Outcome] = []
	var runes := RuneSet.new()
	var cut := {}
	var left := {}
	for k in _node_edges:
		left[k] = _node_edges[k].size()
	var pulled := {}
	var blocked := false
	for s in steps:
		var o := Outcome.new()
		o.step = s
		if blocked:
			o.after_blocked = true
			o.error = "Waiting on an earlier step"
		else:
			match s.kind:
				DisenchantStep.Kind.CUT:
					_replay_cut(o, runes, cut, left)
				DisenchantStep.Kind.DISSOLVE:
					if s.material == null:
						o.error = "There's no material to dissolve"
					else:
						o.gained = RuneSet.copy_of(s.material.dissolve_runes)
				DisenchantStep.Kind.PULL_OUT:
					o.error = _replay_pull_out(s.placement_id, cut, pulled)
			if o.error == "":
				runes = runes.minus(o.spent).plus(o.gained)
			blocked = o.error != ""
		o.runes = runes
		out.append(o)
	return out


## The runes held at the end of the plan, up to its first blocked step
func runes() -> RuneSet:
	var all := outcomes()
	return RuneSet.new() if all.is_empty() else all.back().runes


## The index of the first planned step that can't be done, or -1
func first_blocked() -> int:
	var all := outcomes()
	for i in all.size():
		if all[i].error != "":
			return i
	return -1


#
# ── Planning ─────────────────────────────────────
#
func is_cut_planned(key: String) -> bool:
	return planned_step_of_edge(key) >= 0


## The index in the plan of the step that cuts this line, or -1
func planned_step_of_edge(key: String) -> int:
	var plan := state.disenchant_plan
	for i in plan.size():
		if plan[i].kind == DisenchantStep.Kind.CUT and step_edge_key(plan[i]) == key:
			return i
	return -1


func is_pull_out_planned(p: PlacementState) -> bool:
	for s in state.disenchant_plan:
		if s.kind == DisenchantStep.Kind.PULL_OUT and s.placement_id == p.id:
			return true
	return false


## Whether a cut of this line can be added to the plan. A cut you can't afford yet can still be
## planned; it shows as blocked until the runes are there.
func check_cut(key: String) -> String:
	if not _edges.has(key):
		return "Only committed lines can be cut"
	if is_cut_planned(key):
		return "That line is already planned to be cut"
	return ""


func plan_cut(key: String) -> String:
	var err := check_cut(key)
	if err == "":
		state.disenchant_plan.append(cut_step(key))
	return err


## A new step that cuts the line `key`
func cut_step(key: String) -> DisenchantStep:
	return DisenchantStep.cut(_edges[key].a, _edges[key].b, _edges[key].which)


func check_dissolve(m: EnchantmentMaterialDefinition) -> String:
	if m == null:
		return "Pick a material to dissolve"
	if board.inventory.get_material_count(m) <= 0:
		return "You don't have another %s" % InscriptionBoard.material_name(m)
	if RuneSet.copy_of(m.dissolve_runes).is_empty():
		return "%s gives no runes" % InscriptionBoard.material_name(m)
	return ""


## Moves `m` from the inventory into the item's plan
func plan_dissolve(m: EnchantmentMaterialDefinition) -> String:
	var err := check_dissolve(m)
	if err == "":
		board.inventory.remove_material(m)
		state.disenchant_plan.append(DisenchantStep.dissolve(m))
	return err


func check_pull_out(p: PlacementState) -> String:
	if p == null or not p.committed or find_carving(p.id) == null:
		return "Only committed enchantments can be pulled out"
	if is_pull_out_planned(p):
		return "%s is already planned to come out" % p.enchantment.enchantment_name
	var uncut := 0
	for k in chain(p):
		if not is_cut_planned(k):
			uncut += 1
	if uncut > 0:
		return "Cut every line of %s first (%d left)" % [p.enchantment.enchantment_name, uncut]
	return ""


func plan_pull_out(p: PlacementState) -> String:
	var err := check_pull_out(p)
	if err == "":
		state.disenchant_plan.append(DisenchantStep.pull_out(p.id))
	return err


## Takes the last step off the plan. An undone dissolve gives its material back.
func undo_last() -> DisenchantStep:
	if state.disenchant_plan.is_empty():
		return null
	var s: DisenchantStep = state.disenchant_plan.pop_back()
	if s.kind == DisenchantStep.Kind.DISSOLVE and s.material:
		board.inventory.add_material(s.material)
	return s


func clear_plan() -> void:
	while not state.disenchant_plan.is_empty():
		undo_last()


#
# ── Commit ───────────────────────────────────────
#
## The enchantments the plan pulls out
func planned_pull_outs() -> Array[PlacementState]:
	var out: Array[PlacementState] = []
	for s in state.disenchant_plan:
		if s.kind == DisenchantStep.Kind.PULL_OUT:
			var p := find_carving(s.placement_id)
			if p:
				out.append(p)
	return out


func check_commit() -> String:
	if state.disenchant_plan.is_empty():
		return "Plan a disenchant first"
	var all := outcomes()
	for i in all.size():
		if all[i].error != "":
			return "Step %d can't be done: %s" % [i + 1, all[i].error]
	var pulled := planned_pull_outs()
	if pulled.is_empty():
		return "Pull out an enchantment before committing"
	var unfinished: Array[String] = []
	for s in state.disenchant_plan:
		if s.kind != DisenchantStep.Kind.CUT:
			continue
		var p := edge_placement(step_edge_key(s))
		if p == null:
			continue
		var n := p.enchantment.enchantment_name
		if p not in pulled and n not in unfinished:
			unfinished.append(n)
	if not unfinished.is_empty():
		return (
			"Every enchantment you cut into has to be pulled out too. Not yet: "
			+ ", ".join(unfinished)
		)
	return ""


## Pulls out every planned enchantment, freeing its cells. The dissolved materials and the
## pulled-out enchantments' materials are used up, and leftover runes disperse.
func commit() -> Array[PlacementState]:
	var done: Array[PlacementState] = []
	if check_commit() != "":
		return done
	done = planned_pull_outs()
	for p in done:
		board.remove_carving(p)
	state.disenchant_plan.clear()
	_rebuild()
	return done


#
# ── Internals ────────────────────────────────────
#
func _replay_cut(o: Outcome, runes: RuneSet, cut: Dictionary, left: Dictionary) -> void:
	var key := step_edge_key(o.step)
	if not _edges.has(key):
		o.error = "That line isn't part of a committed carving"
		return
	if cut.has(key):
		o.error = "That line is already cut"
		return
	var cost := edge_cost(key)
	if not runes.covers(cost):
		o.error = "Needs %s more" % runes.shortfall(cost).describe()
		return
	o.spent = cost
	cut[key] = true
	for n: String in [_edges[key].a, _edges[key].b]:
		left[n] -= 1
		if left[n] == 0:
			o.freed.append(n)
			o.gained = o.gained.plus(node_harvest_runes(n))


func _replay_pull_out(placement_id: int, cut: Dictionary, pulled: Dictionary) -> String:
	var p := find_carving(placement_id)
	if p == null:
		return "That enchantment isn't carved on this item"
	if pulled.has(placement_id):
		return "%s is already pulled out" % p.enchantment.enchantment_name
	for k in chain(p):
		if not cut.has(k):
			return "Some of its lines aren't cut yet"
	pulled[placement_id] = true
	return ""


func _rebuild() -> void:
	_edges.clear()
	_node_edges.clear()
	_chains.clear()
	for f in board.fixed_lines():
		if f.placement.committed:
			_add_edge(f.a, f.b, f.cells)
	for l in state.lines:
		if l.committed:
			_add_edge(l.a, l.b, l.cells)
	# Each committed enchantment's chain is every line reachable from its nodes
	for p in carvings():
		var keys: Array[String] = []
		var seen := {}
		var stack: Array[String] = []
		for i in p.enchantment.nodes.size():
			stack.append(InscriptionBoard.enchantment_key(p.id, i))
		while not stack.is_empty():
			var n: String = stack.pop_back()
			if seen.has(n):
				continue
			seen[n] = true
			for k: String in _node_edges.get(n, []):
				if k not in keys:
					keys.append(k)
					_edges[k].placement = p
				for end in [_edges[k].a, _edges[k].b]:
					if not seen.has(end):
						stack.append(end)
		_chains[p.id] = keys


func _add_edge(a: String, b: String, cells: Array[Vector2i]) -> void:
	var which := 0
	while _edges.has(edge_key(a, b, which)):
		which += 1
	var key := edge_key(a, b, which)
	_edges[key] = {"a": a, "b": b, "which": which, "cells": cells, "placement": null}
	for n in [a, b]:
		if not _node_edges.has(n):
			_node_edges[n] = []
		_node_edges[n].append(key)
