extends Node
## Tiny SFX bank for the opening flow (procedural TEMPORARY sounds generated
## by tools/make_flow_sfx.py). Respects the game's sound toggle via `enabled`.

const STREAMS := {
	"rotor": preload("res://assets/reclaim/audio/rotor_loop.wav"),
	"thump": preload("res://assets/reclaim/audio/land_thump.wav"),
	"click": preload("res://assets/reclaim/audio/ui_click.wav"),
	"confirm": preload("res://assets/reclaim/audio/ui_confirm.wav"),
	"build": preload("res://assets/reclaim/audio/hq_build.wav"),
	"wind": preload("res://assets/reclaim/audio/wind.wav"),
	"radio": preload("res://assets/reclaim/audio/radio.wav"),
}

var enabled := true
var _voices: Array[AudioStreamPlayer] = []
var _rotor: AudioStreamPlayer
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(5):
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)
	_rotor = AudioStreamPlayer.new()
	_rotor.bus = "SFX"
	var loop: AudioStreamWAV = (STREAMS.rotor as AudioStreamWAV).duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = int(loop.get_length() * loop.mix_rate)
	_rotor.stream = loop
	_rotor.volume_db = -60.0
	add_child(_rotor)


func play(id: String, volume_db := -6.0, pitch := 1.0) -> void:
	if not enabled or not STREAMS.has(id):
		return
	var p := _voices[_next]
	_next = (_next + 1) % _voices.size()
	p.stream = STREAMS[id]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


## level 0..1 fades the looping rotor; 0 stops it.
func set_rotor(level: float, pitch := 1.0) -> void:
	if not enabled or level <= 0.001:
		if _rotor.playing:
			_rotor.stop()
		return
	if not _rotor.playing:
		_rotor.play()
	_rotor.volume_db = linear_to_db(clampf(level, 0.0, 1.0)) - 4.0
	_rotor.pitch_scale = pitch


func stop_all() -> void:
	_rotor.stop()
	for p in _voices:
		p.stop()


func _exit_tree() -> void:
	if is_instance_valid(_rotor):
		_rotor.stop()
		_rotor.stream = null
	for voice in _voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
