extends Node2D

## Demo orchestrator. Uses the godot_genosdb API, which mirrors GenosDB:
##   positions -> Net.send (ephemeral channel)   trees -> Net.put / Net.map (graph)

const REMOTE_PLAYER := preload("res://scenes/remote_player.tscn")
const ROOM_ID := "granja-genosdb-demo"
const SEND_INTERVAL := 0.06   ## ~16 Hz position broadcast

@onready var player: CharacterBody2D = $Player

var _remotes: Dictionary = {}   ## peerId -> remote farmer node
var _trees: Dictionary = {}     ## tree_id -> tree node
var _send_accum := 0.0

func _ready() -> void:
	for t in $Trees.get_children():
		var tid: Variant = t.get("tree_id")
		if tid != null and tid != "":
			_trees[tid] = t
	Net.peer_join.connect(_on_peer_join)
	Net.peer_leave.connect(_on_peer_leave)
	Net.message.connect(_on_message)
	Net.graph_changed.connect(_on_graph)
	Net.join(ROOM_ID)
	Net.map({})   # subscribe to the shared world graph (all nodes)

func _process(delta: float) -> void:
	_send_accum += delta
	if _send_accum >= SEND_INTERVAL:
		_send_accum = 0.0
		Net.send({
			"x": player.global_position.x,
			"y": player.global_position.y,
			"a": player.anim.animation,
			"f": player.anim.flip_h,
		})

# --- Players (ephemeral channel) ---

func _on_peer_join(id: String) -> void:
	if _remotes.has(id):
		return
	var r := REMOTE_PLAYER.instantiate()
	r.name = "Remote_" + id.substr(0, 6)
	add_child(r)
	r.set_label(id.substr(0, 4))
	_remotes[id] = r

func _on_peer_leave(id: String) -> void:
	if _remotes.has(id):
		_remotes[id].queue_free()
		_remotes.erase(id)

func _on_message(id: String, data: Dictionary) -> void:
	if not _remotes.has(id):
		_on_peer_join(id)
	var r: Node = _remotes.get(id)
	if r:
		r.receive_state(data)

# --- Trees (persistent graph) ---

func _on_graph(id: String, _action: String, data: Dictionary) -> void:
	if data.get("type", "") != "tree":
		return
	var t: Node = _trees.get(id)
	if t and is_instance_valid(t):
		t.apply_remote(data)
