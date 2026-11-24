extends Control
## Two four-second flights precede the in-world landing sequence.
## Both preserve the original subtitles and support skipping.

signal finished
signal skipped

const FlowUI = preload("res://scripts/reclaim/flow/flow_ui.gd")
const HeliArt = preload("res://scripts/reclaim/flow/heli_art.gd")

const COAST = preload("res://assets/reclaim/jeju/intro/jeju_coast.png")
const CITY = preload("res://assets/reclaim/jeju/intro/jeju_city.png")
const SHOTS := [
	{"len": 4.0, "title": "제주 해상 · 20:41", "line": "수도 탈환 작전 제1단계. 점령된 제주시 해안으로 진입한다."},
	{"len": 4.0, "title": "제주시 점령구역 상공", "line": "도심 중앙 광장, 붉은 신호탄 확인. 착륙 지점으로 하강한다."},
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
var _radio_played := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	skipped.emit()


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
	_line.text = SHOTS[_shot].line


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
		var level: float = [0.55, 0.85][_shot]
		sfx.set_rotor(level)
		if _shot == 1 and not _radio_played and _shot_t > 0.4:
			_radio_played = true
			sfx.play("radio", -8.0)
	# subtitles type in over the first second of a shot (cheap typewriter)
	var full: String = SHOTS[_shot].line
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
	var shot := mini(_shot, SHOTS.size() - 1)
	var progress := clampf(_shot_t / float(SHOTS[shot].len), 0.0, 1.0)
	var background: Texture2D = COAST if shot == 0 else CITY
	var factor := maxf(size.x / background.get_width(), size.y / background.get_height())
	var extent := background.get_size() * factor
	var scene := Rect2((size - extent) * 0.5, extent)
	draw_texture_rect(background, scene, false)
	if shot == 1:
		for hotspot in [Vector2(0.20, 0.31), Vector2(0.69, 0.42), Vector2(0.92, 0.37)]:
			var anchor: Vector2 = scene.position + hotspot * scene.size
			var shift: float = hotspot.x * 1.6
			var effect_size := Vector2.ONE * size.y * 0.23
			HeliArt.draw_clip(self, "fire", _t + shift, anchor, effect_size, 0.54)
			HeliArt.draw_clip(self, "smoke", _t + shift, anchor, effect_size * 1.35, 0.42)
			HeliArt.draw_clip(self, "embers", _t + shift + 0.31, anchor + Vector2(0, -24), effect_size, 0.56)
	var aircraft := Vector2.ONE * size.y * (0.50 if shot == 0 else 0.58)
	var flight := Vector2(lerpf(-0.23, 1.24, progress) * size.x,
		size.y * (0.43 if shot == 0 else lerpf(0.34, 0.55, progress)))
	HeliArt.draw_clip(self, "side", _t, flight, aircraft)
	var bar := size.y * 0.1
	draw_rect(Rect2(0, 0, size.x, bar), Color.BLACK)
	draw_rect(Rect2(0, size.y - bar, size.x, bar), Color.BLACK)
	var fade := clampf(minf(progress, 1.0 - progress) * 12.0, 0.0, 1.0)
	if fade < 1.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 1.0 - fade))
