class_name FarmerFrames
extends RefCounted

## Builds the farmer SpriteFrames at runtime from the Ninja Adventure character
## sheet (CC0). Layout: 16x16 frames, COLUMN = direction (down/up/left/right),
## ROW = animation frame (row 0 idle, rows 0-3 walk, row 4 attack). Cached and
## shared by the local and remote farmers. See CREDITS.md.

const SHEET := "res://assets/farm/farmer.png"
const DIR_COL := {"down": 0, "up": 1, "left": 2, "right": 3}

static var _cache: SpriteFrames

static func get_frames() -> SpriteFrames:
	if _cache:
		return _cache
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var tex := load(SHEET) as Texture2D
	for d in DIR_COL:
		var col: int = DIR_COL[d]
		_add(sf, "walk_" + d, tex, col, [0, 1, 2, 3], 8.0, true)
		_add(sf, "idle_" + d, tex, col, [0], 4.0, true)
		_add(sf, "chop_" + d, tex, col, [4], 8.0, false)   # attack pose
	_cache = sf
	return sf

static func _add(sf: SpriteFrames, name: String, tex: Texture2D, col: int, rows: Array, fps: float, loop: bool) -> void:
	sf.add_animation(name)
	sf.set_animation_speed(name, fps)
	sf.set_animation_loop(name, loop)
	for r in rows:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * 16, r * 16, 16, 16)
		sf.add_frame(name, at)
