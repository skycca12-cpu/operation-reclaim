extends RefCounted

const GOLD := Color("#dfc17b")
const INK := Color("#191b1b")
const RARITY := {
	"일반": Color("#a6a7ab"), "고급": Color("#82bb71"), "희귀": Color("#74aeee"),
	"영웅": Color("#b48be0"), "전설": Color("#eb6867"),
}
const ICONS := {
	"build": ["0011110","0110111","0111001","0011000","0011000","0110000","1100000"],
	"base": ["0001000","0011100","0111110","1100011","0101010","0101010","0111110"],
	"pause": ["0110110","0110110","0110110","0110110","0110110","0110110","0110110"],
	"info": ["0111110","0100010","0101010","0100010","0101010","0101010","0111110"],
	"offense": ["0000011","0000111","0001111","0011110","0111100","1101000","1100000"],
	"defense": ["1111111","1100011","1101011","1101011","0111110","0011100","0001000"],
	"range": ["0011100","0100010","1000001","1011101","1000001","0100010","0011100"],
	"health": ["0000000","0110110","1111111","1111111","0111110","0011100","0001000"],
	"rate": ["0001111","0011100","1111100","0011111","0011100","0110000","1100000"],
	"motion": ["0011100","0000110","0011110","0011000","0001100","0100111","1111110"],
	"support": ["0111110","0100010","1101011","1111111","1000001","1010101","0111110"],
}


class GridIcon extends Control:
	var pattern: Array
	var tint: Color

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var unit := floorf(side / 7.0)
		var start := (size - Vector2.ONE * unit * 7.0) * 0.5
		for y in range(pattern.size()):
			for x in range(pattern[y].length()):
				if pattern[y][x] == "1":
					draw_rect(Rect2(start + Vector2(x, y) * unit, Vector2.ONE * unit), tint)


static func icon(kind: String, tint: Color, width: float) -> Control:
	var node := GridIcon.new()
	node.pattern = ICONS.get(kind, ICONS.support)
	node.tint = tint
	node.custom_minimum_size = Vector2.ONE * width
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func plate(color: Color = GOLD, fill: Color = INK, padding: float = 6.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


static func label(value: String, font_size := 14, color := Color("#efeadc")) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func tool_button(kind: String, hint: String, callback: Callable) -> Button:
	var result := Button.new()
	result.custom_minimum_size = Vector2(38.0, 38.0)
	result.tooltip_text = hint
	result.add_theme_stylebox_override("normal", plate(Color("#776943")))
	result.add_theme_stylebox_override("hover", plate(GOLD, Color("#41371f")))
	var glyph := icon(kind, GOLD, 22.0)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result.add_child(glyph)
	result.pressed.connect(callback)
	return result


static func augment_card(card: Dictionary, callback: Callable, width: float, height: float, show_description: bool) -> Button:
	var result := Button.new()
	result.custom_minimum_size = Vector2(width, height)
	result.clip_contents = true
	var rarity := String(card.get("rarity", ""))
	var stars := clampi(int(card.get("stars", 0)), 0, 5)
	var accent: Color = RARITY.get(rarity, Color("#a6a7ab"))
	for state in ["normal", "pressed", "hover"]:
		var style := plate(accent, INK.lerp(accent, 0.13 if state == "normal" else 0.24))
		style.set_border_width_all(2 if stars >= 4 else 1)
		if stars >= 3:
			style.border_width_top = 2 + (1 if stars == 5 else 0)
		result.add_theme_stylebox_override(state, style)
	result.pressed.connect(callback)
	result.tooltip_text = String(card.get("description", ""))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 7
	box.offset_top = 7
	box.offset_right = -7
	box.offset_bottom = -7
	box.add_theme_constant_override("separation", 2)
	result.add_child(box)
	var kind := String(card.get("effect", ""))
	var keys := {"damage": "offense", "rate": "rate", "reload": "rate", "pierce": "offense", "projectile": "offense",
		"range": "range", "armor": "defense", "health": "health", "building_hp": "defense", "speed": "motion",
		"build": "build", "turret_damage": "offense", "turret_rate": "rate"}
	var icon_key := String(keys.get(kind, "support"))
	var glyph := icon(icon_key, accent, 24.0)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(glyph)
	for line in [String(card.get("name", "")), "%s  %s" % [rarity, "★".repeat(stars)] if stars > 0 else "등급·별 기록 없음"]:
		var text := label(line, 14, Color("#efeadc") if line == String(card.get("name", "")) else accent)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(text)
	if show_description:
		var description := label(String(card.get("description", "")), 12, Color("#cbc4b4"))
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(description)
	return result
