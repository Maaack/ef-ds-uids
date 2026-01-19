@tool
extends EditorPlugin

const Utilities = preload("res://addons/ef_ds_uids/utilities.gd")

var menu_plugin : EditorContextMenuPlugin 

func _enter_tree() -> void:
	menu_plugin = preload("res://addons/ef_ds_uids/context_menu_plugin.gd").new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, menu_plugin)
	add_tool_menu_item("Clear UID Cache...", Utilities.nuke_the_cache)

func _exit_tree() -> void:
	remove_context_menu_plugin(menu_plugin)
	remove_tool_menu_item("Clear UID Cache...")
