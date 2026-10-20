class_name WorkshopPalette
extends RefCounted

## The workshop's placeholder art that isn't part of the UI theme: the workbench the inscribing
## table sits on and the leather mat under the item. Panel, card and tooltip looks live in the
## project theme (res://ui/main_theme.tres, named in UiStyles); `theme_stylebox` hands out a copy
## of one for code that tints it per card.

const WORKBENCH := preload("res://art/placeholder/workbench_wood.png")
## A nine-patch with LEATHER_MAT_MARGIN pixels of border on each side
const LEATHER_MAT := preload("res://art/placeholder/leather_mat.png")
const LEATHER_MAT_MARGIN := 28


## A copy of a theme type's panel style, safe to change for one control. An empty style when the
## project has no theme or the type has no panel style.
static func theme_stylebox(type_name: StringName) -> StyleBox:
	var theme := ThemeDB.get_project_theme()
	if theme == null or not theme.has_stylebox(&"panel", type_name):
		return StyleBoxFlat.new()
	return theme.get_stylebox(&"panel", type_name).duplicate()
