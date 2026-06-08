extends Node2D

## A non-controllable farmer driven by a peer's network state. Hidden until its
## first position arrives, shows the peer's broadcast character variant, and bobs/
## hops procedurally. Its name label has an outline so overlapping labels stay
## readable.

const CHARS := [
	"res://assets/farm/farmer_red.png",
	"res://assets/farm/farmer_blonde.png",
	"res://assets/farm/farmer_green.png",
]

@onready var sprite: Sprite2D = $Sprite
@onready var label: Label = $Label

var _target := Vector2.ZERO
var _init := false
var _moving := false
var _flip := false
var _char := -1
var _t := 0.0

func _ready() -> void:
	visible = false
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)

func set_label(text: String) -> void:
	label.text = text

## Apply a state packet {x, y, f(lip), ch(ar), mv(moving)} from the owning peer.
func receive_state(data: Dictionary) -> void:
	_target = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	_flip = bool(data.get("f", false))
	_moving = bool(data.get("mv", false))
	var ci := int(data.get("ch", 0))
	if ci != _char:
		_char = ci
		sprite.texture = load(CHARS[ci % CHARS.size()])
	if not _init:
		global_position = _target   # snap on first packet
		_init = true
		visible = true

func _process(delta: float) -> void:
	if not _init:
		return
	global_position = global_position.lerp(_target, 1.0 - exp(-14.0 * delta))
	_t += delta
	sprite.flip_h = _flip
	if _moving:
		sprite.position.y = -absf(sin(_t * 14.0)) * 3.0
		sprite.scale = Vector2(1.0, 1.0 + sin(_t * 14.0) * 0.05)
	else:
		sprite.position.y = sin(_t * 3.0) * 0.6
		sprite.scale = Vector2.ONE
