class_name FarmerFrames
extends RefCounted

## Builds the farmer SpriteFrames at runtime (CC0 Ninja Adventure character).
## Walk/idle come from the 16x16 character sheet (column = direction
## down/up/left/right, row = frame). Chop comes from a baked 32x32 swing sheet
## (the katana composited over the character so it isn't clipped). Cached and
## shared by the local and remote farmers. See CREDITS.md.

const SHEET := "res://assets/farm/farmer.png"        ## 16x16 walk/idle
const CHOP_SHEET := "res://assets/farm/farmer_chop.png"  ## 32x32 baked sword swing
const DIR_COL := {"down": 0, "up": 1, "left": 2, "right": 3}

static var _cache: SpriteFrames

static func get_frames() -> SpriteFrames:
	if _cache:
		return _cache
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var tex := load(SHEET) as Texture2D
	var chop := load(CHOP_SHEET) as Texture2D
	for d in DIR_COL:
		var col: int = DIR_COL[d]
		_add(sf, "walk_" + d, tex, 16, col, [0, 1, 2, 3], 8.0, true)
		_add(sf, "idle_" + d, tex, 16, col, [0], 4.0, true)
		_add(sf, "chop_" + d, chop, 32, col, [0, 1, 2], 10.0, false)
	_cache = sf
	return sf

static func _add(sf: SpriteFrames, name: String, tex: Texture2D, size: int, col: int, rows: Array, fps: float, loop: bool) -> void:
	sf.add_animation(name)
	sf.set_animation_speed(name, fps)
	sf.set_animation_loop(name, loop)
	for r in rows:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * size, r * size, size, size)
		sf.add_frame(name, at)
