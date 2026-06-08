extends CanvasLayer

## Minimal HUD: shows the SHARED wood total, updated reactively from the world
## (which derives it from the synced GenosDB graph — whoever chops, it goes up).

@onready var label: Label = $Wood/Label

func _ready() -> void:
	# The HUD is a child of the World node, which owns the shared wood total.
	get_parent().wood_changed.connect(_on_wood_changed)

func _on_wood_changed(total: int) -> void:
	label.text = "Wood: %d" % total
