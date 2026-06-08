extends Node

## Global CC0 sound effects (Ninja Adventure pack). A small pool of one-shot
## players (so overlapping sounds don't cut each other), a looping wind ambient,
## and occasional birds. See CREDITS.md.

const SOUNDS := {
	"chop": "res://assets/farm/audio/chop.wav",
	"fall": "res://assets/farm/audio/fall.wav",
	"wood": "res://assets/farm/audio/wood.wav",
	"reset": "res://assets/farm/audio/reset.wav",
	"bird": "res://assets/farm/audio/bird.wav",
}
const POOL := 8

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0

func _ready() -> void:
	randomize()
	for k in SOUNDS:
		_streams[k] = load(SOUNDS[k])
	for _i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	# Quiet looping wind ambient.
	var wind = load("res://assets/farm/audio/wind.wav")
	if wind is AudioStreamWAV:
		wind.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var w := AudioStreamPlayer.new()
	w.stream = wind
	w.volume_db = -22.0
	w.autoplay = true
	add_child(w)
	_schedule_bird()

## Play a one-shot sound by key, with optional volume (dB) and pitch.
func play(name: String, volume_db := 0.0, pitch := 1.0) -> void:
	var s = _streams.get(name)
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func _schedule_bird() -> void:
	var t := get_tree().create_timer(randf_range(7.0, 18.0))
	t.timeout.connect(func() -> void:
		play("bird", -13.0, randf_range(0.9, 1.2))
		_schedule_bird()
	)
