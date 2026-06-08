@tool
extends EditorExportPlugin

## On a Web export, drop genos_bridge.js next to index.html and inject a
## <script type="module"> tag into it — so the GenosDB bridge "just works"
## without the user editing any HTML or export setting.

const BRIDGE_SRC := "res://addons/godot_genosdb/genos_bridge.js"
const TAG := "\t<script type=\"module\" src=\"genos_bridge.js\"></script>\n"

var _is_web := false
var _index_path := ""

func _get_name() -> String:
	return "GenosDBWebBridge"

func _export_begin(features: PackedStringArray, _is_debug: bool, path: String, _flags: int) -> void:
	_is_web = features.has("web")
	_index_path = path

func _export_end() -> void:
	if not _is_web or _index_path.is_empty():
		return
	var dir := _index_path.get_base_dir()
	# 1) Copy the bridge next to the exported index.html.
	var bridge := FileAccess.get_file_as_string(BRIDGE_SRC)
	var out := FileAccess.open(dir.path_join("genos_bridge.js"), FileAccess.WRITE)
	if out:
		out.store_string(bridge)
		out.close()
	# 2) Inject the module tag into index.html (idempotent).
	var html := FileAccess.get_file_as_string(_index_path)
	if not html.is_empty() and not html.contains("genos_bridge.js"):
		html = html.replace("</body>", TAG + "</body>")
		var h := FileAccess.open(_index_path, FileAccess.WRITE)
		if h:
			h.store_string(html)
			h.close()
	print("[godot_genosdb] Web bridge injected into ", _index_path)
