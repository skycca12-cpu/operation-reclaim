extends Control
## A single illustrated prologue precedes the in-world landing sequence.

signal finished
signal skipped

const FlowUI = preload("res://scripts/reclaim/flow/flow_ui.gd")
const APPROACH = preload("res://assets/reclaim/jeju/intro/jeju_approach.png")
const DURATION := 4.0
const CAPTION := "수도 탈환 작전 제1단계. 불타는 제주시 해안으로 진입한다."

const HERO_LINES := [
	"강태준: 방패 들고 먼저 내린다. 텐트 칠 시간은 내가 번다.",
	"윤시혁: 사거리 확보 완료. 착륙하면 바로 사격 지원 들어간다.",
	"서하린: 드론 연결 완료. 착륙 지점 주변 안전 확인할게요.",
	"한유진: 텐트 키트랑 공구 챙겼어! 내리자마자 기지 세운다!",
]

var sfx: Node = null
var _t := 0.0
var _running := false
var _title: Label
var _line: Label
var _skip: Button


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


func start() -> void:
	_t = 0.0
	_running = true
	_title.text = "제주 해상 · 20:41"
	_line.text = CAPTION
	_line.visible_characters = 0
	if sfx:
		sfx.play("wind", -10.0)
		sfx.set_rotor(0.55)
	queue_redraw()


func skip() -> void:
	if not _running:
		return
	_running = false
	if sfx: sfx.set_rotor(0.0)
	skipped.emit()


func _layout() -> void:
	var bar := size.y * 0.1
	_title.position = Vector2(40, bar + 14)
	_title.size = Vector2(600, 24)
	_line.position = Vector2(size.x * 0.1, size.y - bar - 64)
	_line.size = Vector2(size.x * 0.8, 56)
	_skip.position = Vector2(size.x - 200, 14)
	_skip.size = Vector2(176, 40)


func _process(delta: float) -> void:
	if not visible or not _running:
		return
	_t += delta
	if _t >= DURATION:
		_running = false
		if sfx: sfx.set_rotor(0.0)
		finished.emit()
		return
	_line.visible_characters = int(clampf(_t / 0.85, 0.0, 1.0) * CAPTION.length())
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
	var factor := maxf(size.x / APPROACH.get_width(), size.y / APPROACH.get_height())
	var extent := APPROACH.get_size() * factor
	draw_texture_rect(APPROACH, Rect2((size - extent) * 0.5, extent), false)
	var bar := size.y * 0.1
	draw_rect(Rect2(0, 0, size.x, bar), Color.BLACK)
	draw_rect(Rect2(0, size.y - bar, size.x, bar), Color.BLACK)
	var fade := clampf(minf(_t, DURATION - _t) / 0.3, 0.0, 1.0)
	if fade < 1.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 1.0 - fade))
