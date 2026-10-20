class_name DisenchantPlanPanel
extends VBoxContainer

## The disenchant plan as a numbered list, with what each step costs and gives and the runes
## held after it. A step that can't be done shows red, and the steps waiting behind it grey.
## Steps are undone from the end with the Undo button.

signal undo_requested

const COLOR_BLOCKED := "f06060"
const COLOR_WAITING := "7b7884"

var _list: RichTextLabel
var _undo: Button


func _init() -> void:
	add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "Disenchant plan"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	_list = RichTextLabel.new()
	_list.bbcode_enabled = true
	_list.scroll_following = true
	_list.custom_minimum_size.y = 260
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_list)
	_undo = Button.new()
	_undo.text = "Undo last step"
	_undo.focus_mode = Control.FOCUS_NONE  # So Space and Tab stay with the palette
	_undo.pressed.connect(undo_requested.emit)
	add_child(_undo)


func show_plan(board: DisenchantBoard) -> void:
	var outs := board.outcomes()
	_undo.disabled = outs.is_empty()
	if outs.is_empty():
		_list.text = (
			(
				"[color=#%s]Nothing planned. Double-click a material to dissolve it for runes, "
				% COLOR_WAITING
			)
			+ "then click lines to cut them.[/color]"
		)
		return
	var text := ""
	for i in outs.size():
		text += _row(board, i, outs[i]) + "\n"
	_list.text = text.strip_edges()


func _row(board: DisenchantBoard, i: int, o: DisenchantBoard.Outcome) -> String:
	var head := "%d. %s" % [i + 1, board.describe_step(o.step)]
	if o.after_blocked:
		return "[color=#%s]%s\n    waiting on an earlier step[/color]" % [COLOR_WAITING, head]
	if o.error != "":
		return "[color=#%s]%s\n    ✗ %s[/color]" % [COLOR_BLOCKED, head, o.error]
	var parts: Array[String] = []
	if not o.spent.is_empty():
		parts.append("−" + o.spent.describe())
	if not o.gained.is_empty():
		parts.append("+" + o.gained.describe())
	parts.append("→ " + runes_bbcode(o.runes))
	return "%s\n    %s" % [head, "  ".join(parts)]


## The four rune counts as coloured numbers, like the rune bar
static func runes_bbcode(runes: RuneSet) -> String:
	var counts := runes.to_array()
	var out: Array[String] = []
	for i in counts.size():
		out.append("[color=#%s]%d[/color]" % [BoardView.RUNE_COLORS[i].to_html(false), counts[i]])
	return " ".join(out)
