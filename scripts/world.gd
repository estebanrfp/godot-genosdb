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

@onready var player: CharacterBody2D = $YSort/Player

var _remotes: Dictionary = {}     ## peerId -> remote farmer node
var _last_seen: Dictionary = {}   ## peerId -> last update time (ms)
var _trees: Dictionary = {}       ## tree_id -> tree node
var _fells: Dictionary = {}       ## fell event id -> true (for the shared wood total)
var _send_accum := 0.0

func _ready() -> void:
	for t in get_tree().get_nodes_in_group("tree"):
		var tid: Variant = t.get("tree_id")
		if tid != null and tid != "":
			_trees[tid] = t
	_build_decor()
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
		})
	_cull_stale()

# --- Players (ephemeral channel) ---

func _on_peer_join(id: String) -> void:
	if _remotes.has(id):
		return
	var r := REMOTE_PLAYER.instantiate()
	r.name = "Remote_" + id.substr(0, 6)
	$YSort.add_child(r)         # under the y-sorted node so depth is correct
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
	if r == null:
		return
	if data.has("chat"):
		r.say(str(data["chat"]))     # chat bubble over the peer's farmer
	else:
		r.receive_state(data)        # position/animation update

## Broadcast a chat message over the GenosDB channel and show it locally.
func send_chat(text: String) -> void:
	var msg := text.strip_edges()
	if msg.is_empty():
		return
	if msg.length() > 80:
		msg = msg.substr(0, 80)
	player.say(msg)
	Net.send({"chat": msg})

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
	# A removed node carries no value, so key off the id we already track.
	if action == "removed":
		if _fells.erase(id):
			wood_changed.emit(_fells.size() * WOOD_PER_TREE)
		return
	match data.get("type", ""):
		"tree":
			var t: Node = _trees.get(id)
			if t and is_instance_valid(t):
				t.apply_remote(data)
		"fell":
			# Shared, race-free wood total: count unique felled-tree events.
			if not _fells.has(id):
				_fells[id] = true
				wood_changed.emit(_fells.size() * WOOD_PER_TREE)

## Reset the SHARED world for everyone: remove every fell event (wood -> 0) and
## regrow all trees. This is the GenosDB remove() side of the API — chopping uses
## put(), resetting uses remove(), and the change propagates to every peer.
func reset_world() -> void:
	for fell_id in _fells.keys():
		Net.remove(fell_id)                                  # GenosDB db.remove(id)
	for tree_id in _trees.keys():
		var t: Node = _trees[tree_id]
		if is_instance_valid(t):
			Net.put({"type": "tree", "hp": t.max_hp}, tree_id)

# --- Decorative cozy-farm props (CC0 Ishtar Pixels pack) ---

## Add a decorative sprite under the y-sorted node. `off` lifts the art so the
## node origin sits at the prop's base (its feet) for correct depth sorting.
func _add_prop(path: String, pos: Vector2, off: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.offset = off
	s.position = pos
	$YSort.add_child(s)
	return s

func _build_decor() -> void:
	var P := "res://assets/farm/"
	# House (80x96) with a solid footprint so players can't walk through it.
	var house := _add_prop(P + "house.png", Vector2(118, 150), Vector2(0, -48))
	var body := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(70, 26)
	col.shape = shape
	col.position = Vector2(0, -13)
	body.add_child(col)
	house.add_child(body)
	# Scattered rocks, logs and a sign for cozy detail.
	_add_prop(P + "rock_grey.png", Vector2(168, 196), Vector2(0, -6))
	_add_prop(P + "rock_brown.png", Vector2(250, 432), Vector2(0, -6))
	_add_prop(P + "rock_grey2.png", Vector2(700, 360), Vector2(0, -6))
	_add_prop(P + "log.png", Vector2(190, 150), Vector2(0, -6))
	_add_prop(P + "wood.png", Vector2(225, 95), Vector2(0, -6))
	_add_prop(P + "sign.png", Vector2(372, 250), Vector2(0, -8))

	# Fenced crop field (bottom-right tilled plot).
	var fx0 := 456; var fx1 := 648; var fy0 := 280; var fy1 := 408
	for x in range(fx0, fx1 + 1, 16):
		_add_prop(P + "fence_f.png", Vector2(x, fy0), Vector2(0, -8))   # top rail
		_add_prop(P + "fence_f.png", Vector2(x, fy1), Vector2(0, -8))   # bottom rail
	for y in range(fy0 + 16, fy1, 16):
		_add_prop(P + "fence_g.png", Vector2(fx0, y), Vector2(0, -8))   # left posts
		_add_prop(P + "fence_g.png", Vector2(fx1, y), Vector2(0, -8))   # right posts
	# Rows of crops inside the field.
	var crops := [P + "crop_bush.png", P + "crop_stalk.png", P + "crop_sprout.png"]
	var ci := 0
	for cy in range(fy0 + 24, fy1 - 8, 22):
		for cx in range(fx0 + 22, fx1 - 10, 26):
			_add_prop(crops[ci % crops.size()], Vector2(cx, cy), Vector2(0, -8))
			ci += 1
