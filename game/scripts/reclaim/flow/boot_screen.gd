extends Control
## Boot / loading screen. Uses the approved loading illustration (with the baked
## bar and text erased by tools/make_flow_assets.py) and draws a REAL progress
## bar: every step below is executed one per frame and the bar reports
## completed_steps / total_steps. A short minimum time per step keeps it legible.

signal finished

const FlowUI = preload("res://scripts/reclaim/flow/flow_ui.gd")
const ART_SIZE := Vector2(1673, 940)
# Approved-art pixel rectangles of the original baked loading UI.
const TEXT_RECT := Rect2(1066, 796, 420, 44)
const BAR_RECT := Rect2(1062, 849, 418, 36)
const PCT_RECT := Rect2(1488, 838, 120, 58)
const MIN_STEP_TIME := 0.14

const STEPS := [
	["작전 지도 불러오는 중", "res://assets/reclaim/world/jeju_ground_tile.png"],
	["도심 구조물 배치 중", "res://assets/reclaim/world/jeju_props_atlas.png"],
	["메인 화면 준비 중", "res://assets/reclaim/ui/main_menu_art.png"],
	["강태준 합류", "res://assets/reclaim/portraits/tae_full.png"],
	["윤시혁 합류", "res://assets/reclaim/portraits/si_full.png"],
	["서하린 합류", "res://assets/reclaim/portraits/harin_full.png"],
	["한유진 합류", "res://assets/reclaim/portraits/yujin_full.png"],
	["전투 스프라이트 점검", "res://assets/reclaim/characters/harin_sheet.png"],
	["헬기 무전 연결", "res://assets/reclaim/audio/rotor_loop.wav"],
	["착륙 신호 확인", "res://assets/reclaim/audio/land_thump.wav"],
	["보급 텐트 적재", "res://assets/reclaim/audio/hq_build.wav"],
	["저장 데이터 확인", ""],
]

var _art: TextureRect
var _status: Label
var _pct: Label
var _hint: Label
var _step := 0
var _step_timer := 0.0
var _shown := 0.0
var _done := false
var _done_time := 0.0
var _fade := 0.0
var loaded: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_art = FlowUI.make_cover_texture(FlowUI.LOADING_ART)
	add_child(_art)
	_status = FlowUI.make_label("작전 준비 중...", 22)
	add_child(_status)
	_pct = FlowUI.make_label("0%", 40, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_pct)
	_hint = FlowUI.make_label("", 16, FlowUI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_hint)
	resized.connect(_layout)
	_layout()


func restart() -> void:
	_step = 0
	_step_timer = 0.0
	_shown = 0.0
	_done = false
	_done_time = 0.0
	_fade = 0.0


func progress() -> float:
	return float(_step) / float(STEPS.size())


func _layout() -> void:
	var cover := FlowUI.cover_rect(size, ART_SIZE)
	var s := cover.size.x / ART_SIZE.x
	var t := FlowUI.art_to_screen(TEXT_RECT, cover, ART_SIZE)
	_status.position = t.position
	_status.size = t.size
	_status.add_theme_font_size_override("font_size", int(30 * s))
	var p := FlowUI.art_to_screen(PCT_RECT, cover, ART_SIZE)
	_pct.position = p.position
	_pct.size = p.size
	_pct.add_theme_font_size_override("font_size", int(44 * s))
	_hint.position = Vector2(0, size.y - 34)
	_hint.size = Vector2(size.x, 26)


func _process(delta: float) -> void:
	if not visible:
		return
	_fade = minf(1.0, _fade + delta * 2.5)
	modulate.a = _fade
	if not _done:
		_step_timer += delta
		if _step_timer >= MIN_STEP_TIME and _step < STEPS.size():
			_step_timer = 0.0
			var path: String = STEPS[_step][1]
			if path != "" and ResourceLoader.exists(path):
				loaded[path] = ResourceLoader.load(path)
			_status.text = "작전 준비 중... %s" % STEPS[_step][0]
			_step += 1
			if _step >= STEPS.size():
				_done = true
				_status.text = "작전 준비 완료"
	else:
		_done_time += delta
		_hint.text = "클릭하거나 아무 키나 눌러 계속" if int(_done_time * 2.0) % 2 == 0 else ""
		if _done_time > 6.0:
			_emit()
	_shown = move_toward(_shown, progress(), delta * 2.2)
	_pct.text = "%d%%" % int(round(_shown * 100.0))
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if _done and _done_time > 0.25 and ((event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed)):
		_emit()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _done and _done_time > 0.25 and event is InputEventKey and event.pressed and not event.echo:
		_emit()
		get_viewport().set_input_as_handled()


func _emit() -> void:
	if not visible:
		return
	visible = false
	finished.emit()


func _draw() -> void:
	var cover := FlowUI.cover_rect(size, ART_SIZE)
	var bar := FlowUI.art_to_screen(BAR_RECT, cover, ART_SIZE)
	# dark plate covering the erased area, then the approved-style red bar
	draw_rect(bar.grow(4), Color(0.04, 0.02, 0.03, 0.92))
	draw_rect(bar, Color("#2a0c10"))
	var fill := Rect2(bar.position, Vector2(bar.size.x * _shown, bar.size.y))
	draw_rect(fill, FlowUI.RED)
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.35)), Color(1, 0.55, 0.55, 0.45))
	if fill.size.x > 6:
		draw_rect(Rect2(fill.end.x - 5, fill.position.y, 5, fill.size.y), Color(1, 0.9, 0.9, 0.85))
	draw_rect(bar.grow(2), FlowUI.RED, false, 2.0)
