extends RefCounted

const SIDE := 60
const CELL := 48.0
const EXTENT := SIDE * CELL
const GROUND := preload("res://assets/reclaim/flat_arena_asphalt.png")
const GROUND_SHADER := preload("res://assets/reclaim/flat_arena_ground.gdshader")

var bounds := Rect2(Vector2.ONE * (-EXTENT * 0.5), Vector2.ONE * EXTENT)


func walkable(point: Vector2, margin := 0.0) -> bool:
	return bounds.grow(-margin).has_point(point)


func nearest_land(point: Vector2, margin: float) -> Vector2:
	# Stay inside the right and bottom edges, which Rect2 excludes.
	var interior := bounds.grow(-margin - 0.01)
	return point.clamp(interior.position, interior.end)


func camera_center(focus: Vector2, viewport: Vector2, zoom: float) -> Vector2:
	var half_view := (viewport / (zoom * 2.0)).min(bounds.size * 0.5)
	return focus.clamp(bounds.position + half_view, bounds.end - half_view)


func create_background() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = GROUND
	sprite.centered = false
	sprite.show_behind_parent = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	sprite.material = material
	return sprite


func align_background(sprite: Sprite2D, focus: Vector2, viewport: Vector2, zoom: float) -> void:
	sprite.position = viewport * 0.5 + (bounds.position - camera_center(focus, viewport, zoom)) * zoom
	sprite.scale = bounds.size / GROUND.get_size() * zoom
