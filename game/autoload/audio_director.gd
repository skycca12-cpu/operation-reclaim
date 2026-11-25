extends Node

const BrowserBgmPlayer = preload("res://scripts/manus/browser_bgm_player.gd")

const MAX_SFX_VOICES := 8
const MAX_UI_VOICES := 2
const SAW_SILENT_DB := -48.0
const SAW_RUNNING_DB := -2.2
# Optional resource paths. Empty means intentionally silent; add project audio
# here or call register_cue() after importing an AudioStream resource.
# Cue trims balance active loudness before the shared effects slider.
# The cut overlay is quieter so it can play over the running motor.
const CUES := {
	"player.shotgun": {"path": "res://assets/reclaim/audio/shotgun.ogg", "bus": "SFX", "gain_db": -0.7},
	"player.m4": {"path": "res://assets/reclaim/audio/rifle_m4.ogg", "bus": "SFX", "gain_db": -0.3},
	"player.chainsaw_rev": {"path": "res://assets/reclaim/audio/chainsaw_rev.ogg", "bus": "SFX", "gain_db": -3.3},
	"player.chainsaw": {"path": "res://assets/reclaim/audio/chainsaw_cut.ogg", "bus": "SFX", "gain_db": -4.5},
	"enemy.low": {"path": "res://assets/reclaim/audio/zombie_growl_low.ogg", "bus": "SFX", "gain_db": 10.7},
	"enemy.high": {"path": "res://assets/reclaim/audio/zombie_growl_high.ogg", "bus": "SFX", "gain_db": 19.7},
	"enemy.elderly": {"path": "res://assets/reclaim/audio/zombie_growl_elderly.ogg", "bus": "SFX", "gain_db": 13.5},
	"enemy.boss_arrival": {"path": "res://assets/reclaim/audio/boss_arrival.ogg", "bus": "SFX", "gain_db": 4.7},
	"enemy.ambient": {"path": "res://assets/reclaim/audio/zombie_ambient.wav", "bus": "SFX", "gain_db": 5.7},
	"enemy.burrow_rumble": {"path": "res://assets/reclaim/audio/burrow_rumble.ogg", "bus": "SFX", "gain_db": -4.0},
	"enemy.burrow_break": {"path": "res://assets/reclaim/audio/burrow_break.ogg", "bus": "SFX", "gain_db": -4.0},
	"enemy.attack": {"path": "res://assets/reclaim/audio/combat_zombie.wav", "bus": "SFX", "gain_db": -0.9},
	"music.title": {"path": "", "kind": "music"},
	"music.gameplay": {"path": "res://assets/reclaim/audio/combat_music.ogg", "kind": "music"},
	"ui.confirm": {"path": "", "bus": "UI"},
	"ui.cancel": {"path": "", "bus": "UI"},
	"player.action": {"path": "res://assets/reclaim/audio/combat_shot.wav", "bus": "SFX", "gain_db": -2.2},
	"player.shield_impact": {"path": "res://assets/reclaim/audio/shield_impact.ogg", "bus": "SFX"},
	"enemy.impact": {"path": "res://assets/reclaim/audio/combat_hit.wav", "bus": "SFX", "gain_db": 1.3},
	"score.reward": {"path": "", "bus": "SFX"},
	"game.pause": {"path": "", "bus": "UI"},
	"game.victory": {"path": "", "bus": "SFX"},
	"game.defeat": {"path": "", "bus": "SFX"},
}

var _streams: Dictionary = {}
var _music_players: Array[BrowserBgmPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _music_index := 0
var _music_cue := ""
var _unlocked := false
var _headless := false
var _paused := false
var _game_sound_enabled := true
var _game_music_gain := 1.0
var _game_effects_gain := 1.0
var _music_tween: Tween
var _shield_windup: AudioStreamPlayer
var _saw_motor: AudioStreamPlayer
var _saw_active := false
var _saw_pitch := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless = DisplayServer.get_name() == "headless"
	_ensure_buses()
	for index: int in 2:
		var player := BrowserBgmPlayer.new()
		player.name = "Music%d" % index
		player.bus = "Music"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.force_loop = true
		add_child(player)
		player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		player.finished.connect(_on_music_finished.bind(player))
		_music_players.append(player)
	for index: int in MAX_SFX_VOICES:
		_sfx_players.append(_make_player("Sfx%d" % index, "SFX"))
	for index: int in MAX_UI_VOICES:
		_ui_players.append(_make_player("Ui%d" % index, "UI"))
	_shield_windup = _make_player("ShieldWindup", "SFX")
	_shield_windup.stream = ResourceLoader.load("res://assets/reclaim/audio/shield_windup.ogg") as AudioStream
	_saw_motor = _make_player("ChainsawMotor", "SFX")
	var motor := ResourceLoader.load("res://assets/reclaim/audio/chainsaw_motor.ogg") as AudioStreamOggVorbis
	motor.loop = true
	_saw_motor.stream = motor
	_saw_motor.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	_saw_motor.volume_db = SAW_SILENT_DB
	_load_streams()
	TuningStore.value_changed.connect(_on_tuning_changed)
	_apply_bus_settings()


func play_shield_windup() -> void:
	if _game_sound_enabled and _unlocked and not _paused and not _headless:
		_shield_windup.play()


func stop_shield_windup() -> void:
	_shield_windup.stop()


func set_chainsaw_motor(active: bool, overheated := false) -> void:
	_saw_active = active
	_saw_pitch = 0.92 if overheated else 1.0


func _process(delta: float) -> void:
	var running := _saw_active and _game_sound_enabled and not _paused and _unlocked and not _headless
	if not _saw_motor.playing:
		if not running:
			return
		_saw_motor.volume_db = SAW_SILENT_DB
		_saw_motor.pitch_scale = _saw_pitch
		_saw_motor.play()
	var target := SAW_RUNNING_DB if running else SAW_SILENT_DB
	_saw_motor.volume_db = move_toward(_saw_motor.volume_db, target, delta * (700.0 if running else 260.0))
	_saw_motor.pitch_scale = move_toward(_saw_motor.pitch_scale, _saw_pitch, delta * 0.5)
	if not running and _saw_motor.volume_db <= SAW_SILENT_DB:
		_saw_motor.stop()


func _exit_tree() -> void:
	release_streams()


func release_streams() -> void:
	stop_shield_windup()
	_saw_active = false
	_saw_motor.stop()
	stop_music(0.0)
	for player: AudioStreamPlayer in _sfx_players + _ui_players:
		player.stop()
		player.stream = null
	for stream: AudioStream in _streams.values():
		BrowserBgmPlayer.release_cached_stream(stream)
	_streams.clear()


func register_cue(cue_id: String, resource_path: String) -> bool:
	if not CUES.has(cue_id):
		return false
	# Avoid load() on empty/missing paths. Missing audio is expected.
	if resource_path.is_empty() or not ResourceLoader.exists(resource_path):
		unregister_cue(cue_id)
		return false
	var stream := ResourceLoader.load(resource_path) as AudioStream
	return register_stream(cue_id, stream)


func register_stream(cue_id: String, stream: AudioStream) -> bool:
	if not CUES.has(cue_id):
		return false
	unregister_cue(cue_id)
	if stream == null:
		return false
	_streams[cue_id] = stream
	return true


func unregister_cue(cue_id: String) -> void:
	if cue_id == _music_cue:
		stop_music(0.0)
	var old_stream: AudioStream = _streams.get(cue_id)
	if old_stream != null:
		for players in [_music_players, _sfx_players, _ui_players]:
			for player in players:
				if player.stream == old_stream:
					player.stop()
					player.stream = null
		BrowserBgmPlayer.release_cached_stream(old_stream)
	_streams.erase(cue_id)


func unlock_audio() -> void:
	# Called from a real button/input gesture; no dummy cue is required.
	_unlocked = true


func play_music(cue_id: String, crossfade_seconds: float = 0.35) -> bool:
	var stream: AudioStream = _streams.get(cue_id)
	if stream == null or CUES.get(cue_id, {}).get("kind", "") != "music":
		stop_music(0.0)
		return false
	if not _unlocked and not _headless:
		return false
	var current: BrowserBgmPlayer = _music_players[_music_index]
	if current.stream == stream and (current.playing or _headless):
		_music_cue = cue_id
		return true
	_kill_music_tween()
	var old_player := current
	_music_index = 1 - _music_index
	var next_player: BrowserBgmPlayer = _music_players[_music_index]
	next_player.stop()
	next_player.stream = stream
	next_player.volume_db = -40.0 if old_player.playing else 0.0
	_music_cue = cue_id
	if _headless:
		old_player.stop()
		old_player.stream = null
		return true
	next_player.play()
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(next_player, "volume_db", 0.0, maxf(0.0, crossfade_seconds))
	if old_player.playing:
		_music_tween.tween_property(old_player, "volume_db", -40.0, maxf(0.0, crossfade_seconds))
		_music_tween.chain().tween_callback(func() -> void:
			old_player.stop()
			old_player.stream = null
		)
	return true


func stop_music(fade_seconds: float = 0.25) -> void:
	_music_cue = ""
	_kill_music_tween()
	if fade_seconds <= 0.0 or _headless:
		for player: BrowserBgmPlayer in _music_players:
			player.stop()
			player.stream = null
		return
	_music_tween = create_tween().set_parallel(true)
	for player: BrowserBgmPlayer in _music_players:
		_music_tween.tween_property(player, "volume_db", -40.0, fade_seconds)
	_music_tween.chain().tween_callback(func() -> void:
		for player: BrowserBgmPlayer in _music_players:
			player.stop()
			player.stream = null
	)


func _kill_music_tween() -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = null


func play_cue(cue_id: String, pitch_scale: float = 1.0) -> bool:
	var stream: AudioStream = _streams.get(cue_id)
	if stream == null or CUES.get(cue_id, {}).get("kind", "") == "music":
		return false
	if not _unlocked and not _headless:
		return false
	if _headless:
		return true
	var cue: Dictionary = CUES[cue_id]
	var players := _ui_players if str(cue.get("bus", "SFX")) == "UI" else _sfx_players
	var player := _claim_voice(players)
	player.stream = stream
	player.volume_db = float(cue.get("gain_db", 0.0))
	player.pitch_scale = clampf(pitch_scale, 0.75, 1.35)
	player.play()
	return true


func register_button(button: Button, cancel_cue: bool = false) -> void:
	if button == null or button.has_meta("audio_registered"):
		return
	button.set_meta("audio_registered", true)
	button.pressed.connect(func() -> void:
		unlock_audio()
		play_cue("ui.cancel" if cancel_cue else "ui.confirm")
	)


func set_game_paused(paused: bool) -> void:
	if _paused == paused:
		return
	_paused = paused
	_apply_bus_settings()
	if paused:
		play_cue("game.pause")


func get_cue_ids() -> Array:
	return CUES.keys()


func get_voice_capacity() -> Dictionary:
	return {"music": _music_players.size(), "sfx": _sfx_players.size(), "ui": _ui_players.size()}


func _make_player(player_name: String, bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player


func _claim_voice(players: Array) -> AudioStreamPlayer:
	for value: Variant in players:
		var player: AudioStreamPlayer = value
		if not player.playing:
			return player
	var recycled: AudioStreamPlayer = players[0]
	recycled.stop()
	return recycled


func _load_streams() -> void:
	for cue_id: String in CUES:
		register_cue(cue_id, str(CUES[cue_id].path))


func _ensure_buses() -> void:
	for bus_name: String in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func set_game_audio_mix(music_gain: float, effects_gain: float, enabled: bool) -> void:
	_game_music_gain = clampf(music_gain, 0.0, 1.0)
	_game_effects_gain = clampf(effects_gain, 0.0, 1.0)
	_game_sound_enabled = enabled
	_apply_bus_settings()


func _apply_bus_settings() -> void:
	var mappings := {
		"Master": "audio.master.volume_db",
		"Music": "audio.music.volume_db",
		"SFX": "audio.sfx.volume_db",
		"UI": "audio.ui.volume_db",
	}
	for bus_name: String in mappings:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			var duck := 8.0 if bus_name == "Music" and _paused else 0.0
			var gain := _game_music_gain if bus_name == "Music" else _game_effects_gain
			var adjustment := 0.0 if bus_name == "Master" else linear_to_db(maxf(0.001, gain))
			AudioServer.set_bus_volume_db(index, float(TuningStore.get_value(mappings[bus_name], 0.0)) + adjustment - duck)
			if bus_name != "Master":
				AudioServer.set_bus_mute(index, not _game_sound_enabled or gain == 0.0)
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, bool(TuningStore.get_value("audio.master.muted", false)))


func _on_tuning_changed(id: String, _requested: Variant, _active: Variant) -> void:
	if id.begins_with("audio."):
		_apply_bus_settings()


func _on_music_finished(player: BrowserBgmPlayer) -> void:
	if player == _music_players[_music_index] and not _music_cue.is_empty() and player.stream != null:
		player.play()
