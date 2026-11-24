extends Control
## Four-operator selection with full-body portraits.

signal chosen(index: int)
signal back_pressed

const FlowUI = preload("res://scripts/reclaim/flow/flow_ui.gd")
const Data = preload("res://scripts/reclaim/data.gd")
var selected := 2
var _cards: Array[Button] = []
var _portraits: Array[TextureRect] = []
var _detail: Label
var _confirm: Button
var _time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := FlowUI.make_cover_texture(FlowUI.MENU_ART)
	bg.modulate = Color(0.28, 0.24, 0.27)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 40; root.offset_right = -40; root.offset_top = 22; root.offset_bottom = -18
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	root.add_child(FlowUI.make_label("작전 인원 선택", 36, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(FlowUI.make_label("한 판에 한 명만 직접 출격합니다 · 카드를 눌러 대원을 고르세요", 15, FlowUI.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	root.add_child(row)
	for i in range(Data.CHARACTERS.size()):
		row.add_child(_make_card(i))
	_detail = FlowUI.make_label("", 16, FlowUI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_detail)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	root.add_child(buttons)
	var back := FlowUI.make_plate_button("뒤로")
	back.custom_minimum_size = Vector2(180, 50)
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(func(): back_pressed.emit())
	buttons.add_child(back)
	_confirm = FlowUI.make_plate_button("", true)
	_confirm.custom_minimum_size = Vector2(340, 50)
	_confirm.add_theme_font_size_override("font_size", 22)
	_confirm.pressed.connect(func(): chosen.emit(selected))
	buttons.add_child(_confirm)
	_select(selected)


func _make_card(i: int) -> Button:
	var c: Dictionary = Data.CHARACTERS[i]
	var card := Button.new()
	card.custom_minimum_size = Vector2(270, 0)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.toggle_mode = false
	card.focus_mode = Control.FOCUS_ALL
	card.pressed.connect(_select.bind(i))
	card.mouse_entered.connect(func(): card.grab_focus())
	_cards.append(card)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10; box.offset_right = -10; box.offset_top = 10; box.offset_bottom = -10
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var portrait := TextureRect.new()
	portrait.texture = FlowUI.PORTRAITS[i]
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	box.add_child(portrait)
	_portraits.append(portrait)
	box.add_child(FlowUI.make_label(String(c.name), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(FlowUI.make_label(FlowUI.ROLES[i], 15, FlowUI.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(FlowUI.make_label(String(c.weapon), 14, FlowUI.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var stats := FlowUI.make_label("HP %d  ·  이동 %d" % [int(c.hp), int(c.speed)], 13, FlowUI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(stats)
	return card


func _select(i: int) -> void:
	if i != selected:
		pass
	selected = i
	for k in range(_cards.size()):
		var on := k == selected
		var accent := FlowUI.RED if on else FlowUI.SILVER.darkened(0.35)
		var st := FlowUI.plate_style(accent, on)
		st.bg_color = Color(0.09, 0.05, 0.07, 0.92) if on else Color(0.05, 0.04, 0.05, 0.82)
		var hv := FlowUI.plate_style(FlowUI.RED.lightened(0.2) if on else FlowUI.SILVER, on, true)
		hv.bg_color = st.bg_color.lightened(0.06)
		_cards[k].add_theme_stylebox_override("normal", st)
		_cards[k].add_theme_stylebox_override("hover", hv)
		_cards[k].add_theme_stylebox_override("pressed", hv)
		_cards[k].add_theme_stylebox_override("focus", hv)
		_portraits[k].modulate = Color.WHITE if on else Color(0.62, 0.6, 0.64)
	var c: Dictionary = Data.CHARACTERS[selected]
	_detail.text = "%s · %s — %s" % [c.name, FlowUI.ROLES[selected], c.special]
	_confirm.text = "▶  %s(으)로 출격 준비" % c.name


func on_shown() -> void:
	_select(selected)
	_confirm.grab_focus.call_deferred()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed:
		return
	var code: int = event.physical_keycode
	if code >= KEY_1 and code <= KEY_4:
		_select(code - KEY_1)
		get_viewport().set_input_as_handled()
	elif code == KEY_LEFT or code == KEY_A:
		_select(posmod(selected - 1, 4)); get_viewport().set_input_as_handled()
	elif code == KEY_RIGHT or code == KEY_D:
		_select(posmod(selected + 1, 4)); get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	# 2-frame idle "breath" on the selected portrait (low frame count on purpose)
	for k in range(_portraits.size()):
		_portraits[k].position.y = (-3.0 if (k == selected and int(_time * 2.0) % 2 == 0) else 0.0)
