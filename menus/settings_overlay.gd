class_name SettingsOverlay
extends RefCounted

## Opens the settings menu over another menu, once a settings scene exists at SCENE_PATH.
## The settings scene closes itself with a `closed` signal, or by hiding.

const SCENE_PATH := "res://menus/settings_menu.tscn"
const CLOSED_SIGNAL := &"closed"


static func is_available() -> bool:
	return ResourceLoader.exists(SCENE_PATH)


## Shows the settings menu on top of `parent`; returns it, or null when there is none yet
static func open(parent: Control) -> Control:
	if not is_available():
		return null
	var scene := load(SCENE_PATH) as PackedScene
	var menu := scene.instantiate() as Control
	if menu == null:
		return null
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(menu)
	if menu.has_signal(CLOSED_SIGNAL):
		menu.connect(CLOSED_SIGNAL, menu.queue_free)
	else:
		menu.visibility_changed.connect(
			func() -> void:
				if not menu.visible:
					menu.queue_free()
		)
	return menu
