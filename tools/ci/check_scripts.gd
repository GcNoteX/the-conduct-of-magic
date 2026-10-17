## CI only: loads every project script and exits non-zero if any fails to compile.
## Run with `godot --headless --path . res://tools/ci/check_scripts.tscn`.
extends Node

const SKIP_DIRS: Array[String] = ["res://addons", "res://demo", "res://.godot"]


func _ready() -> void:
	var failed: Array[String] = []
	for path in _find_scripts("res://"):
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			failed.append(path)
	for path in failed:
		printerr("Failed to compile: ", path)
	print("Checked scripts, %d failed." % failed.size())
	get_tree().quit(1 if failed.size() > 0 else 0)


func _find_scripts(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	if dir_path in SKIP_DIRS:
		return found
	for file in DirAccess.get_files_at(dir_path):
		if file.ends_with(".gd"):
			found.append(dir_path.path_join(file))
	for sub in DirAccess.get_directories_at(dir_path):
		found.append_array(_find_scripts(dir_path.path_join(sub)))
	return found
