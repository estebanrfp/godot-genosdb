extends CharacterBody2D

## Top-down farmer (the local player). Picks a random tint at startup and
## broadcasts it, so every peer sees this player in the same color (a simple,
## consistent identity without needing a seed). Wood lives here.

const SPEED := 82.0
const CHOP_TIME := 0.32

var facing := Vector2.DOWN
var dir_name := "down"
var chop_timer := 0.0
var color := Color.WHITE

## Vivid tints that all contrast with the green farm (no greens that camouflage).
const PALETTE := [
	Color("ff5a5a"), Color("4aa3ff"), Color("ffb14a"), Color("c77dff"),
	Color("ff7ad9"), Color("ffe14a"), Color("ff8c42"), Color("63e6ff"),
	Color("ffffff"), Color("b0b0ff"),
]

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var chop_area: Area2D = $ChopArea

func _ready() -> void:
	add_to_group("player")
	randomize()
	color = PALETTE[randi() % PALETTE.size()]   # distinct, readable tint per player
	anim.modulate = color

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
