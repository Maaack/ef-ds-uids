@tool
extends EditorContextMenuPlugin

const ACCEPTED_EXTENSIONS : Array[String] = ["tres", "tscn", "gd"]
const UID_IN_FILE_EXTENSIONS : Array[String] = ["tres", "tscn"]

const UID_PREG_MATCH = r'uid:\/\/([0-9a-z]+)'

func _popup_menu(paths):
	var icon_texture = preload("res://addons/ef_ds_uids/replace.svg")
	if not paths.is_empty():
		var has_useable_extension : bool = false
		for path in paths:
			if path is String:
				if path.get_extension() in ACCEPTED_EXTENSIONS:
					has_useable_extension = true
					break
		if has_useable_extension:
			add_context_menu_item("Replace UIDs", _replace_uids, icon_texture)

func _remove_uid(content : String) -> String:
	var regex = RegEx.new()
	regex.compile(UID_PREG_MATCH)
	var regex_match := regex.search(content)
	var text_uid = regex_match.get_string(1)
	var int_uid = ResourceUID.text_to_id(text_uid)
	ResourceUID.remove_id(int_uid)
	return regex.sub(content, "")

func _replace_uid(content : String, new_uid : String) -> String:
	var regex = RegEx.new()
	regex.compile(UID_PREG_MATCH)
	var regex_match := regex.search(content)
	var text_uid = regex_match.get_string(1)
	var int_uid = ResourceUID.text_to_id(text_uid)
	ResourceUID.remove_id(int_uid)
	return regex.sub(content, 'uid://%s' % new_uid)

func _get_first_uid(content : String) -> String:
	var regex = RegEx.new()
	regex.compile(UID_PREG_MATCH)
	var regex_match := regex.search(content)
	return regex_match.get_string(1)

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

func _replace_file_uid(path : String, new_id : String) -> String:
	var file_content = _get_file_text(path)
	var old_uid = _get_first_uid(file_content)
	var int_uid = ResourceUID.text_to_id(old_uid)
	ResourceUID.remove_id(int_uid)
	var replaced_content := _replace_uid(file_content, new_id)
	_save_file_text(path, replaced_content)
	return old_uid

func _process_file(
	file_path: String,
	search_text: String,
	replace_text: String
) -> void:
	var contents := _get_file_text(file_path)
	if not contents.contains(search_text):
		return
	var new_contents := contents.replace(search_text, replace_text)
	_save_file_text(file_path, new_contents)

func _process_directory(
	path: String,
	search_text: String,
	replace_text: String,
	extensions: PackedStringArray
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
			_process_directory(full_path, search_text, replace_text, extensions)
		elif name.get_extension() in extensions:
			_process_file(full_path, search_text, replace_text)
	dir.list_dir_end()
	
func find_and_replace_in_project(
	search_text: String,
	replace_text: String,
	root_path: String = "res://",
	extensions: PackedStringArray = ["gd", "tscn", "tres", "cfg", "json", "txt"]
) -> void:
	_process_directory(root_path, search_text, replace_text, extensions)

func _replace_uids(paths):
	for path in paths:
		var extension = path.get_extension()
		if extension in UID_IN_FILE_EXTENSIONS:
			var int_uid := ResourceUID.create_id_for_path(path)
			var new_uid = ResourceUID.id_to_text(int_uid).trim_prefix("uid://")
			var old_uid = _replace_file_uid(path, new_uid)
			find_and_replace_in_project(old_uid, new_uid)
		elif extension == "gd":
			var int_uid := ResourceUID.create_id_for_path(path)
			var new_uid = ResourceUID.id_to_text(int_uid).trim_prefix("uid://")
			var old_uid = _replace_file_uid(path + ".uid", new_uid)
			find_and_replace_in_project(old_uid, new_uid)
