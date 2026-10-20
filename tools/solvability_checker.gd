class_name SolvabilityChecker
extends RefCounted

## Dev tool: finds out whether a disenchant board can be cleared, and with which materials.
## Dissolving only ever adds runes, so every dissolve can go first. What's left is a search over
## cut orders. The runes held after a set of cuts depend only on which lines are cut (each freed
## node pays out once), so the search visits each set of cut lines at most once.
## Pulling out is free, so an enchantment can come out as soon as its chain is cut.


## One way to clear a board: what to dissolve, then the order to cut in
class Solution:
	extends RefCounted

	var dissolves: Array[EnchantmentMaterialDefinition] = []
	## Edge keys in cutting order
	var cuts: Array[String] = []
	## The runes left over at the end
	var runes_left := RuneSet.new()

	## The plan as DisenchantSteps: the dissolves, the cuts, then pulling out `targets`
	func steps(targets: Array[PlacementState], board: DisenchantBoard) -> Array[DisenchantStep]:
		var out: Array[DisenchantStep] = []
		for m in dissolves:
			out.append(DisenchantStep.dissolve(m))
		for k in cuts:
			var ends := board.edge_ends(k)
			out.append(DisenchantStep.cut(ends[0], ends[1]))
		for p in targets:
			out.append(DisenchantStep.pull_out(p.id))
		return out

	func describe_dissolves() -> String:
		var names: Array[String] = []
		for m in dissolves:
			names.append(InscriptionBoard.material_name(m))
		return ", ".join(names) if not names.is_empty() else "nothing"


## The most materials a solution may dissolve
var max_dissolves: int = 6
## Stop a cut-order search after this many sets of cut lines (guards against huge boards)
var max_states: int = 200000

var board: DisenchantBoard


func _init(disenchant_board: DisenchantBoard) -> void:
	board = disenchant_board


## Every line that has to be cut to pull out all of `targets`
func lines_to_cut(targets: Array[PlacementState]) -> Array[String]:
	var out: Array[String] = []
	for p in targets:
		for k in board.chain(p):
			if k not in out:
				out.append(k)
	return out


## The cheapest ways to clear `targets` with materials from `available` ({material: count}):
## every combination with the fewest dissolves that works, each with one cut order.
## Empty when nothing up to max_dissolves works.
func solve(targets: Array[PlacementState], available: Dictionary) -> Array[Solution]:
	var edges := lines_to_cut(targets)
	var mats: Array[EnchantmentMaterialDefinition] = []
	for m: EnchantmentMaterialDefinition in available:
		if available[m] > 0 and not RuneSet.copy_of(m.dissolve_runes).is_empty():
			mats.append(m)
	mats.sort_custom(
		func(x, y): return InscriptionBoard.material_name(x) < InscriptionBoard.material_name(y)
	)
	for size in max_dissolves + 1:
		var found: Array[Solution] = []
		for combo in _combinations(mats, available, size, 0):
			var start := RuneSet.new()
			for m in combo:
				start = start.plus(m.dissolve_runes)
			var s := find_cut_order(edges, start)
			if s:
				s.dissolves.assign(combo)
				found.append(s)
		if not found.is_empty():
			return found
	return []


## A cut order that cuts every line in `edges` starting with `start` runes, or null if none does
func find_cut_order(edges: Array[String], start: RuneSet) -> Solution:
	var n := edges.size()
	assert(n < 63, "Too many lines for the checker")
	var full := (1 << n) - 1
	var costs: Array[RuneSet] = []
	for k in edges:
		costs.append(board.edge_cost(k))
	# For each line's ends: the mask of every line at that node, and its harvest
	var ends := []
	for k in edges:
		var pair := []
		for node in board.edge_ends(k):
			var mask := 0
			for other in board.node_edges(node):
				var i := edges.find(other)
				mask |= (1 << i) if i >= 0 else (1 << 62)  # 1 << 62: a line we never cut
			pair.append([mask, board.node_harvest_runes(node)])
		ends.append(pair)

	var parent := {0: [-1, -1]}  ## cut set -> [previous set, line cut]
	var stack: Array = [[0, start]]
	while not stack.is_empty() and parent.size() <= max_states:
		var top: Array = stack.pop_back()
		var cut: int = top[0]
		var runes: RuneSet = top[1]
		if cut == full:
			return _solution(edges, parent, cut, runes)
		for i in n:
			var bit := 1 << i
			if cut & bit or not runes.covers(costs[i]):
				continue
			var next := cut | bit
			if parent.has(next):
				continue
			var after := runes.minus(costs[i])
			for end in ends[i]:
				if end[0] & ~next == 0:
					after = after.plus(end[1])
			parent[next] = [cut, i]
			stack.append([next, after])
	return null


func _solution(edges: Array[String], parent: Dictionary, cut: int, runes: RuneSet) -> Solution:
	var s := Solution.new()
	s.runes_left = runes
	var at := cut
	while at != 0:
		var step: Array = parent[at]
		s.cuts.push_front(edges[step[1]])
		at = step[0]
	return s


## Every multiset of `size` materials from mats[from..], within what's available
func _combinations(
	mats: Array[EnchantmentMaterialDefinition], available: Dictionary, size: int, from: int
) -> Array:
	if size == 0:
		return [[]]
	var out := []
	for i in range(from, mats.size()):
		var m := mats[i]
		for take in range(1, mini(available[m], size) + 1):
			var head := []
			for t in take:
				head.append(m)
			for rest in _combinations(mats, available, size - take, i + 1):
				out.append(head + rest)
	return out
