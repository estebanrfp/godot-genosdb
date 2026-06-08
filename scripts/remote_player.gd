extends Node2D

## A non-controllable farmer driven by a peer's network state. Hidden until its
## first position arrives, plays the peer's broadcast animation (LPC 4-dir walk/
## chop), and lerps to the target position. Its name label has an outline so
## overlapping labels stay readable.

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $Label

var _target := Vector2.ZERO
var _init := false

func _ready() -> void:
	anim.sprite_frames = FarmerFrames.get_frames()
	visible = false
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)

func set_label(text: String) -> void:
	label.text = text

## Apply a state packet {x, y, a(nim)} from the owning peer.
func receive_state(data: Dictionary) -> void:
	_target = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	if not _init:
		global_position = _target   # snap on first packet
		_init = true
		visible = true
	anim.play(str(data.get("a", "idle_down")))

func _process(delta: float) -> void:
	if _init:
		global_position = global_position.lerp(_target, 1.0 - exp(-14.0 * delta))
