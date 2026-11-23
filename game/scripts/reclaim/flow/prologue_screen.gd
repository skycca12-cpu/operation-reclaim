extends Control
## Jeju prologue – cheap "still + camera move" cut scene (no video, no 3D).
##  Shot 1  해상 접근   : side-view parallax dusk coast, helicopter flies in.
##  Shot 2  도심 상공   : real in-game Jeju map seen from above, camera descends
##                        toward the flare-marked landing zone.
##  Shot 3  강하 준비   : selected operator (approved portrait) + radio line.
## Fades + subtitles, skippable with the button / Esc / Space / Enter.

signal finished

const FlowUI = preload("res://scripts/reclaim/flow/flow_ui.gd")
const HeliArt = preload("res://scripts/reclaim/flow/heli_art.gd")
const JejuMapArt = preload("res://scripts/reclaim/jeju_map_art.gd")
const Data = preload("res://scripts/reclaim/data.gd")

const SHOTS := [
	{"len": 6.5, "title": "제주 해상 · 20:41", "line": "수도 탈환 작전 제1단계. 점령된 제주시 해안으로 진입한다."},
	{"len": 5.5, "title": "제주시 점령구역 상공", "line": "도심 중앙 광장, 붉은 신호탄 확인. 착륙 지점으로 하강한다."},
	{"len": 4.5, "title": "강하 준비", "line": ""},
]
const HERO_LINES := [
	"강태준: 방패 들고 먼저 내린다. 텐트 칠 시간은 내가 번다.",
	"윤시혁: 사거리 확보 완료. 착륙하면 바로 사격 지원 들어간다.",
	"서하린: 드론 연결 완료. 착륙 지점 주변 안전 확인할게요.",
	"한유진: 텐트 키트랑 공구 챙겼어! 내리자마자 기지 세운다!",
]

var hero_index := 0
var landing_world := Vector2.ZERO
var sfx: Node = null
var _t := 0.0
var _shot := 0
var _shot_t := 0.0
var _running := false
var _title: Label
var _line: Label
var _skip: Button
var _stars: Array[Vector2] = []
var _city: Array[Rect2] = []
var _fires: Array[Vector2] = []
var _smoke_seed: Array[float] = []
var _radio_played := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var rng := RandomNumberGenerator.new()
	rng.seed = 2031
	for i in range(70): _stars.append(Vector2(rng.randf(), rng.randf() * 0.42))
	var x := 0.0
	while x < 2.4:
		var w := rng.randf_range(0.025, 0.07)
		_city.append(Rect2(x, 0, w, rng.randf_range(0.05, 0.19)))
		if rng.randf() < 0.28: _fires.append(Vector2(x + w * 0.5, rng.randf_range(0.0, 1.0)))
		x += w + rng.randf_range(0.0, 0.012)
	for i in range(9): _smoke_seed.append(rng.randf())
	_title = FlowUI.make_label("", 16, FlowUI.GOLD)
	add_child(_title)
	_line = FlowUI.make_label("", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_line)
	_skip = FlowUI.make_plate_button("건너뛰기  ▶▶")
	_skip.add_theme_font_size_override("font_size", 16)
	_skip.pressed.connect(skip)
	add_child(_skip)
	resized.connect(_layout)
	_layout()


func start(hero: int, lz_world: Vector2) -> void:
	hero_index = hero
	landing_world = lz_world
	_t = 0.0
	_shot = 0
	_shot_t = 0.0
	_running = true
	_radio_played = false
	_apply_text()
	if sfx: sfx.play("wind", -10.0)


func skip() -> void:
	if not _running:
		return
	_running = false
	if sfx: sfx.set_rotor(0.0)
	finished.emit()


func current_shot() -> int:
	return _shot


func _layout() -> void:
	var bar := size.y * 0.1
	_title.position = Vector2(40, bar + 14)
	_title.size = Vector2(600, 24)
	_line.position = Vector2(size.x * 0.1, size.y - bar - 64)
	_line.size = Vector2(size.x * 0.8, 56)
	_skip.position = Vector2(size.x - 200, 14)
	_skip.size = Vector2(176, 40)


func _apply_text() -> void:
	_title.text = SHOTS[_shot].title
	_line.text = SHOTS[_shot].line if _shot < 2 else HERO_LINES[hero_index]


func _process(delta: float) -> void:
	if not visible or not _running:
		return
	_t += delta
	_shot_t += delta
	if _shot_t >= SHOTS[_shot].len:
		_shot_t = 0.0
		_shot += 1
		if _shot >= SHOTS.size():
			_running = false
			if sfx: sfx.set_rotor(0.0)
			finished.emit()
			return
		_apply_text()
	if sfx:
		var level: float = [0.55, 0.85, 0.35][_shot]
		sfx.set_rotor(level)
		if _shot == 1 and not _radio_played and _shot_t > 0.4:
			_radio_played = true
			sfx.play("radio", -8.0)
	# subtitles type in over the first second of a shot (cheap typewriter)
	var full: String = SHOTS[_shot].line if _shot < 2 else HERO_LINES[hero_index]
	_line.visible_characters = int(clampf(_shot_t / 1.2, 0.0, 1.0) * full.length())
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER]:
			skip()
			accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and _running and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			skip()
			get_viewport().set_input_as_handled()


func _draw() -> void:
	match _shot:
		0: _draw_sea_approach(_shot_t / SHOTS[0].len)
		1: _draw_city_overhead(_shot_t / SHOTS[1].len)
		_: _draw_briefing(_shot_t / SHOTS[2].len)
	# letterbox + fades
	var bar := size.y * 0.1
	draw_rect(Rect2(0, 0, size.x, bar), Color.BLACK)
	draw_rect(Rect2(0, size.y - bar, size.x, bar), Color.BLACK)
	var len: float = SHOTS[_shot].len
	var fade := clampf(minf(_shot_t / 0.5, (len - _shot_t) / 0.5), 0.0, 1.0)
	if fade < 1.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 1.0 - fade))


# ---------------------------------------------------------------- shot 1
func _draw_sea_approach(p: float) -> void:
	var w := size.x
	var h := size.y
	var horizon := h * 0.6
	# stepped sky gradient (pixel bands)
	var top := Color("#1a0d1f")
	var mid := Color("#7a1a2c")
	var low := Color("#ef5a34")
	for i in range(24):
		var k := float(i) / 23.0
		var col := top.lerp(mid, k * 1.6) if k < 0.62 else mid.lerp(low, (k - 0.62) / 0.38)
		draw_rect(Rect2(0, horizon * k, w, horizon / 23.0 + 1), col)
	for s in _stars:
		draw_rect(Rect2(s.x * w, s.y * h, 2, 2), Color(1, 0.9, 0.9, 0.35))
	var pan := p * w * 0.35
	# red sun
	var sun := Vector2(w * 0.3 - pan * 0.1, horizon - h * 0.2)
	draw_circle(sun, h * 0.11, Color("#ff5a3c", 0.25))
	draw_circle(sun, h * 0.075, Color("#ff6b45"))
	# Hallasan silhouette (far layer)
	var far := PackedVector2Array([Vector2(-20, horizon)])
	for i in range(41):
		var fx := float(i) / 40.0
		var hy := horizon - h * (0.05 + 0.17 * exp(-pow((fx - 0.62) * 3.2, 2.0)))
		far.append(Vector2(fx * (w + 40) - 20 - pan * 0.15, hy))
	far.append(Vector2(w + 20, horizon))
	draw_colored_polygon(far, Color("#2c1022"))
	# ruined coastal city (mid layer, parallax)
	for r in _city:
		var x := r.position.x * w * 0.9 + w * 0.35 - pan * 0.6
		if x > w or x + r.size.x * w < 0: continue
		var bh := r.size.y * h
		var rect := Rect2(x, horizon - bh, r.size.x * w * 0.9, bh)
		draw_rect(rect, Color("#170a14"))
		# broken roof notch
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.6, rect.position.y - 3, rect.size.x * 0.3, 4), Color("#170a14"))
		var wy := rect.position.y + 6
		while wy < horizon - 8:
			if int(wy + x) % 3 == 0:
				draw_rect(Rect2(rect.position.x + 4, wy, 3, 3), Color("#ff9a4a", 0.5))
			wy += 11
	for f in _fires:
		var fx := f.x * w * 0.9 + w * 0.35 - pan * 0.6
		var flick := 0.6 + 0.4 * float(int(_t * 6.0 + f.y * 10.0) % 2)
		draw_circle(Vector2(fx, horizon - 4), 5.0 * flick, Color("#ffb347", 0.9))
		for k in range(4):
			var rise := fmod(_t * 18.0 + k * 22.0 + f.y * 40.0, 90.0)
			draw_circle(Vector2(fx + sin(_t + k) * 6.0, horizon - 10 - rise), 6.0 + rise * 0.12, Color(0.12, 0.07, 0.09, 0.45 * (1.0 - rise / 90.0)))
	# sea with sun streaks
	draw_rect(Rect2(0, horizon, w, h - horizon), Color("#12070f"))
	for i in range(14):
		var y := horizon + 6 + i * (h - horizon) / 14.0
		var off := fmod(_t * 20.0 + i * 37.0, 60.0)
		draw_rect(Rect2(sun.x - 60 + off - i * 4, y, 50 + i * 6, 2), Color("#ff6b45", 0.35 - i * 0.02))
	# black basalt shoreline in front
	var shore := PackedVector2Array([Vector2(w * 0.55 - pan * 1.1, h), Vector2(w * 0.62 - pan * 1.1, horizon + h * 0.12), Vector2(w * 0.9 - pan * 1.1, horizon + h * 0.08), Vector2(w * 1.6 - pan * 1.1, horizon + h * 0.1), Vector2(w * 1.6, h)])
	draw_colored_polygon(shore, Color("#0a0509"))
	# helicopter flies in from the left, bobbing
	var hx := lerpf(-w * 0.15, w * 0.46, ease(p, 0.6))
	var hy := h * 0.36 + sin(_t * 2.2) * 6.0
	HeliArt.draw_side(self, Vector2(hx, hy), 1.25, int(_t * 12.0) % 4, 0.06)


# ---------------------------------------------------------------- shot 2
func _draw_city_overhead(p: float) -> void:
	var z := lerpf(0.42, 0.78, ease(p, -1.8))
	var start := landing_world + Vector2(-900, 620)
	var cam := start.lerp(landing_world, ease(p, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(z, z))
	JejuMapArt.draw(self, cam, size / z)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# dusk grade
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.05, 0.12, 0.28))
	# flare at landing zone (2-frame flicker)
	var lz := (landing_world - cam) * z + size * 0.5
	var flick := 1.0 if int(_t * 8.0) % 2 == 0 else 0.7
	draw_circle(lz, 60.0 * z * flick, Color(1, 0.15, 0.1, 0.18))
	draw_circle(lz, 7.0, Color(1, 0.3, 0.2, flick))
	draw_arc(lz, 34.0 * z + 8.0 * sin(_t * 4.0), 0, TAU, 32, Color(1, 0.3, 0.25, 0.7), 2.0)
	# clouds sliding past (altitude cue)
	for i in range(_smoke_seed.size()):
		var sx := fmod(_smoke_seed[i] * size.x * 1.6 - p * size.x * 1.3 + size.x * 0.4, size.x * 1.6) - size.x * 0.3
		var sy := size.y * (0.1 + 0.8 * fmod(_smoke_seed[i] * 7.3, 1.0))
		draw_circle(Vector2(sx, sy), 90.0 + 40.0 * _smoke_seed[i], Color(0.75, 0.6, 0.65, 0.10 * (1.0 - p)))
	# our helicopter (top-down) above the camera centre
	var heli := size * 0.5 + Vector2(-60, 40) * (1.0 - p)
	HeliArt.draw_top(self, heli, 0.9 + 0.3 * (1.0 - p), -0.6 + 0.6 * p, _t * 18.0, 1.4 - 0.6 * p)
	# HUD frame
	var c := Color(1, 0.35, 0.3, 0.8)
	draw_rect(Rect2(lz - Vector2(26, 26), Vector2(52, 52)), c, false, 2.0)
	draw_string(ThemeDB.fallback_font, lz + Vector2(32, -14), "LZ  ALPHA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, c)
	draw_string(ThemeDB.fallback_font, Vector2(40, size.y * 0.1 + 64), "고도 %d m" % int(lerpf(420, 160, p)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.8, 0.7, 0.9))


# ---------------------------------------------------------------- shot 3
func _draw_briefing(p: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0d070b"))
	# cabin light stripes (2-frame red/dark alarm)
	var alarm := 0.22 if int(_t * 2.0) % 2 == 0 else 0.1
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.8, 0.05, 0.08, alarm))
	for i in range(9):
		draw_rect(Rect2(i * size.x / 8.0 - fmod(_t * 60.0, size.x / 8.0), size.y * 0.18, 6, size.y * 0.64), Color(0, 0, 0, 0.35))
	# open side door with the city glow
	var door := Rect2(size.x * 0.58, size.y * 0.18, size.x * 0.34, size.y * 0.64)
	draw_rect(door, Color("#3a0f19"))
	draw_rect(Rect2(door.position.x, door.end.y - 70, door.size.x, 70), Color("#1c0a10"))
	for k in range(6):
		draw_rect(Rect2(door.position.x + 20 + k * 52, door.end.y - 70 - 20 - (k * 37) % 50, 30, 20 + (k * 37) % 50), Color("#12060c"))
	draw_rect(door, Color("#7b7f6a"), false, 6.0)
	# selected operator (approved full-body art) slides in
	var tex: Texture2D = FlowUI.PORTRAITS[hero_index]
	var th := size.y * 0.78
	var tw := th * float(tex.get_width()) / float(tex.get_height())
	var x := lerpf(-tw, size.x * 0.12, ease(minf(1.0, p * 2.2), 0.4))
	draw_texture_rect(tex, Rect2(x, size.y * 0.16, tw, th), false)
	draw_string(ThemeDB.fallback_font, Vector2(door.position.x + 18, door.position.y + 34), "착륙까지 %d초" % maxi(0, int(ceil((1.0 - p) * 4.0))), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.85, 0.75))
	draw_string(ThemeDB.fallback_font, Vector2(door.position.x + 18, door.position.y + 60), "%s · %s" % [Data.CHARACTERS[hero_index].name, FlowUI.ROLES[hero_index]], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, FlowUI.GOLD)
