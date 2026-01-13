@tool
extends EditorPlugin

var menu_plugin : EditorContextMenuPlugin 

func _enter_tree() -> void:
	menu_plugin = preload("res://addons/ef_ds_uids/context_menu_plugin.gd").new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, menu_plugin)

func _exit_tree() -> void:
	remove_context_menu_plugin(menu_plugin)
