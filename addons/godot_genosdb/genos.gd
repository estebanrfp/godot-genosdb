extends Node

## GenosDB <-> Godot bridge (autoload "Net"). Web-only; every method is a safe
## no-op on desktop, so the same code runs everywhere.
##
## Hybrid sync (GenosDB's recommended model):
##   - EPHEMERAL  : broadcast()  -> message_received   (GenosRTC data channel)
##   - PERSISTENT : db_put()/db_remove() -> graph_changed (reactive graph; late
##                  joiners get current state via the 'initial' action)
##
## The JS half (genos_bridge.js) is auto-injected into the Web export by the
## editor export plugin and loads GenosDB from a CDN.

signal peer_joined(id: String)
signal peer_left(id: String)
signal message_received(id: String, data: Dictionary)
signal graph_changed(id: String, action: String, data: Dictionary)

var enabled := false
var ready_bridge := false

var _pending_room := ""
var _w: JavaScriptObject
var _callbacks: Array = []   # keep JS callback refs alive

func _ready() -> void:
	if not OS.has_feature("web"):
		return
	enabled = true
	_w = JavaScriptBridge.get_interface("window")
	_w.gdOnJoin = _make(_on_join)
	_w.gdOnLeave = _make(_on_leave)
	_w.gdOnMsg = _make(_on_msg)
	_w.gdOnGraph = _make(_on_graph)

func _make(c: Callable) -> JavaScriptObject:
	var cb := JavaScriptBridge.create_callback(c)
	_callbacks.append(cb)
	return cb

## Join (or create) a GenosDB room. All peers using the same id share the world.
## Retries until the injected bridge module has finished loading.
func join(room_id: String) -> void:
	if not enabled:
		return
	_pending_room = room_id
	_try_join()

func _try_join() -> void:
	if bool(_w.__bridgeReady):
		_w.NetJoin(_pending_room)
		ready_bridge = true
	else:
		get_tree().create_timer(0.2).timeout.connect(_try_join, CONNECT_ONE_SHOT)

## Ephemeral broadcast to all peers (fast, not stored). E.g. player positions.
func broadcast(data: Dictionary) -> void:
	if enabled and ready_bridge:
		_w.NetSend(JSON.stringify(data))

## Write/update a node in the shared persistent graph (syncs P2P + persists).
func db_put(id: String, data: Dictionary) -> void:
	if enabled and ready_bridge:
		_w.NetPut(id, JSON.stringify(data))

## Remove a node from the shared graph.
func db_remove(id: String) -> void:
	if enabled and ready_bridge:
		_w.NetRemove(id)

func _on_join(a: Array) -> void:
	peer_joined.emit(str(a[0]))

func _on_leave(a: Array) -> void:
	peer_left.emit(str(a[0]))

func _on_msg(a: Array) -> void:
	var p: Variant = JSON.parse_string(str(a[1]))
	if typeof(p) == TYPE_DICTIONARY:
		message_received.emit(str(a[0]), p)

func _on_graph(a: Array) -> void:
	var p: Variant = JSON.parse_string(str(a[2]))
	if typeof(p) == TYPE_DICTIONARY:
		graph_changed.emit(str(a[0]), str(a[1]), p)
