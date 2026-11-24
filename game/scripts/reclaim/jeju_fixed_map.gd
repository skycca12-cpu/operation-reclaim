extends RefCounted

const BACKGROUND := preload("res://assets/reclaim/jeju_v2/background.png")
const MAP_PATH := "res://assets/reclaim/jeju_v2/map.json"
const SCALE := 2.65
const HQ_WORLD := Vector2(24, 0)
const IMAGE_ORIGIN := HQ_WORLD - Vector2(768, 480) * SCALE

var bounds := Rect2(IMAGE_ORIGIN, BACKGROUND.get_size() * SCALE)
var build_bounds := Rect2()
var spawn_points := PackedVector2Array()
var _routes := PackedVector2Array()
var _outline := PackedVector2Array()
var _obstacles: Array[PackedVector2Array] = []
var _obstacle_bounds: Array[Rect2] = []


func setup() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	_outline = _polygon(data.walkable_union[0])
	# Extend the four lane seams into the arena before unioning them.
	# The east side of the source arena drifts by two pixels along its edge.
	var joins := [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]
	for i in range(joins.size()):
		var lane := _polygon(data.walkable_union[i + 1])
		var join: Vector2 = joins[i]
		var seam := -INF
		for point in lane:
			seam = maxf(seam, point.dot(join))
		for vertex in range(lane.size()):
			if is_equal_approx(lane[vertex].dot(join), seam):
				lane[vertex] += join * SCALE * 3.0
		var merged := Geometry2D.merge_polygons(_outline, lane)
		assert(merged.size() == 1, "Jeju lane is disconnected")
		_outline = merged[0]
	for points in data.obstacle_polygons:
		var obstacle := _polygon(points)
		_obstacles.append(obstacle)
		_obstacle_bounds.append(_polygon_bounds(obstacle))
	build_bounds = _polygon_bounds(_polygon(data.build_polygon))
	var entries := [Vector2(732, 260), Vector2(739, 750), Vector2(280, 451), Vector2(1180, 528), Vector2(768, 480), Vector2(768, 480), Vector2(768, 480), Vector2(1060, 640)]
	for i in range(data.spawn_candidates.size()):
		var point := _image_to_world(_point(data.spawn_candidates[i]))
		var entry := _image_to_world(entries[i])
		var spawn := nearest_land(point, 42.0)
		assert(_segment_clear(spawn, entry, 42.0) and _segment_clear(entry, HQ_WORLD, 42.0),
			"Jeju spawn %d lacks a ground route" % (i + 1))
		spawn_points.append(spawn)
		_routes.append(entry)


func _point(pair: Array) -> Vector2:
	return Vector2(float(pair[0]), float(pair[1]))


func _image_to_world(point: Vector2) -> Vector2:
	return IMAGE_ORIGIN + point * SCALE


func _polygon(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(_image_to_world(_point(point)))
	return result


func _polygon_bounds(polygon: PackedVector2Array) -> Rect2:
	var result := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		result = result.expand(point)
	return result


func _near_edge(point: Vector2, polygon: PackedVector2Array, margin: float) -> bool:
	for i in range(polygon.size()):
		var nearest := Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()])
		if point.distance_squared_to(nearest) < margin * margin:
			return true
	return false


func walkable(point: Vector2, margin: float = 0.0) -> bool:
	if not Geometry2D.is_point_in_polygon(point, _outline) or _near_edge(point, _outline, margin):
		return false
	for i in range(_obstacles.size()):
		if not _obstacle_bounds[i].grow(margin).has_point(point):
			continue
		if Geometry2D.is_point_in_polygon(point, _obstacles[i]) or _near_edge(point, _obstacles[i], margin):
			return false
	return true


func nearest_land(point: Vector2, margin: float) -> Vector2:
	if walkable(point, margin):
		return point
	# Search in rings, starting at the closest boundary for far-out legacy saves.
	var center := point
	if not Geometry2D.is_point_in_polygon(point, _outline):
		var best := INF
		for i in range(_outline.size()):
			var edge := Geometry2D.get_closest_point_to_segment(point, _outline[i], _outline[(i + 1) % _outline.size()])
			var distance := point.distance_squared_to(edge)
			if distance < best:
				best = distance
				center = edge
	for ring in range(1, 25):
		for direction in range(24):
			var candidate := center + Vector2.from_angle(direction * TAU / 24.0) * ring * 8.0
			if walkable(candidate, margin):
				return candidate
	return HQ_WORLD


func _segment_clear(start: Vector2, end: Vector2, margin: float) -> bool:
	var steps := maxi(1, ceili(start.distance_to(end) / 10.0))
	for i in range(steps + 1):
		if not walkable(start.lerp(end, float(i) / steps), margin):
			return false
	return true


func spawn_index(angle: float) -> int:
	var direction := Vector2.from_angle(angle)
	var best := -INF
	var chosen := 0
	for i in range(spawn_points.size()):
		var alignment := direction.dot(HQ_WORLD.direction_to(spawn_points[i]))
		if alignment > best:
			best = alignment
			chosen = i
	return chosen


func approach_point(spawn: Vector2) -> Vector2:
	var index := spawn_points.find(spawn)
	return _routes[index] if index >= 0 else HQ_WORLD


func camera_center(focus: Vector2, viewport: Vector2, zoom: float) -> Vector2:
	var half_view := (viewport / (zoom * 2.0)).min(bounds.size * 0.5)
	return focus.clamp(bounds.position + half_view, bounds.end - half_view)


func draw_background(canvas: CanvasItem, offset: Vector2) -> void:
	canvas.draw_texture_rect(BACKGROUND, Rect2(bounds.position + offset, bounds.size), false)
