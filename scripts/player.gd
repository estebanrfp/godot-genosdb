extends CharacterBody2D

## Top-down farmer with a full animation set: idle / walk / chop in 4 directions
## (side mirrored for left). Press "chop" near a tree to hit it. Wood lives here for
## now; the multiplayer layer will route it through GenosDB.

const SPEED := 82.0
const CHOP_TIME := 0.32

signal wood_changed(amount: int)

var facing := Vector2.DOWN
var dir_name := "down"
var wood := 0
var chop_timer := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var chop_area: Area2D = $ChopArea

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * SPEED
	if input != Vector2.ZERO:
		facing = input.normalized()
		if absf(input.x) > absf(input.y):
			dir_name = "side"
			anim.flip_h = input.x < 0.0
		elif input.y < 0.0:
			dir_name = "up"
			anim.flip_h = false
		else:
			dir_name = "down"
			anim.flip_h = false
		chop_area.position = facing * 12.0
	move_and_slide()

	if chop_timer > 0.0:
		chop_timer -= delta
	if Input.is_action_just_pressed("chop") and chop_timer <= 0.0:
		chop_timer = CHOP_TIME
		_chop()

	_update_anim(input)

## Pick the right clip for the current state and facing.
func _update_anim(input: Vector2) -> void:
	if chop_timer > 0.0:
		anim.play("chop_" + dir_name)
	elif input != Vector2.ZERO:
		anim.play("walk_" + dir_name)
	else:
		anim.play("idle_" + dir_name)

## Hit the first tree overlapping the chop area in the facing direction.
func _chop() -> void:
	for a in chop_area.get_overlapping_areas():
		if a.is_in_group("tree") and a.has_method("chop"):
			a.chop(1)
			break

func add_wood(n: int) -> void:
	wood += n
	wood_changed.emit(wood)
