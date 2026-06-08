extends CanvasLayer

## Minimal HUD: shows the SHARED wood total (updated reactively from the world,
## which derives it from the synced GenosDB graph) and a Reset button that wipes
## the shared world for everyone.

@onready var label: Label = $Wood/Label
@onready var reset_button: Button = $Reset
@onready var chat_input: LineEdit = $Chat

func _ready() -> void:
	# The HUD is a child of the World node, which owns the shared world state.
	var world := get_parent()
	world.wood_changed.connect(_on_wood_changed)
	reset_button.pressed.connect(func() -> void:
		Sfx.play("reset")
		world.reset_world()
	)
	# Chat: Enter sends the message (P2P) and releases focus so you can move again.
	chat_input.text_submitted.connect(func(text: String) -> void:
		world.send_chat(text)
		chat_input.clear()
		chat_input.release_focus()
	)

func _on_wood_changed(total: int) -> void:
	label.text = "Wood: %d" % total
