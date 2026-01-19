@tool
extends Script

static func _collect_files(path : String, result : PackedStringArray, seen : Dictionary) -> void:
	if FileAccess.file_exists(path):
		if not seen.has(path):
			seen[path] = true
			result.append(path)
		return
	elif DirAccess.dir_exists_absolute(path):
		var dir := DirAccess.open(path)
		if dir == null:
			return
		dir.list_dir_begin()
		while true:
			var name := dir.get_next()
			if name == "":
				break
			if name == "." or name == "..":
				continue
			var full_path := path.path_join(name)
			_collect_files(full_path, result, seen)
		dir.list_dir_end()

static func expand_to_files(paths : PackedStringArray) -> PackedStringArray:
	var result : PackedStringArray = []
	var seen : Dictionary = {}
	for path in paths:
		_collect_files(path, result, seen)
	return result

static func nuke_the_cache() -> void:
	if FileAccess.file_exists("res://.godot/uid_cache.bin"):
		DirAccess.remove_absolute("res://.godot/uid_cache.bin")
		var file_paths = expand_to_files(["res://.godot/editor/"])
		for path in file_paths:
			if path.get_file().begins_with("filesystem"):
				DirAccess.remove_absolute(path)
