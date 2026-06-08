class_name SpeechBubble
extends Label

## A small fading speech bubble shown above a character (world space). Created in
## code by the local and remote farmers; call show_message() to display chat text.

const LIFETIME := 4.0
const FADE := 0.6
const HEIGHT := -44.0   ## bubble top, in pixels above the character origin (feet)

var _t := 0.0

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 8)
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_theme_constant_override("outline_size", 3)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.12, 0.78)
	sb.set_corner_radius_all(5)
	sb.set_content_margin_all(4)
	add_theme_stylebox_override("normal", sb)
	z_index = 200   ## always on top of characters / y-sort

func show_message(msg: String) -> void:
	text = msg
	visible = true
	modulate.a = 1.0
	_t = LIFETIME
	# Size to the text and center the bubble just above the character's head.
	var sz := get_minimum_size()
	size = sz
	position = Vector2(-sz.x * 0.5, HEIGHT)

func _process(delta: float) -> void:
	if not visible:
		return
	_t -= delta
	if _t <= FADE:
		modulate.a = maxf(0.0, _t / FADE)
	if _t <= 0.0:
		visible = false
