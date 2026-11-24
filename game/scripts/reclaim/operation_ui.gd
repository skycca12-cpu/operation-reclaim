extends RefCounted

const FlowUI = preload("res://scripts/reclaim/flow/flow_ui.gd")
const OPERATORS := ["tae", "si", "harin", "yujin"]
const RARITY_ORDER := ["일반", "고급", "희귀", "영웅", "전설", "신화"]

const GOLD := Color("#dfc17b")
const INK := Color("#191b1b")
const RARITY := {
	"일반": Color("#e3e3e3"), "고급": Color("#82bb71"), "희귀": Color("#74aeee"),
	"영웅": Color("#b48be0"), "전설": Color("#e8cd62"), "신화": Color("#eb6867"),
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


class CardFrame extends Control:
	var accent: Color
	var rank: int

	func _draw() -> void:
		var inset := 3.0
		var corner := 5.0 + float(rank)
		var right := size.x - inset
		var bottom := size.y - inset
		var edges := PackedVector2Array([
			Vector2(inset, corner), Vector2(corner, inset), Vector2(right - corner, inset),
			Vector2(right, corner), Vector2(right, bottom - corner), Vector2(right - corner, bottom),
			Vector2(corner, bottom), Vector2(inset, bottom - corner), Vector2(inset, corner),
		])
		draw_polyline(edges, Color(accent, 0.42), 1.0)
		for mark in range(rank + 1):
			var x := size.x * 0.5 + float(mark) * 5.0 - float(rank) * 2.5
			draw_rect(Rect2(x - 1.5, 2, 3, 3), accent)
		if rank >= 3:
			draw_line(Vector2(8, bottom), Vector2(24, bottom), accent, 2.0)
			draw_line(Vector2(right - 19, bottom), Vector2(right - 3, bottom), accent, 2.0)
		if rank >= 4:
			draw_line(Vector2(inset, bottom * 0.33), Vector2(inset, bottom * 0.57), accent, 2.0)
			draw_line(Vector2(right, bottom * 0.33), Vector2(right, bottom * 0.57), accent, 2.0)


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
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.corner_detail = 1
	style.anti_aliasing = false
	style.shadow_color = Color("#050504d9")
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
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
	var display := VBoxContainer.new()
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.alignment = BoxContainer.ALIGNMENT_CENTER
	display.add_theme_constant_override("separation", 1)
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result.add_child(display)
	var glyph := icon(kind, GOLD, 21.0)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	display.add_child(glyph)
	var caption := label({"info": "정보", "build": "건설", "base": "기지", "pause": "메뉴"}[kind], 11)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display.add_child(caption)
	result.custom_minimum_size = Vector2(39, 49)
	result.pressed.connect(callback)
	return result


static func augment_card(card: Dictionary, callback: Callable, width: float, height: float, show_description: bool) -> Button:
	var result := Button.new()
	result.custom_minimum_size = Vector2(width, height)
	result.clip_contents = true
	var rarity := String(card.get("rarity", ""))
	var stars := clampi(int(card.get("stars", 0)), 0, 6)
	var accent: Color = RARITY.get(rarity, Color("#a6a7ab"))
	var rank := maxi(0, RARITY_ORDER.find(rarity))
	for state in ["normal", "pressed", "hover"]:
		var style := plate(accent, Color("#11121b").lerp(accent, 0.07 if state == "normal" else 0.17))
		style.set_border_width_all(3 if rank >= 4 else 2 if rank >= 2 else 1)
		result.add_theme_stylebox_override(state, style)
	result.pressed.connect(callback)
	result.tooltip_text = String(card.get("description", ""))
	var frame := CardFrame.new()
	frame.rank = rank
	frame.accent = accent
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result.add_child(frame)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 7
	box.offset_top = 7
	box.offset_right = -7
	box.offset_bottom = -7
	box.add_theme_constant_override("separation", 2)
	result.add_child(box)
	var kind := String(card.get("key", card.get("effect", "")))
	var keys := {"damage": "offense", "rate": "rate", "reload": "rate", "pierce": "offense", "projectile": "offense",
		"range": "range", "armor": "defense", "health": "health", "building_hp": "defense", "speed": "motion",
		"build": "build", "turret_damage": "offense", "turret_rate": "rate", "hp": "health",
		"magazine": "offense", "move": "motion", "regen": "health", "crit": "range", "evade": "motion",
		"projectile_speed": "rate", "ricochet": "offense", "freeze_strength": "defense", "burn_damage": "offense",
		"saw_angle": "range", "dash_distance": "motion", "facility_hp": "build", "wall_hp": "defense"}
	var icon_key := String(keys.get(kind, "support"))
	var glyph := icon(icon_key, accent.lightened(0.42), 42.0 if show_description else 28.0)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(glyph)
	var rating := label("★".repeat(stars), 14, Color("#ffce54"))
	rating.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(rating)
	var name_text := label(String(card.get("name", "")), 13)
	name_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_text)
	if show_description:
		var tier := label(rarity, 12, accent)
		tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(tier)
	if show_description:
		var description := label(String(card.get("description", "")), 12, Color("#cbc4b4"))
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(description)
	var owner := OPERATORS.find(String(card.get("hero", "")))
	if owner >= 0:
		var source: Texture2D = FlowUI.PORTRAITS[owner]
		var face := AtlasTexture.new()
		face.atlas = source
		face.region = Rect2(source.get_width() * 0.26, 0, source.get_width() * 0.48, source.get_height() * 0.31)
		var badge := TextureRect.new()
		badge.texture = face
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		badge.offset_left = -34.0
		badge.offset_right = -6.0
		badge.offset_top = 5.0
		badge.offset_bottom = 33.0
		result.add_child(badge)
	return result
