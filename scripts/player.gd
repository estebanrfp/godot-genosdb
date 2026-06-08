extends CharacterBody2D

## Top-down farmer (the local player). 4-directional LPC character (CC-BY-SA) that
## walks up/left/down/right and chops trees with an axe. Frames are built at
## runtime from the LPC sheets (see FarmerFrames). Movement broadcasts the current
## animation so peers see the same pose.

const SPEED := 82.0
const CHOP_TIME := 0.30
const BASE_OFFSET := Vector2(0, -8)

var dir_name := "down"
var chop_timer := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var chop_area: Area2D = $ChopArea

var _bubble: SpeechBubble

func _ready() -> void:
	add_to_group("player")
	anim.sprite_frames = FarmerFrames.get_frames()
	anim.play("idle_down")
	_bubble = SpeechBubble.new()
	add_child(_bubble)

## Show a chat message in a bubble above this player.
func say(msg: String) -> void:
	_bubble.show_message(msg)

func _physics_process(delta: float) -> void:
	# Ignore movement/chop keys while typing in the chat box.
	var typing := get_viewport().gui_get_focus_owner() is LineEdit
	var input := Vector2.ZERO if typing else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * SPEED
	if input != Vector2.ZERO:
		if absf(input.x) > absf(input.y):
			dir_name = "right" if input.x > 0.0 else "left"
		else:
			dir_name = "down" if input.y > 0.0 else "up"
		chop_area.position = _dir_vec() * 12.0
	move_and_slide()
	# Keep the farmer inside the farm bounds (matches the ground + camera limits).
	global_position.x = clampf(global_position.x, 12.0, 756.0)
	global_position.y = clampf(global_position.y, 24.0, 470.0)

	if chop_timer > 0.0:
		chop_timer -= delta
	if not typing and Input.is_action_just_pressed("chop") and chop_timer <= 0.0:
		chop_timer = CHOP_TIME
		_chop()

	_update_anim(input)
	# Chop is a single attack pose, so add a quick lunge toward the tree for punch.
	if chop_timer > 0.0:
		var p := 1.0 - chop_timer / CHOP_TIME
		anim.offset = BASE_OFFSET + _dir_vec() * sin(p * PI) * 3.0
	else:
		anim.offset = BASE_OFFSET

func _dir_vec() -> Vector2:
	match dir_name:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
		_: return Vector2.RIGHT

## Pick the clip for the current state and facing.
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
