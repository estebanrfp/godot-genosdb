class_name FarmerFrames
extends RefCounted

## Builds the LPC farmer SpriteFrames at runtime from two 64x64 sheets (walk:
## 9 frames x 4 dirs, chop: 6 frames x 4 dirs; row order = up, left, down, right).
## Cached and shared by the local and remote farmers. CC-BY-SA — see CREDITS.md.

const WALK := "res://assets/farm/farmer_walk.png"
const CHOP := "res://assets/farm/farmer_chop.png"
const DIRS := ["up", "left", "down", "right"]

static var _cache: SpriteFrames

static func get_frames() -> SpriteFrames:
	if _cache:
		return _cache
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var walk := load(WALK) as Texture2D
	var chop := load(CHOP) as Texture2D
	for r in DIRS.size():
		var d: String = DIRS[r]
		_add(sf, "walk_" + d, walk, r, 9, 10.0, true)
		_add(sf, "chop_" + d, chop, r, 6, 14.0, false)
		_add(sf, "idle_" + d, walk, r, 1, 6.0, true)   # standing pose = walk frame 0
	_cache = sf
	return sf

static func _add(sf: SpriteFrames, name: String, tex: Texture2D, row: int, count: int, fps: float, loop: bool) -> void:
	sf.add_animation(name)
	sf.set_animation_speed(name, fps)
	sf.set_animation_loop(name, loop)
	for c in count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(c * 64, row * 64, 64, 64)
		sf.add_frame(name, at)
