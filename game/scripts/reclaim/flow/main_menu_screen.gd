extends Control
## Main menu on the approved key art (메인화면_승인참고.png, used unmodified).
## The four plates baked into the art are covered by REAL interactive buttons
## placed on exactly the same art-pixel rectangles.

signal start_pressed
signal continue_pressed
signal settings_pressed
signal perks_pressed
signal quit_pressed

const FlowUI = preload("res://scripts/reclaim/flow/flow_ui.gd")
const ART_SIZE := Vector2(1670, 941)
const BUTTON_RECTS := {
	"start": Rect2(632, 497, 404, 80),
	"continue": Rect2(658, 576, 350, 72),
	"settings": Rect2(658, 651, 350, 72),
	"quit": Rect2(658, 726, 350, 80),
}
const PERK_RECT := Rect2(700, 828, 266, 46)

var buttons: Dictionary = {}
var _art: TextureRect
var _notice: Label
var _hint: Label
var _notice_timer := 0.0
var _intro := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_art = FlowUI.make_cover_texture(FlowUI.MENU_ART)
	add_child(_art)
	buttons.start = FlowUI.make_plate_button("▶  게임 시작", true)
	buttons["continue"] = FlowUI.make_plate_button("이어하기")
	buttons.settings = FlowUI.make_plate_button("설정")
	buttons.quit = FlowUI.make_plate_button("게임 종료")
	buttons.perks = FlowUI.make_plate_button("작전 훈장 강화", false, FlowUI.GOLD)
	for key in buttons:
		add_child(buttons[key])
	buttons.start.pressed.connect(func(): start_pressed.emit())
	buttons["continue"].pressed.connect(func(): continue_pressed.emit())
	buttons.settings.pressed.connect(func(): settings_pressed.emit())
	buttons.perks.pressed.connect(func(): perks_pressed.emit())
	buttons.quit.pressed.connect(func(): quit_pressed.emit())
	_notice = FlowUI.make_label("", 18, FlowUI.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_notice)
	_hint = FlowUI.make_label("WASD 이동 · 마우스 조준 · Shift 회피 · B 건설 · Esc 일시정지", 14, FlowUI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_hint)
	resized.connect(_layout)
	_layout()


func set_continue_available(available: bool) -> void:
	var b: Button = buttons["continue"]
	b.disabled = not available
	b.tooltip_text = "" if available else "저장된 작전이 없습니다"


func show_notice(text: String) -> void:
	_notice.text = text
	_notice_timer = 3.5


func on_shown() -> void:
	_intro = 0.0
	buttons.start.grab_focus.call_deferred()


func _layout() -> void:
	var cover := FlowUI.cover_rect(size, ART_SIZE)
	var s := cover.size.x / ART_SIZE.x
	for key in BUTTON_RECTS:
		var r := FlowUI.art_to_screen(BUTTON_RECTS[key], cover, ART_SIZE)
		var b: Button = buttons[key]
		b.position = r.position
		b.size = r.size
		b.add_theme_font_size_override("font_size", int((36 if key == "start" else 32) * s))
	var pr := FlowUI.art_to_screen(PERK_RECT, cover, ART_SIZE)
	buttons.perks.position = pr.position
	buttons.perks.size = pr.size
	buttons.perks.add_theme_font_size_override("font_size", int(22 * s))
	_notice.position = Vector2(0, pr.end.y + 6)
	_notice.size = Vector2(size.x, 28)
	_hint.position = Vector2(0, size.y - 28)
	_hint.size = Vector2(size.x, 24)


func _process(delta: float) -> void:
	if not visible:
		return
	_intro = minf(1.0, _intro + delta * 2.0)
	modulate.a = _intro
	if _notice_timer > 0.0:
		_notice_timer -= delta
		if _notice_timer <= 0.0:
			_notice.text = ""
