extends CanvasLayer

## Minimal HUD: shows the wood count, updated reactively from the player.

@onready var label: Label = $Wood/Label

func _ready() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		players[0].wood_changed.connect(_on_wood_changed)

func _on_wood_changed(amount: int) -> void:
	label.text = "Madera: %d" % amount
