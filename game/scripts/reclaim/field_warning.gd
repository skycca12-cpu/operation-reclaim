extends PanelContainer

const FlowUI = preload("res://scripts/reclaim/flow/flow_ui.gd")
const DURATION := 4.5
const WARNINGS := {
	"normal": "일반 좀비가 몰려와. 가까이 붙기 전에 거리를 벌려!",
	"runner": "질주형 출현! 이동이 빠르니 포위되기 전에 경로를 열어.",
	"bomber": "자폭형 발견! 가까이 오면 폭발해. 경고 범위에서 벗어나!",
	"spitter": "독액 투사형이야. 지면에 표시가 뜨면 바로 이동해!",
	"brute": "괴력형 출현! 맷집이 강하고 원거리 공격도 해. 집중 사격해!",
	"S11": "공성형 출현! 거대한 주먹으로 방벽과 시설을 노린다!",
	"boss20": "감염 지휘체다! 포효하면 주변 좀비가 강해져.",
	"boss60": "변이 수호체 출현! 지면에 표시된 충격 범위를 피해야 해.",
	"boss40": "철갑 포식자다! 방어 태세 때 피해가 줄어. 빈틈을 노려!",
	"boss80": "파쇄자 출현! 가까운 시설에 큰 피해를 줘. 방벽을 지켜!",
	"boss100": "군체 지배자다! 지원 좀비를 부르니 퇴로부터 확보해!",
}

var _portrait: AtlasTexture
var _speaker: Label
var _line: Label
var _pending: Array[String] = []
var _remaining := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var style := FlowUI.plate_style(FlowUI.RED)
	style.bg_color = Color("#191619")
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.mouse_filter = MOUSE_FILTER_IGNORE
	box.custom_minimum_size = Vector2(372.0, 0.0)
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var label := FlowUI.make_label("", 14, FlowUI.GOLD)
	box.add_child(label)
	_speaker = label
	_line = FlowUI.make_label("", 16, FlowUI.TEXT)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size.y = 42.0
	box.add_child(_line)
	hide()


func enqueue(kind: String) -> void:
	if WARNINGS.has(kind):
		_pending.append(kind)


func pending_warnings() -> Array[String]:
	return _pending.duplicate()


func clear() -> void:
	_pending.clear()
	_remaining = 0.0
	hide()


func update(delta: float, hero: int, hero_name: String) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	if _remaining > 0.0:
		return
	if _pending.is_empty():
		hide()
		return
	var kind: String = _pending.pop_front()
	_remaining = DURATION
	var source := FlowUI.PORTRAITS[hero]
	var face := AtlasTexture.new()
	face.atlas = source
	face.region = Rect2(0, 0, source.get_width(), source.get_height() * 0.38)
	_portrait = face
	queue_redraw()
	_speaker.text = hero_name
	_line.text = WARNINGS[kind]
	show()


func _draw() -> void:
	if _portrait == null:
		return
	var image_size := _portrait.get_size()
	var fitted := image_size * minf(78.0 / image_size.x, 85.0 / image_size.y)
	draw_texture_rect(_portrait, Rect2(Vector2(12.0, -fitted.y - 2.0), fitted), false)
