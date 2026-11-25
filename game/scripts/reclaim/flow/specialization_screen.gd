extends Control

signal chosen(id: String)
signal back_pressed

const FlowUI = preload("res://scripts/reclaim/flow/flow_ui.gd")
const Data = preload("res://scripts/reclaim/data.gd")
const Paths = preload("res://scripts/reclaim/specializations.gd")

var title: Label
var choices: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := FlowUI.make_cover_texture(FlowUI.MENU_ART)
	bg.modulate = Color(0.17, 0.15, 0.19)
	add_child(bg)
	var body := VBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 48
	body.offset_right = -48
	body.offset_top = 28
	body.offset_bottom = -28
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 18)
	add_child(body)
	title = FlowUI.make_label("", 32, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	body.add_child(title)
	choices = HBoxContainer.new()
	choices.add_theme_constant_override("separation", 14)
	body.add_child(choices)
	var back := FlowUI.make_plate_button("난이도 선택으로")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size = Vector2(200, 48)
	back.pressed.connect(func(): back_pressed.emit())
	body.add_child(back)


func setup(hero_index: int) -> void:
	var hero: Dictionary = Data.CHARACTERS[hero_index]
	title.text = "%s · 출격 특화 선택" % hero.name
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	for path: Dictionary in Paths.PATHS[hero.id]:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", FlowUI.plate_style(FlowUI.GOLD))
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choices.add_child(panel)
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 12)
		panel.add_child(card)
		card.add_child(FlowUI.make_label(path.name, 25, Color.WHITE))
		var summary := FlowUI.make_label(path.summary, 16, FlowUI.MUTED)
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(summary)
		for index in range(Paths.LEVELS.size()):
			var line := FlowUI.make_label("%d레벨 · %s" % [Paths.LEVELS[index], path.tiers[index][0]], 16, Color.WHITE)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(line)
		var choose := FlowUI.make_plate_button("%s 선택" % path.name, true)
		choose.custom_minimum_size.y = 48
		choose.pressed.connect(func(): chosen.emit(path.id))
		card.add_child(choose)
		if choices.get_child_count() == 1:
			choose.grab_focus.call_deferred()
