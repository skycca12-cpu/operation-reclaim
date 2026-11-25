extends RefCounted

const DUST := Color("#b09276")
const DARK_EARTH := Color("#32241f")
const LOOSE_EARTH := Color("#795e4b")


static func ground(canvas: CanvasItem, center: Vector2, radius: float, progress: float, openness: float, now: float) -> void:
	var edge := PackedVector2Array()
	var rim := PackedVector2Array()
	for index in range(13):
		var spoke := Vector2.from_angle(index * TAU / 13.0) * Vector2(1.0, 0.52)
		var variation := 0.65 + fposmod(float(index * 17), 13.0) * 0.032
		edge.append(center + spoke * radius * variation * openness)
		rim.append(center + spoke * radius * (variation + 0.16) * openness)
		if index % 2 == 0:
			var end := center + spoke * radius * (variation + 0.32) * (0.25 + 0.75 * progress)
			var hinge := center.lerp(end, 0.55) + spoke.orthogonal() * 5.0
			canvas.draw_polyline(PackedVector2Array([center, hinge, end]), Color(DARK_EARTH, progress * 0.92), 2.0)
	if openness > 0.0:
		canvas.draw_colored_polygon(rim, Color(LOOSE_EARTH, minf(1.0, openness * 2.0)))
		canvas.draw_colored_polygon(edge, Color(DARK_EARTH, minf(1.0, openness * 2.0)))
		for index in range(13):
			var point := rim[index]
			var fragment := PackedVector2Array([point, rim[(index + 1) % 13], edge[index]])
			canvas.draw_colored_polygon(fragment, Color(LOOSE_EARTH.lightened(float(index % 3) * 0.09), openness))
	else:
		for index in range(9):
			var age := fposmod(now * 1.65 + index * 0.37, 1.0)
			var tip := Vector2.from_angle(index * 2.4) * radius * (0.15 + age * 0.56)
			var mote := center + Vector2(tip.x, tip.y * 0.48 - age * 28.0)
			canvas.draw_circle(mote.round(), (3.0 + age * 8.0) * progress, Color(DUST, progress * (1.0 - age) * 0.38))


static func burst(canvas: CanvasItem, center: Vector2, radius: float, age: float) -> void:
	for index in range(18):
		var spoke := Vector2.from_angle(index * 2.4)
		var landing := center + spoke * Vector2(1.0, 0.56) * radius * (0.28 + age * (0.9 + (index % 5) * 0.12))
		var height := sin(age * PI) * (20.0 + (index % 6) * 9.0)
		var point := (landing - Vector2(0, height)).round()
		var chunk := float(3 + index % 4)
		var poly := PackedVector2Array([point + Vector2(-chunk, 0), point + Vector2(0, -chunk), point + Vector2(chunk, -1), point + Vector2(2, chunk)])
		canvas.draw_colored_polygon(poly, Color(LOOSE_EARTH.lightened(float(index % 3) * 0.10), 1.0 - age))
	for index in range(11):
		var spread := Vector2.from_angle(index * 2.4) * Vector2(radius, radius * 0.33) * (0.29 + age * 0.7)
		canvas.draw_circle(center + spread - Vector2(0, age * 27.0), 5.0 + age * 17.0, Color(DUST, (1.0 - age) * 0.30))
