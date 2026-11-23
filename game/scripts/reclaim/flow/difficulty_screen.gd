extends Control
## Five-step difficulty selection: 쉬움 · 보통 · 어려움 · 매우 어려움 · 지옥.

signal chosen(index: int)
signal back_pressed

const FlowUI = preload("res://scripts/reclaim/flow/flow_ui.gd")
const Data = preload("res://scripts/reclaim/data.gd")
const ACCENTS := [Color("#6fc47f"), Color("#d8c36a"), Color("#e48a45"), Color("#e2493f"), Color("#a3122a")]
const NOTES := [
	"처음 플레이하는 대원용 · 적이 약하고 느리게 몰려옵니다",
	"기준 난이도 · 설계된 전투 밸런스",
	"적 체력과 공격이 강해지고 더 자주 몰려옵니다",
	"숙련자용 · 진지 구축이 늦으면 버티기 어렵습니다",
	"생존 보장 없음 · 최대 체력·공격·출현 배율",
]

var selected := 1
var hero_index := 0
var _rows: Array[Button] = []
var _portrait: TextureRect
var _hero_label: Label
var _confirm: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := FlowUI.make_cover_texture(FlowUI.MENU_ART)
	bg.modulate = Color(0.14, 0.11, 0.13)
	add_child(bg)
	var split := HBoxContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	split.offset_left = 50; split.offset_right = -50; split.offset_top = 26; split.offset_bottom = -22
	split.add_theme_constant_override("separation", 36)
	add_child(split)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(360, 0)
	split.add_child(left)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	left.add_child(_portrait)
	_hero_label = FlowUI.make_label("", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	left.add_child(_hero_label)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 10)
	split.add_child(right)
	right.add_child(FlowUI.make_label("난이도 선택", 36, Color.WHITE))
	right.add_child(FlowUI.make_label("제주 점령구역 · 작전 강도를 정하세요", 15, FlowUI.MUTED))
	for i in range(Data.DIFFICULTIES.size()):
		var d: Dictionary = Data.DIFFICULTIES[i]
		var b := FlowUI.make_plate_button("", false, ACCENTS[i])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 70)
		b.add_theme_font_size_override("font_size", 17)
		b.text = "%s\n%s   (적 체력 ×%.1f · 공격 ×%.2f · 출현 ×%.1f)" % [d.label, NOTES[i], d.hp, d.attack, d.spawn]
		b.pressed.connect(_select.bind(i))
		b.mouse_entered.connect(func(): b.grab_focus())
		right.add_child(b)
		_rows.append(b)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	right.add_child(buttons)
	var back := FlowUI.make_plate_button("뒤로")
	back.custom_minimum_size = Vector2(170, 50)
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(func(): back_pressed.emit())
	buttons.add_child(back)
	_confirm = FlowUI.make_plate_button("", true)
	_confirm.custom_minimum_size = Vector2(320, 50)
	_confirm.add_theme_font_size_override("font_size", 22)
	_confirm.pressed.connect(func(): chosen.emit(selected))
	buttons.add_child(_confirm)
	_select(selected)


func setup(hero: int, difficulty: int) -> void:
	hero_index = hero
	_portrait.texture = FlowUI.PORTRAITS[hero]
	_hero_label.text = "%s · %s" % [Data.CHARACTERS[hero].name, FlowUI.ROLES[hero]]
	_select(difficulty)
	_confirm.grab_focus.call_deferred()


func _select(i: int) -> void:
	selected = clampi(i, 0, _rows.size() - 1)
	for k in range(_rows.size()):
		var on := k == selected
		var st := FlowUI.plate_style(ACCENTS[k] if on else ACCENTS[k].darkened(0.55), on)
		if on: st.bg_color = ACCENTS[k].darkened(0.78)
		_rows[k].add_theme_stylebox_override("normal", st)
		_rows[k].add_theme_stylebox_override("focus", FlowUI.plate_style(ACCENTS[k].lightened(0.2), on, true))
		_rows[k].add_theme_stylebox_override("hover", FlowUI.plate_style(ACCENTS[k].lightened(0.2), on, true))
	_confirm.text = "▶  %s 난이도로 출격" % Data.DIFFICULTIES[selected].label


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed:
		return
	var code: int = event.physical_keycode
	if code >= KEY_1 and code <= KEY_5:
		_select(code - KEY_1); get_viewport().set_input_as_handled()
	elif code == KEY_UP or code == KEY_W:
		_select(selected - 1); get_viewport().set_input_as_handled()
	elif code == KEY_DOWN or code == KEY_S:
		_select(selected + 1); get_viewport().set_input_as_handled()
