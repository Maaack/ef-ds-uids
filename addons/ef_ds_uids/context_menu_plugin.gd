@tool
extends EditorContextMenuPlugin

const UID_IN_FILE_EXTENSIONS : PackedStringArray = ["tres", "tscn"]
const UID_IN_IMPORT_FILE_EXTENSIONS : PackedStringArray = ["png", "svg", "gif", "wav", "mp3", "ogg", "gltf", "glb", "dae", "obj", "fbx"]
const UID_IN_UID_FILE_EXTENSIONS : PackedStringArray = ["gd"]
const FIND_AND_REPLACE_EXTENSIONS : PackedStringArray = ["gd", "tscn", "tres", "cfg", "json", "txt"]
const UID_PREG_MATCH = r'uid:\/\/([0-9a-z]+)'
const UID_IMPORT_PREG_MATCH = r'uid="uid:\/\/[0-9a-z]+" '


func _expand_to_files(paths : PackedStringArray) -> PackedStringArray:
	var result : PackedStringArray = []
	var seen : Dictionary = {}
	for path in paths:
		_collect_files(path, result, seen)
	return result

func _collect_files(path : String, result : PackedStringArray, seen : Dictionary) -> void:
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

func _get_first_uid(content : String) -> String:
	var regex = RegEx.new()
	regex.compile(UID_PREG_MATCH)
	var regex_match := regex.search(content)
	return regex_match.get_string()

func _get_file_text(file_path : String) -> String:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Plugin error - failed to read file: `%s`" % file_path)
		return ""
	var content = file.get_as_text()
	file.close()
	return content

func _save_file_text(file_path : String, content : String) -> void:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_warning("Plugin error - failed to write file: %s" % file_path)
		return
	file.store_string(content)
	file.close()

func _remove_file_uid(path : String) -> String:
	var file_content = _get_file_text(path)
	var removed_uid = _get_first_uid(file_content)
	var int_uid = ResourceUID.text_to_id(removed_uid)
	if ResourceUID.has_id(int_uid):
		ResourceUID.remove_id(int_uid)
	return removed_uid

func _find_and_replace_in_file(
	file_path : String,
	search_text : String,
	replace_text : String,
	skip_first : bool = false
) -> void:
	var contents := _get_file_text(file_path)
	if not contents.contains(search_text):
		return
	var new_contents : String
	if skip_first:
		var ignore_first = contents.find(search_text) + search_text.length()
		var ignore_content := contents.substr(0, ignore_first)
		var remaining_content := contents.substr(ignore_first)
		new_contents = ignore_content + remaining_content.replace(search_text, replace_text)
	else: 
		new_contents = contents.replace(search_text, replace_text)
	_save_file_text(file_path, new_contents)

func _find_and_replace_in_directory(
	path : String,
	search_text : String,
	replace_text : String,
	extensions : PackedStringArray,
	skip_first : bool = false
) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("Plugin error - failed to open directory: %s" % path)
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var full_path := path.path_join(name)
		if dir.current_is_dir():
			_find_and_replace_in_directory(full_path, search_text, replace_text, extensions)
		elif name.get_extension() in extensions:
			_find_and_replace_in_file(full_path, search_text, replace_text, skip_first)
	dir.list_dir_end()
	
func find_and_replace_in_project(
	search_text : String,
	replace_text : String,
	root_path : String = "res://",
	extensions : PackedStringArray = FIND_AND_REPLACE_EXTENSIONS
) -> void:
	_find_and_replace_in_directory(root_path, search_text, replace_text, extensions, true)

func _find_and_replace_uid(path : String, file_extension : String = "") -> void:
	var old_uid = _remove_file_uid(path + file_extension)
	var int_uid := ResourceUID.create_id_for_path(path)
	var new_uid = ResourceUID.id_to_text(int_uid)
	if not ResourceUID.has_id(int_uid):
		ResourceUID.add_id(int_uid, path)
	_find_and_replace_in_file(path + file_extension, old_uid, new_uid)
	find_and_replace_in_project(old_uid, new_uid)
	
func _find_and_erase_uid(path : String, file_extension : String = "") -> void:
	var old_uid = _remove_file_uid(path + file_extension)
	find_and_replace_in_project(old_uid, "")

func _remove_imported_uids(path : String, file_extension : String = "") -> void:
	var file_content = _get_file_text(path + file_extension)
	var regex = RegEx.new()
	regex.compile(UID_IMPORT_PREG_MATCH)
	var new_content = regex.sub(file_content, "", true)
	_save_file_text(path + file_extension, new_content)

func _parse_path_extensions(paths : PackedStringArray, method : Callable) -> void:
	for path in paths:
		var extension = path.get_extension()
		if extension in UID_IN_FILE_EXTENSIONS:
			method.call(path)
		elif extension in UID_IN_IMPORT_FILE_EXTENSIONS:
			method.call(path, ".import")
		elif extension in UID_IN_UID_FILE_EXTENSIONS:
			method.call(path, ".uid")

func _nuke_the_cache() -> void:
	if FileAccess.file_exists("res://.godot/uid_cache.bin"):
		DirAccess.remove_absolute("res://.godot/uid_cache.bin")
		var file_paths = _expand_to_files(["res://.godot/editor/"])
		for path in file_paths:
			if path.get_file().begins_with("filesystem"):
				DirAccess.remove_absolute(path)

func _replace_uids(paths):
	var file_paths = _expand_to_files(paths)
	_parse_path_extensions(file_paths, _find_and_replace_uid)
	_nuke_the_cache()

func _erase_uids(paths):
	var file_paths = _expand_to_files(paths)
	_parse_path_extensions(file_paths, _find_and_erase_uid)
	_nuke_the_cache()

func _erase_imported_uids(paths):
	var file_paths = _expand_to_files(paths)
	_parse_path_extensions(file_paths, _remove_imported_uids)

func _popup_menu(paths):
	var erase_icon = preload("res://addons/ef_ds_uids/assets/eraser.svg")
	var replace_icon = preload("res://addons/ef_ds_uids/assets/replace.svg")
	var accepted_extensions : PackedStringArray = UID_IN_FILE_EXTENSIONS + UID_IN_IMPORT_FILE_EXTENSIONS + UID_IN_UID_FILE_EXTENSIONS
	if paths.is_empty(): return
	var file_paths = _expand_to_files(paths)
	var files_with_matching_extensions : int = 0
	for path in file_paths:
		if path is String:
			if path.get_extension() in accepted_extensions:
				files_with_matching_extensions += 1
				if files_with_matching_extensions > 1:
					break
	if files_with_matching_extensions > 0:
		var uid_text = "UID"
		if files_with_matching_extensions > 1:
			uid_text = "UIDs"
		add_context_menu_item("Replace %s" % uid_text, _replace_uids, replace_icon)
		add_context_menu_item("Erase Imported UIDs", _erase_imported_uids, erase_icon)
