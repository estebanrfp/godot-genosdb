extends Node2D

## Demo orchestrator. Uses the godot_genosdb API, which mirrors GenosDB:
##   positions -> Net.send (ephemeral channel)   trees -> Net.put / Net.map (graph)
##
## SHARED WOOD: the wood total is a co-op team value derived from the graph by
## counting unique "fell" event nodes — one per tree actually felled (not per hit),
## a race-free grow-only counter. Concurrent fells never clobber each other, and a
## regrown tree felled again adds another node. Late-joiners get the full history
## via 'initial', so everyone sees the same total.

signal wood_changed(total: int)

const REMOTE_PLAYER := preload("res://scenes/remote_player.tscn")
const ROOM_ID := "genosdb-farm-demo"

## Recommended practice: pass your own Nostr relays. GenosDB ships its own working
## list, but those community relays may be updated over time — passing your own
## (most public relays are free) means peer discovery doesn't depend on the defaults.
## This is the same list GenosRTC uses and is currently working. (Empty list = use
## GenosDB's defaults.) See addons/godot_genosdb/README.md.
const RELAYS := [
	"wss://ftp.halifax.rwth-aachen.de/nostr",
	"wss://nostr.data.haus",
	"wss://nostr.mom",
	"wss://nostr.oxtr.dev",
	"wss://nostr.sathoarder.com",
	"wss://nostr.vulpem.com",
	"wss://relay.binaryrobot.com",
	"wss://relay.fountain.fm",
	"wss://relay.mostro.network",
	"wss://relay.nostrdice.com",
	"wss://sendit.nosflare.com",
	"wss://yabu.me/v2",
	"wss://relay.damus.io",
]

const SEND_INTERVAL := 0.06   ## ~16 Hz position broadcast
const STALE_MS := 8000        ## drop a remote with no updates for this long (ghost cleanup)
const WOOD_PER_TREE := 1      ## one felled tree = +1 (the shared total = trees felled)

@onready var player: CharacterBody2D = $Player

var _remotes: Dictionary = {}     ## peerId -> remote farmer node
var _last_seen: Dictionary = {}   ## peerId -> last update time (ms)
var _trees: Dictionary = {}       ## tree_id -> tree node
var _fells: Dictionary = {}       ## fell event id -> true (for the shared wood total)
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
	Net.join(ROOM_ID, RELAYS)   # passing our own relays = production-ready
	Net.map({})                 # subscribe to the shared world graph (all nodes)

func _process(delta: float) -> void:
	_send_accum += delta
	if _send_accum >= SEND_INTERVAL:
		_send_accum = 0.0
		Net.send({
			"x": player.global_position.x,
			"y": player.global_position.y,
			"a": player.anim.animation,
			"f": player.anim.flip_h,
			"c": player.color.to_html(false),
		})
	_cull_stale()

# --- Players (ephemeral channel) ---

func _on_peer_join(id: String) -> void:
	if _remotes.has(id):
		return
	var r := REMOTE_PLAYER.instantiate()
	r.name = "Remote_" + id.substr(0, 6)
	add_child(r)
	r.set_label(id.substr(0, 4))
	_remotes[id] = r
	_last_seen[id] = Time.get_ticks_msec()

func _on_peer_leave(id: String) -> void:
	_drop(id)

func _on_message(id: String, data: Dictionary) -> void:
	if not _remotes.has(id):
		_on_peer_join(id)
	_last_seen[id] = Time.get_ticks_msec()
	var r: Node = _remotes.get(id)
	if r:
		r.receive_state(data)

## Remove peers that left without a clean peer:leave (closed tab, lost connection).
func _cull_stale() -> void:
	var now := Time.get_ticks_msec()
	for id in _remotes.keys():
		if now - int(_last_seen.get(id, now)) > STALE_MS:
			_drop(id)

func _drop(id: String) -> void:
	if _remotes.has(id):
		_remotes[id].queue_free()
		_remotes.erase(id)
	_last_seen.erase(id)

# --- Trees + shared wood (persistent graph) ---

func _on_graph(id: String, action: String, data: Dictionary) -> void:
	match data.get("type", ""):
		"tree":
			var t: Node = _trees.get(id)
			if t and is_instance_valid(t):
				t.apply_remote(data)
		"fell":
			# Shared, race-free wood total: count unique felled-tree events.
			if action != "removed" and not _fells.has(id):
				_fells[id] = true
				wood_changed.emit(_fells.size() * WOOD_PER_TREE)
