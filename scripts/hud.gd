extends CanvasLayer

## Minimal HUD: shows the SHARED wood total (updated reactively from the world,
## which derives it from the synced GenosDB graph) and a Reset button that wipes
## the shared world for everyone.

@onready var label: Label = $Wood/Label
@onready var reset_button: Button = $Reset

func _ready() -> void:
	# The HUD is a child of the World node, which owns the shared world state.
	var world := get_parent()
	world.wood_changed.connect(_on_wood_changed)
	reset_button.pressed.connect(func() -> void:
		Sfx.play("reset")
		world.reset_world()
	)

func _on_wood_changed(total: int) -> void:
	label.text = "Wood: %d" % total
