extends RefCounted

const GROUND: Texture2D = preload("res://assets/reclaim/world/jeju_ground_tile.png")
const PROPS: Texture2D = preload("res://assets/reclaim/world/jeju_props_atlas.png")
const PROP_CELL := Vector2(768.0, 768.0)
const MAP_TILE := 1920.0


static func draw(canvas: CanvasItem, camera: Vector2, viewport: Vector2) -> void:
	var view_left := camera.x - viewport.x * 0.5
	var view_top := camera.y - viewport.y * 0.5
	var first_x := floori(view_left / MAP_TILE) * int(MAP_TILE)
	var first_y := floori(view_top / MAP_TILE) * int(MAP_TILE)
	for world_y in range(first_y, int(view_top + viewport.y) + int(MAP_TILE), int(MAP_TILE)):
		for world_x in range(first_x, int(view_left + viewport.x) + int(MAP_TILE), int(MAP_TILE)):
			var screen_pos := Vector2(world_x, world_y) - camera + viewport * 0.5
			canvas.draw_texture_rect(GROUND, Rect2(screen_pos, Vector2(MAP_TILE, MAP_TILE)), false)
	_draw_roads(canvas, camera, viewport)
	_draw_city_props(canvas, camera, viewport)


static func _draw_roads(canvas: CanvasItem, camera: Vector2, viewport: Vector2) -> void:
	var left := camera.x - viewport.x * 0.5
	var top := camera.y - viewport.y * 0.5
	var first_x := floori(left / 640.0) * 640
	var first_y := floori(top / 520.0) * 520
	for world_x in range(first_x - 640, first_x + int(viewport.x) + 1280, 640):
		var x := float(world_x) - camera.x + viewport.x * 0.5
		canvas.draw_rect(Rect2(x - 2.0, 0.0, 104.0, viewport.y), Color("#2b322e"))
		canvas.draw_rect(Rect2(x + 5.0, 0.0, 2.0, viewport.y), Color("#596055"))
		canvas.draw_rect(Rect2(x + 91.0, 0.0, 2.0, viewport.y), Color("#596055"))
		for y in range(32, int(viewport.y), 76):
			canvas.draw_rect(Rect2(x + 49.0, float(y), 2.0, 32.0), Color(0.60, 0.58, 0.49, 0.27))
	for world_y in range(first_y - 520, first_y + int(viewport.y) + 1040, 520):
		var y := float(world_y) - camera.y + viewport.y * 0.5
		canvas.draw_rect(Rect2(0.0, y - 2.0, viewport.x, 96.0), Color("#2b322e"))
		canvas.draw_rect(Rect2(0.0, y + 4.0, viewport.x, 2.0), Color("#596055"))
		canvas.draw_rect(Rect2(0.0, y + 82.0, viewport.x, 2.0), Color("#596055"))
		for x in range(30, int(viewport.x), 88):
			canvas.draw_rect(Rect2(float(x), y + 47.0, 34.0, 2.0), Color(0.60, 0.58, 0.49, 0.26))


static func _draw_city_props(canvas: CanvasItem, camera: Vector2, viewport: Vector2) -> void:
	var left := camera.x - viewport.x * 0.5
	var top := camera.y - viewport.y * 0.5
	var first_x := floori(left / 640.0) * 640
	var first_y := floori(top / 520.0) * 520
	for world_x in range(first_x - 640, first_x + int(viewport.x) + 1280, 640):
		for world_y in range(first_y - 520, first_y + int(viewport.y) + 1040, 520):
			var center := Vector2(float(world_x) + 320.0, float(world_y) + 260.0)
			if center.length() < 565.0:
				continue
			var seed := absi(world_x / 8 + world_y / 13)
			var anchor := center - camera + viewport * 0.5
			_draw_prop(canvas, 0, anchor + Vector2(-200.0, -145.0), Vector2(142.0, 126.0))
			_draw_prop(canvas, 1, anchor + Vector2(65.0, -175.0), Vector2(104.0, 64.0))
			_draw_prop(canvas, 2, anchor + Vector2(-245.0, 25.0), Vector2(34.0, 74.0))
			_draw_prop(canvas, 3, anchor + Vector2(130.0, 58.0), Vector2(82.0, 58.0))
			if seed % 2 == 0:
				_draw_prop(canvas, 4, anchor + Vector2(204.0, 168.0), Vector2(92.0, 98.0))
			if seed % 3 != 0:
				_draw_prop(canvas, 5, anchor + Vector2(-135.0, 192.0), Vector2(90.0, 52.0))


static func _draw_prop(canvas: CanvasItem, index: int, center: Vector2, size: Vector2) -> void:
	var source := Rect2(float(index % 3) * PROP_CELL.x, float(index / 3) * PROP_CELL.y, PROP_CELL.x, PROP_CELL.y)
	canvas.draw_texture_rect_region(PROPS, Rect2(center - size * 0.5, size), source)
