extends RefCounted
## Procedural low-frame pixel helicopter (TEMPORARY art – no approved sprite yet).
## Colours follow the dark-olive transport helicopters of the approved menu art.

const OLIVE := Color("#4d5638")
const OLIVE_LIGHT := Color("#6b7650")
const DARK := Color("#23281b")
const OUTLINE := Color("#0f110c")
const GLASS := Color("#7d9aa3")
const LIGHT_RED := Color("#ff4a3d")
const ROTOR := Color(0.08, 0.08, 0.07, 0.55)


## Side view used in the sea-approach shot. `frame` steps 0..3 (low frame rotor).
static func draw_side(c: CanvasItem, pos: Vector2, s: float, frame: int, tilt := 0.08) -> void:
	c.draw_set_transform(pos, tilt, Vector2(s, s))
	# tail boom
	c.draw_colored_polygon(PackedVector2Array([Vector2(-20, -6), Vector2(-118, -12), Vector2(-122, -4), Vector2(-20, 8)]), OUTLINE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-20, -4), Vector2(-116, -10), Vector2(-118, -6), Vector2(-20, 5)]), OLIVE)
	# tail fin + tail rotor
	c.draw_colored_polygon(PackedVector2Array([Vector2(-112, -10), Vector2(-128, -34), Vector2(-120, -34), Vector2(-104, -10)]), DARK)
	var tr := 10.0 if frame % 2 == 0 else 4.0
	c.draw_line(Vector2(-124, -26 - tr), Vector2(-124, -26 + tr), ROTOR, 3.0)
	# fuselage
	var body := PackedVector2Array([Vector2(-30, -22), Vector2(34, -24), Vector2(58, -12), Vector2(64, 4), Vector2(52, 16), Vector2(-26, 18), Vector2(-36, 6)])
	c.draw_colored_polygon(body, OUTLINE)
	var inner := PackedVector2Array()
	for p in body: inner.append(p * 0.94 + Vector2(1, 0))
	c.draw_colored_polygon(inner, OLIVE)
	c.draw_rect(Rect2(-26, -20, 58, 6), OLIVE_LIGHT)
	# cockpit glass and side door
	c.draw_colored_polygon(PackedVector2Array([Vector2(36, -20), Vector2(55, -10), Vector2(58, 0), Vector2(38, 0)]), GLASS)
	c.draw_rect(Rect2(-8, -12, 26, 22), DARK)
	c.draw_rect(Rect2(-6, -10, 9, 7), GLASS.darkened(0.3))
	# skids
	c.draw_line(Vector2(-26, 26), Vector2(48, 26), OUTLINE, 3.0)
	c.draw_line(Vector2(-14, 18), Vector2(-14, 26), OUTLINE, 2.0)
	c.draw_line(Vector2(34, 16), Vector2(34, 26), OUTLINE, 2.0)
	# mast + main rotor (4 low frames: long / short blade spans)
	c.draw_rect(Rect2(4, -32, 8, 9), DARK)
	var span: float = [118.0, 70.0, 22.0, 70.0][frame % 4]
	c.draw_line(Vector2(8 - span, -33), Vector2(8 + span, -33), ROTOR, 4.0)
	c.draw_line(Vector2(8 - 120, -33), Vector2(8 + 120, -33), Color(ROTOR, 0.12), 2.0)
	# warning light
	if frame % 4 < 2:
		c.draw_circle(Vector2(-118, -10), 2.5, LIGHT_RED)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Top-down view for the over-city and landing shots. `altitude` 0 = on ground.
static func draw_top(c: CanvasItem, pos: Vector2, s: float, heading: float, rotor_angle: float, altitude: float, alpha := 1.0) -> void:
	# shadow drifts away from the body as the helicopter climbs
	var shadow_off := Vector2(26, 34) * altitude
	c.draw_set_transform(pos + shadow_off, heading, Vector2(s, s) * (1.0 - 0.15 * altitude))
	_top_silhouette(c, Color(0, 0, 0, 0.35 * alpha), Color(0, 0, 0, 0.35 * alpha))
	c.draw_set_transform(pos, heading, Vector2(s, s) * (1.0 + 0.35 * altitude))
	_top_silhouette(c, Color(OUTLINE, alpha), Color(OLIVE, alpha))
	c.draw_rect(Rect2(-10, -9, 30, 18), Color(OLIVE_LIGHT, alpha))
	c.draw_colored_polygon(PackedVector2Array([Vector2(30, -9), Vector2(44, -5), Vector2(44, 5), Vector2(30, 9)]), Color(GLASS, alpha))
	c.draw_circle(Vector2(4, 0), 5.0, Color(DARK, alpha))
	# main rotor: two crossed blades + blur disc (stepped angle = low frame look)
	var stepped := floorf(rotor_angle / (PI / 6.0)) * (PI / 6.0)
	c.draw_circle(Vector2(4, 0), 74.0, Color(0, 0, 0, 0.10 * alpha))
	for k in range(2):
		var d := Vector2.from_angle(stepped + k * PI * 0.5)
		c.draw_line(Vector2(4, 0) - d * 76.0, Vector2(4, 0) + d * 76.0, Color(0.07, 0.07, 0.06, 0.75 * alpha), 4.0)
	# tail rotor
	var td := Vector2.from_angle(stepped * 2.0)
	c.draw_line(Vector2(-78, 0) - td * 11.0, Vector2(-78, 0) + td * 11.0, Color(0.07, 0.07, 0.06, 0.7 * alpha), 2.0)
	if int(rotor_angle * 2.0) % 2 == 0:
		c.draw_circle(Vector2(-80, 0), 2.5, Color(LIGHT_RED, alpha))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _top_silhouette(c: CanvasItem, outline: Color, fill: Color) -> void:
	var body := PackedVector2Array([Vector2(-30, -16), Vector2(28, -16), Vector2(46, -8), Vector2(50, 0), Vector2(46, 8), Vector2(28, 16), Vector2(-30, 16), Vector2(-38, 0)])
	c.draw_colored_polygon(body, outline)
	var inner := PackedVector2Array()
	for p in body: inner.append(p * 0.88)
	c.draw_colored_polygon(inner, fill)
	c.draw_rect(Rect2(-82, -4, 52, 8), outline)
	c.draw_rect(Rect2(-80, -2, 50, 4), fill)
	c.draw_rect(Rect2(-86, -12, 8, 24), outline)
	# stub wings / skids
	c.draw_rect(Rect2(-14, -24, 34, 4), outline)
	c.draw_rect(Rect2(-14, 20, 34, 4), outline)
