@tool
extends EditorPlugin

## Registers the "Net" autoload (the GenosDB bridge) and an export plugin that
## auto-injects the JS bridge into Web exports. Zero manual setup.

const AUTOLOAD_NAME := "Net"
const AUTOLOAD_PATH := "res://addons/godot_genosdb/genos.gd"
const ExportPlugin := preload("res://addons/godot_genosdb/export_plugin.gd")

var _export_plugin: EditorExportPlugin

func _enter_tree() -> void:
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	_export_plugin = ExportPlugin.new()
	add_export_plugin(_export_plugin)

func _exit_tree() -> void:
	if ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)
	if _export_plugin:
		remove_export_plugin(_export_plugin)
		_export_plugin = null
