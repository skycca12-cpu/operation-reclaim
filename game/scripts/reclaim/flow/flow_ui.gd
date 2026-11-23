extends RefCounted
## Shared look for the opening-flow screens (loading, menu, roster, difficulty,
## prologue). Mirrors the approved main-menu plates: near-black fill, silver
## pixel border, crimson accent for the primary action.

const RED := Color("#e8333a")
const RED_DARK := Color("#3b0b10")
const SILVER := Color("#b9b5bd")
const PLATE := Color("#141015")
const TEXT := Color("#f2edf0")
const MUTED := Color("#a69aa3")
const GOLD := Color("#e7c46a")

const MENU_ART: Texture2D = preload("res://assets/reclaim/ui/main_menu_art.png")
const LOADING_ART: Texture2D = preload("res://assets/reclaim/ui/loading_art.png")
const PORTRAITS: Array[Texture2D] = [
	preload("res://assets/reclaim/portraits/tae_full.png"),
	preload("res://assets/reclaim/portraits/si_full.png"),
	preload("res://assets/reclaim/portraits/harin_full.png"),
	preload("res://assets/reclaim/portraits/yujin_full.png"),
]
## Roles exactly as printed on the approved character sheets.
const ROLES := ["방어 특화형", "공격 특화형", "전술 지원형", "공병 지원형"]


static func plate_style(accent: Color, primary := false, hovered := false, pressed := false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = (RED_DARK if primary else PLATE)
	if hovered:
		s.bg_color = s.bg_color.lightened(0.10)
	if pressed:
		s.bg_color = s.bg_color.darkened(0.25)
	s.border_color = accent.lightened(0.25) if hovered else accent
	s.set_border_width_all(3)
	s.set_corner_radius_all(3)
	s.content_margin_left = 12.0
	s.content_margin_right = 12.0
	s.content_margin_top = 6.0
	s.content_margin_bottom = 6.0
	if primary:
		s.shadow_color = Color(RED, 0.55 if hovered else 0.35)
		s.shadow_size = 10
	else:
		s.shadow_color = Color(0, 0, 0, 0.55)
		s.shadow_size = 4
	return s


static func make_plate_button(text: String, primary := false, accent: Color = SILVER) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	var a := RED if primary else accent
	b.add_theme_stylebox_override("normal", plate_style(a, primary))
	b.add_theme_stylebox_override("hover", plate_style(a, primary, true))
	b.add_theme_stylebox_override("pressed", plate_style(a, primary, true, true))
	b.add_theme_stylebox_override("focus", plate_style(a.lightened(0.35), primary, true))
	b.add_theme_stylebox_override("disabled", plate_style(Color(0.35, 0.33, 0.36), false))
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.47, 0.5))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	b.add_theme_constant_override("outline_size", 4)
	return b


static func make_label(text: String, font_size := 18, color: Color = TEXT, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Rectangle (in control space) where a texture is drawn with "cover" scaling.
static func cover_rect(container: Vector2, tex_size: Vector2) -> Rect2:
	var s := maxf(container.x / tex_size.x, container.y / tex_size.y)
	var draw_size := tex_size * s
	return Rect2((container - draw_size) * 0.5, draw_size)


## Maps a rectangle given in approved-art pixels into control space.
static func art_to_screen(art_rect: Rect2, cover: Rect2, tex_size: Vector2) -> Rect2:
	var s := cover.size.x / tex_size.x
	return Rect2(cover.position + art_rect.position * s, art_rect.size * s)


static func make_cover_texture(tex: Texture2D) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return t
