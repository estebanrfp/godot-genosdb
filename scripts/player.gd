extends CharacterBody2D

## Top-down farmer (the local player). Uses a single-frame cozy character sprite
## (CC0 Ishtar Pixels) animated procedurally: idle sway, walk bounce, chop swing.
## Picks one of three character variants at startup and broadcasts the index, so
## every peer sees the same farmer (a simple, consistent identity).

const SPEED := 82.0
const CHOP_TIME := 0.32
const CHARS := [
	"res://assets/farm/farmer_red.png",
	"res://assets/farm/farmer_blonde.png",
	"res://assets/farm/farmer_green.png",
]

var char_index := 0
var facing := Vector2.DOWN
var flip := false
var is_moving := false
var chop_timer := 0.0
var _t := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var chop_area: Area2D = $ChopArea

func _ready() -> void:
	add_to_group("player")
	randomize()
	char_index = randi() % CHARS.size()
	sprite.texture = load(CHARS[char_index])

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * SPEED
	is_moving = input != Vector2.ZERO
	if is_moving:
		facing = input.normalized()
		if absf(input.x) > 0.1:
			flip = input.x < 0.0
		chop_area.position = facing * 12.0
	move_and_slide()
	# Keep the farmer inside the farm bounds (matches the ground + camera limits).
	global_position.x = clampf(global_position.x, 12.0, 756.0)
	global_position.y = clampf(global_position.y, 24.0, 470.0)

	if chop_timer > 0.0:
		chop_timer -= delta
	if Input.is_action_just_pressed("chop") and chop_timer <= 0.0:
		chop_timer = CHOP_TIME
		_chop()

	_animate(delta)

## Procedural juice for the single-frame character: bob, bounce, chop swing.
func _animate(delta: float) -> void:
	_t += delta
	sprite.flip_h = flip
	if chop_timer > 0.0:
		var p := 1.0 - (chop_timer / CHOP_TIME)          # 0 -> 1 over the swing
		sprite.rotation = sin(p * PI) * 0.5 * (-1.0 if flip else 1.0)
		sprite.position.y = 0.0
		sprite.scale = Vector2.ONE
	elif is_moving:
		sprite.rotation = 0.0
		sprite.position.y = -absf(sin(_t * 14.0)) * 3.0  # little hop
		sprite.scale = Vector2(1.0, 1.0 + sin(_t * 14.0) * 0.05)
	else:
		sprite.rotation = 0.0
		sprite.position.y = sin(_t * 3.0) * 0.6           # gentle idle sway
		sprite.scale = Vector2.ONE

## Hit the first tree overlapping the chop area in the facing direction.
func _chop() -> void:
	for a in chop_area.get_overlapping_areas():
		if a.is_in_group("tree") and a.has_method("chop"):
			a.chop(1)
			break
