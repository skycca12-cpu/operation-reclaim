extends Control
## Main menu on the approved key art (메인화면_승인참고.png, used unmodified).
## An opaque backing covers the original button artwork below the live menu.

signal start_pressed
signal continue_pressed
signal settings_pressed
signal perks_pressed
signal quit_pressed

const FlowUI = preload("res://scripts/reclaim/flow/flow_ui.gd")
const ART_SIZE := Vector2(1670, 941)
const BUTTON_RECTS := {
	"start": Rect2(658, 498, 350, 72),
	"continue": Rect2(658, 576, 350, 72),
	"settings": Rect2(658, 651, 350, 72),
	"quit": Rect2(658, 726, 350, 72),
}
const PERK_RECT := Rect2(700, 828, 266, 46)

var buttons: Dictionary = {}
var _backing: ColorRect
var _selected := ""
var _notice: Label
var _hint: Label
var _notice_timer := 0.0
var _intro := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(FlowUI.make_cover_texture(FlowUI.MENU_ART))
	_backing = ColorRect.new()
	_backing.color = Color("#21191f")
	_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backing)
	buttons.start = FlowUI.make_plate_button("게임 시작")
	buttons["continue"] = FlowUI.make_plate_button("이어하기")
	buttons.settings = FlowUI.make_plate_button("설정")
	buttons.quit = FlowUI.make_plate_button("게임 종료")
	buttons.perks = FlowUI.make_plate_button("작전 훈장 강화", false, FlowUI.GOLD)
	for key in buttons:
		var button: Button = buttons[key]
		button.button_mask = 0
		button.gui_input.connect(_handle_button_click.bind(String(key)))
		button.pressed.connect(_activate.bind(String(key)))
		add_child(button)
	_notice = FlowUI.make_label("", 18, FlowUI.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_notice)
	_hint = FlowUI.make_label("클릭으로 선택 · 더블클릭으로 실행", 14, FlowUI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
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
	_select_button("")


func _handle_button_click(event: InputEvent, key: String) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var button: Button = buttons[key]
	if button.disabled:
		return
	var activate: bool = event.double_click and _selected == key
	_select_button(key)
	button.grab_focus()
	button.accept_event()
	if activate:
		_activate(key)


func _select_button(selected: String) -> void:
	_selected = selected
	for key in buttons:
		var button: Button = buttons[key]
		var accent := FlowUI.RED if key == selected else FlowUI.GOLD if key == "perks" else FlowUI.SILVER
		button.add_theme_stylebox_override("normal", FlowUI.plate_style(accent))
		button.add_theme_stylebox_override("hover", FlowUI.plate_style(accent, false, true))
		button.add_theme_stylebox_override("pressed", FlowUI.plate_style(accent, false, true, true))
		var focus := FlowUI.plate_style(accent)
		focus.draw_center = false
		focus.shadow_size = 0
		button.add_theme_stylebox_override("focus", focus)


func _activate(key: String) -> void:
	match key:
		"start": start_pressed.emit()
		"continue": continue_pressed.emit()
		"settings": settings_pressed.emit()
		"perks": perks_pressed.emit()
		"quit": quit_pressed.emit()


func _layout() -> void:
	var cover := FlowUI.cover_rect(size, ART_SIZE)
	var s := cover.size.x / ART_SIZE.x
	var backing := FlowUI.art_to_screen(Rect2(619, 480, 428, 333), cover, ART_SIZE)
	_backing.position = backing.position
	_backing.size = backing.size
	for key in BUTTON_RECTS:
		var r := FlowUI.art_to_screen(BUTTON_RECTS[key], cover, ART_SIZE)
		var b: Button = buttons[key]
		b.position = r.position
		b.size = r.size
		b.add_theme_font_size_override("font_size", int(32 * s))
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
