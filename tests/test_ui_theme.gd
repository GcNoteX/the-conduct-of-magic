extends Node

"""
Headless checks for the project theme.
Run: godot --headless --path . res://tests/test_ui_theme.tscn
Exits with code 1 if any check fails.
"""

const PROJECT_THEME_SETTING := "gui/theme/custom"
const THEME_PATH := "res://ui/main_theme.tres"

var _failures := 0
var _checks := 0


func _ready() -> void:
	test_project_uses_theme()
	test_variations()
	test_tooltip_is_opaque()
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func test_project_uses_theme() -> void:
	check(ProjectSettings.get_setting(PROJECT_THEME_SETTING) == THEME_PATH, "project theme is set")
	var theme: Theme = load(THEME_PATH)
	check(theme.default_font != null, "the theme has a default font")
	check(theme.default_font_size >= 20, "body text is at least 20 px")


func test_variations() -> void:
	var theme: Theme = load(THEME_PATH)
	for variation in UiStyles.ALL:
		check(theme.get_type_variation_base(variation) != &"", "%s is in the theme" % variation)


func test_tooltip_is_opaque() -> void:
	var theme: Theme = load(THEME_PATH)
	for type_name in [&"TooltipPanel", UiStyles.DARK_TOOLTIP_PANEL]:
		var panel := theme.get_stylebox("panel", type_name) as StyleBoxFlat
		check(panel != null and panel.bg_color.a == 1.0, "%s background is opaque" % type_name)
