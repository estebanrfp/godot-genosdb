extends Area2D

## Choppable tree whose state is shared through the GenosDB graph (Net.db_put).
## A LOCAL chop writes the new hp to the graph; peers (and late-joiners, via the
## 'initial' action) receive it through Net.graph_changed -> apply_remote().
## The tree's id is its node name (Tree1..Tree7) — identical on every peer.

@export var tree_id := ""
@export var max_hp := 3
@export var wood_drop := 2

var hp := 0
var _fallen := false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("tree")
	hp = max_hp
	if tree_id == "":
		tree_id = name

func chop(dmg: int = 1) -> void:
	if _fallen:
		return
	hp -= dmg
	_shake()
	Net.db_put(tree_id, {"type": "tree", "hp": hp})
	if hp <= 0:
		_reward_local()
		_topple()

func apply_remote(data: Dictionary) -> void:
	if _fallen:
		return
	hp = int(data.get("hp", hp))
	if hp <= 0:
		_topple()
	else:
		_shake()

func _reward_local() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		players[0].add_wood(wood_drop)

func _shake() -> void:
	var t := create_tween()
	t.tween_property(sprite, "rotation", 0.06, 0.04)
	t.tween_property(sprite, "rotation", -0.06, 0.04)
	t.tween_property(sprite, "rotation", 0.0, 0.04)

func _topple() -> void:
	if _fallen:
		return
	_fallen = true
	monitoring = false
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(sprite, "rotation", 1.2, 0.25)
	t.tween_property(sprite, "modulate:a", 0.0, 0.3)
	t.chain().tween_callback(queue_free)
