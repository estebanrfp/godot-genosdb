extends Area2D

## Choppable tree whose state is shared through the GenosDB graph (Net.put).
## A LOCAL chop writes the new hp to the graph; peers (and late-joiners, via the
## 'initial' action) receive it through Net.graph_changed -> apply_remote().
## The tree's id is its node name (Tree1..Tree7) — identical on every peer.
##
## A felled tree REGROWS after REGROW_TIME, so the shared world never runs out of
## trees (no permanent deforestation) and a deforested persisted world self-heals.

@export var tree_id := ""
@export var max_hp := 3
@export var wood_drop := 2

const REGROW_TIME := 8.0   ## seconds a felled tree stays down before growing back

var hp := 0
var _fallen := false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("tree")
	hp = max_hp
	if tree_id == "":
		tree_id = name

## Local chop: lower hp, share the tree state, and record a unique chop event so
## the shared wood total counts EVERY chop (a race-free grow-only counter).
func chop(dmg: int = 1) -> void:
	if _fallen:
		return
	hp -= dmg
	_shake()
	Net.put({"type": "tree", "hp": hp}, tree_id)
	Net.put({"type": "chop", "tree": tree_id}, _chop_event_id())
	if hp <= 0:
		_topple()

## Unique id per chop. Only the chopping peer generates it, so it never collides.
func _chop_event_id() -> String:
	return "chop_%s_%d_%d" % [tree_id, Time.get_ticks_usec(), randi()]

## Apply a tree state received from a peer (or our own echo).
func apply_remote(data: Dictionary) -> void:
	var new_hp := int(data.get("hp", hp))
	if new_hp <= 0 and not _fallen:
		hp = new_hp
		_topple()
	elif new_hp > 0 and _fallen:
		_regrow()                       # a peer's regrow reached us
	elif new_hp > 0 and new_hp < max_hp:
		hp = new_hp
		_shake()

func _shake() -> void:
	var t := create_tween()
	t.tween_property(sprite, "rotation", 0.06, 0.04)
	t.tween_property(sprite, "rotation", -0.06, 0.04)
	t.tween_property(sprite, "rotation", 0.0, 0.04)

func _topple() -> void:
	if _fallen:
		return
	_fallen = true
	monitoring = false                  # stop being choppable while down
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(sprite, "rotation", 1.2, 0.25)
	t.tween_property(sprite, "modulate:a", 0.0, 0.3)
	get_tree().create_timer(REGROW_TIME).timeout.connect(_regrow)

## Grow back: restore hp, fade in, and share the refreshed state. Guarded so the
## local timer and a peer echo can't double-apply.
func _regrow() -> void:
	if not _fallen:
		return
	_fallen = false
	hp = max_hp
	monitoring = true
	sprite.rotation = 0.0
	var t := create_tween()
	t.tween_property(sprite, "modulate:a", 1.0, 0.3)
	Net.put({"type": "tree", "hp": hp}, tree_id)
