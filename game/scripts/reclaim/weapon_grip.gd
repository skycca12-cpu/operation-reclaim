extends RefCounted


static func draw_sleeve(canvas: CanvasItem, shoulder: Vector2, elbow: Vector2, wrist: Vector2, cloth: Color) -> void:
	var sleeve := PackedVector2Array([shoulder, elbow, wrist])
	canvas.draw_polyline(sleeve, Color("#201922"), 10.0)
	canvas.draw_polyline(sleeve, cloth.darkened(0.32), 7.0)
	canvas.draw_line(shoulder + Vector2(0, -1), elbow + Vector2(0, -1), cloth, 3.0)


static func draw_glove(canvas: CanvasItem, grip: Vector2, tint: Color) -> void:
	var hand := grip.round()
	canvas.draw_colored_polygon(PackedVector2Array([
		hand + Vector2(-4, -2), hand + Vector2(-2, -4), hand + Vector2(2, -4),
		hand + Vector2(4, -2), hand + Vector2(4, 2), hand + Vector2(2, 4),
		hand + Vector2(-3, 4), hand + Vector2(-4, 2),
	]), Color("#211922"))
	canvas.draw_rect(Rect2(hand + Vector2(-3, -2), Vector2(6, 4)), tint)
	canvas.draw_line(hand + Vector2(-2, -2), hand + Vector2(2, -2), tint.lightened(0.26), 1.0)
