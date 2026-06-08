extends Node

## Global CC0 audio (Ninja Adventure pack). One-shot SFX pool + looping background
## music + quiet wind + occasional birds. Ambient starts on the FIRST user input
## (browsers block autoplay until a gesture, so we can't start it on load). See
## CREDITS.md.

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
var _music: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _ambient_started := false

func _ready() -> void:
	randomize()
	for k in SOUNDS:
		_streams[k] = load(SOUNDS[k])
	for _i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	# Background music (loops).
	var music = load("res://assets/farm/audio/music.ogg")
	if music is AudioStreamOggVorbis:
		music.loop = true
	_music = AudioStreamPlayer.new()
	_music.stream = music
	_music.volume_db = -12.0
	add_child(_music)
	# Quiet wind ambient (loops).
	var wind = load("res://assets/farm/audio/wind.wav")
	if wind is AudioStreamWAV:
		wind.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_wind = AudioStreamPlayer.new()
	_wind.stream = wind
	_wind.volume_db = -18.0
	add_child(_wind)

## Web blocks audio until a user gesture, so kick off the ambient on first input.
func _input(event: InputEvent) -> void:
	if _ambient_started:
		return
	if (event is InputEventKey and event.pressed) \
			or (event is InputEventMouseButton and event.pressed) \
			or event is InputEventScreenTouch:
		_ambient_started = true
		_music.play()
		_wind.play()
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
	var t := get_tree().create_timer(randf_range(8.0, 18.0))
	t.timeout.connect(func() -> void:
		play("bird", -14.0, randf_range(0.9, 1.2))
		_schedule_bird()
	)
