extends Node

## GenosDB <-> Godot bridge (autoload "Net"). Web-only; every method is a safe
## no-op on desktop, so the same code runs everywhere.
##
## The API mirrors GenosDB on purpose, so using this plugin teaches the real
## GenosDB API:
##   GenosDB (JS)                    ->  Godot (Net)
##   await gdb(name, {rtc:true})     ->  Net.join(name)
##   room.on('peer:join'/'leave')    ->  signals peer_join / peer_leave
##   channel.send(data)              ->  Net.send(data)            (ephemeral)
##   channel.on('message', cb)       ->  signal message(id, data)  (ephemeral)
##   db.put(node, id)                ->  Net.put(data, id)          (graph)
##   db.remove(id)                   ->  Net.remove(id)             (graph)
##   db.map(query, cb)               ->  Net.map(query) + signal graph_changed
##
## (db.get() isn't exposed because Godot's Object.get() collides; use map().)

signal peer_join(id: String)
signal peer_leave(id: String)
signal message(id: String, data: Dictionary)                       # ephemeral channel
signal graph_changed(id: String, action: String, data: Dictionary) # graph (db.map)

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

## Open a room (= a GenosDB instance named `room_id`). All peers using the same
## id share the world. Retries until the injected bridge module has loaded.
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

## EPHEMERAL — broadcast to every peer (GenosRTC data channel). Not stored.
func send(data: Dictionary) -> void:
	if enabled and ready_bridge:
		_w.NetSend(JSON.stringify(data))

## GRAPH — insert/update a node (GenosDB db.put). Synced P2P and persisted.
## Pass an explicit id, or leave it empty to let GenosDB generate one.
func put(data: Dictionary, id: String = "") -> void:
	if enabled and ready_bridge:
		_w.NetPut(JSON.stringify(data), id)

## GRAPH — delete a node (GenosDB db.remove).
func remove(id: String) -> void:
	if enabled and ready_bridge:
		_w.NetRemove(id)

## GRAPH — subscribe to a query (GenosDB db.map). Updates arrive on graph_changed.
## Empty query = all nodes. Late-joiners receive current state via action "initial".
func map(query: Dictionary = {}) -> void:
	if enabled and ready_bridge:
		_w.NetMap(JSON.stringify(query))

func _on_join(a: Array) -> void:
	peer_join.emit(str(a[0]))

func _on_leave(a: Array) -> void:
	peer_leave.emit(str(a[0]))

func _on_msg(a: Array) -> void:
	var p: Variant = JSON.parse_string(str(a[1]))
	if typeof(p) == TYPE_DICTIONARY:
		message.emit(str(a[0]), p)

func _on_graph(a: Array) -> void:
	var p: Variant = JSON.parse_string(str(a[2]))
	if typeof(p) == TYPE_DICTIONARY:
		graph_changed.emit(str(a[0]), str(a[1]), p)
