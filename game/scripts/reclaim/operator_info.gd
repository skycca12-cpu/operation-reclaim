extends CenterContainer

const UI = preload("res://scripts/reclaim/operation_ui.gd")

signal closed

var _title: Label
var _portrait: TextureRect
var _stats: GridContainer
var _cards: GridContainer
var _detail: Label
var _note: Label
var _acquired_title: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	add_child(layout)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(466.0, 420.0)
	panel.add_theme_stylebox_override("panel", UI.plate(UI.GOLD, Color("#171b19"), 14.0))
	layout.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 9)
	panel.add_child(body)
	body.add_child(UI.label("캐릭터 정보", 19, UI.GOLD))
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	body.add_child(header)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(85.0, 65.0)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(_portrait)
	_title = UI.label("", 22, UI.GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_title)
	_stats = GridContainer.new()
	_stats.columns = 4
	_stats.add_theme_constant_override("h_separation", 8)
	_stats.add_theme_constant_override("v_separation", 2)
	body.add_child(_stats)
	_note = UI.label("", 12, Color("#adac9e"))
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_note)
	var inventory := PanelContainer.new()
	inventory.custom_minimum_size = Vector2(437, 420)
	inventory.add_theme_stylebox_override("panel", UI.plate(UI.GOLD, Color("#171b19"), 12.0))
	layout.add_child(inventory)
	var acquired := VBoxContainer.new()
	acquired.add_theme_constant_override("separation", 8)
	inventory.add_child(acquired)
	var tools := HBoxContainer.new()
	acquired.add_child(tools)
	_acquired_title = UI.label("", 19, UI.GOLD)
	_acquired_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_child(_acquired_title)
	var close := Button.new()
	close.text = "×"
	close.tooltip_text = "닫기 [C]"
	close.custom_minimum_size.x = 36
	close.add_theme_stylebox_override("normal", UI.plate())
	close.pressed.connect(func(): closed.emit())
	tools.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 236.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	acquired.add_child(scroll)
	_cards = GridContainer.new()
	_cards.columns = 4
	_cards.add_theme_constant_override("h_separation", 6)
	_cards.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_cards)
	_detail = UI.label("", 13, UI.GOLD)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size.y = 36.0
	acquired.add_child(_detail)


func fill(heading: String, portrait: Texture2D, rows: Array, cards: Array, note: String) -> void:
	_title.text = heading
	_portrait.texture = portrait
	_note.text = note
	_acquired_title.text = "획득한 증강  (%d)" % cards.size()
	for list in [_stats, _cards]:
		for child in list.get_children():
			list.remove_child(child)
			child.queue_free()
	for row in [["능력치", "기본 수치", "증강 증가치", "최종 수치"]] + rows:
		for col in range(4):
			var color := UI.GOLD if col == 3 else Color("#9bd39f") if col == 2 else Color("#e3ded0")
			var cell := UI.label(String(row[col]), 14, color)
			cell.custom_minimum_size = Vector2(122.0 if col == 0 else 94.0, 26.0)
			cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			var plate := PanelContainer.new()
			var fill_color := Color("#34301e") if col == 3 else Color("#202321")
			plate.add_theme_stylebox_override("panel", UI.plate(Color("#66583a") if col == 3 else Color("#31342f"), fill_color, 0.0))
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plate.add_child(cell)
			_stats.add_child(plate)
	_detail.text = "이번 전투에서 획득한 증강이 없습니다." if cards.is_empty() else "카드를 선택하면 효과를 확인할 수 있습니다."
	for card in cards:
		_cards.add_child(UI.augment_card(card, _show_effect.bind(card), 93.0, 94.0, false))


func _show_effect(card: Dictionary) -> void:
	var count := int(card.get("count", 1))
	var prefix := "%s · %d회 획득" % [card.name, count] if count > 1 else String(card.name)
	var applied: Array = card.get("effects_applied", [])
	var description := " / ".join(PackedStringArray(applied)) if count > 1 and not applied.is_empty() else String(card.description)
	_detail.text = "%s · %s" % [prefix, description]
