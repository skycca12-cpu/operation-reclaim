extends RefCounted

const FIRE := 1
const POISON := 2
const ICE := 4
const SHOCK := 8
const WEAPON_KEYS := {"burn": FIRE, "poison": POISON, "freeze": ICE, "shock": SHOCK}
const EMBER := Color("#ff7b37")
const TOXIN := Color("#aada54")
const FROST := Color("#96e0ff")
const ARC := Color("#bdadff")


static func trail(canvas: CanvasItem, tail: Vector2, tip: Vector2, mask: int, phase: float) -> void:
	var forward := tail.direction_to(tip)
	var side := forward.orthogonal()
	if mask & FIRE:
		flame(canvas, tip, forward, phase)
	if mask & POISON:
		for i in range(3):
			var spot := tip - forward * (4 + i * 5) + side * (2 + i % 2 * 3)
			canvas.draw_rect(Rect2(spot.round(), Vector2(3, 3)), TOXIN)
	if mask & ICE:
		canvas.draw_line(tail - side * 2, tip - side * 2, FROST, 2.0)
		canvas.draw_rect(Rect2((tip - side * 3).round(), Vector2(3, 3)), Color("#e1f7ff"))
	if mask & SHOCK:
		spark(canvas, tail + side * 3, tip + side * 3, 1.0)


static func flame(canvas: CanvasItem, tip: Vector2, forward: Vector2, phase: float, scale := 1.0) -> void:
	var side := forward.orthogonal() * scale
	var back := -forward * scale
	var flicker := int(phase * 23.0) % 3
	var rim := PackedVector2Array([tip + back * 2, tip + back * 7 + side * 4,
		tip + back * (17 + flicker * 2) + side * 3, tip + back * 12, tip + back * 21 - side * 2,
		tip + back * 8 - side * 4])
	canvas.draw_colored_polygon(rim, Color("#d6472c"))
	var core := PackedVector2Array([tip, tip + back * 7 + side * 3, tip + back * 14,
		tip + back * 7 - side * 2])
	canvas.draw_colored_polygon(core, EMBER)
	canvas.draw_line(tip + back * 2, tip + back * 7, Color("#fff2ab"), 2.0 * scale)


static func spark(canvas: CanvasItem, a: Vector2, b: Vector2, opacity: float) -> void:
	var side := a.direction_to(b).orthogonal()
	var width := minf(5.0, a.distance_to(b) * 0.22)
	var line := PackedVector2Array([a, a.lerp(b, 0.28) + side * width, a.lerp(b, 0.5) - side * width,
		a.lerp(b, 0.73) + side * width * 0.7, b])
	canvas.draw_polyline(line, Color(ARC, opacity * 0.72), 3.0)
	canvas.draw_polyline(line, Color("#f4eaff", opacity), 1.0)


static func crystals(canvas: CanvasItem, p: Vector2, opacity: float) -> void:
	for i in range(3):
		var x := float(i - 1) * 12.0
		var base := p + Vector2(x, 30.0 + float(i % 2) * 4.0)
		var peak := base + Vector2(x * 0.36 + 2.0, -25.0 - float(i % 2) * 17.0)
		var left := base + Vector2(-6.0, -5.0)
		var right := base + Vector2(6.0, -2.0)
		canvas.draw_colored_polygon(PackedVector2Array([peak, left, base + Vector2(0, 3), right]), Color("#50acce", opacity * 0.74))
		canvas.draw_colored_polygon(PackedVector2Array([peak, base + Vector2(-1, 0), right]), Color("#daf9ff", opacity * 0.82))


static func shatter(canvas: CanvasItem, p: Vector2, age: float) -> void:
	var opacity := 1.0 - age
	for i in range(9):
		var axis := Vector2.from_angle(float(i) * TAU / 9.0 + 0.17)
		var point := p + axis * (8.0 + age * float(26 + (i % 3) * 9))
		var side := axis.orthogonal()
		canvas.draw_colored_polygon(PackedVector2Array([point + axis * 5.0, point + side * 2.0, point - axis * 3.0, point - side * 2.0]),
			Color(FROST if i % 2 == 0 else Color("#dcf7ff"), opacity))
