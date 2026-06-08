extends Node2D

## A non-controllable farmer driven by a peer's network state. Smoothly interpolates
## to the last received position and mirrors the peer's animation.

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $Label

var _target := Vector2.ZERO
var _init := false

func set_label(text: String) -> void:
	label.text = text

## Apply a state packet {x, y, a(nim), f(lip)} from the owning peer.
func receive_state(data: Dictionary) -> void:
	_target = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	if not _init:
		global_position = _target   # snap on first packet
		_init = true
	anim.play(str(data.get("a", "idle_down")))
	anim.flip_h = bool(data.get("f", false))

func _process(delta: float) -> void:
	if _init:
		global_position = global_position.lerp(_target, 1.0 - exp(-14.0 * delta))
