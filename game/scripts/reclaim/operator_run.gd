extends RefCounted

const ATLAS := preload("res://assets/reclaim/characters/operator_run_cycle.png")
const FRAME := Vector2(128, 152)
const ORIGIN := Vector2(-64, -86)
const FRAMES_PER_CYCLE := 4
const STEP_DISTANCE := 20.0
const SIDE_STEP_DISTANCE := 26.0
const START_ROWS := {"harin": 0, "yujin": 3, "tae": 6, "si": 9}


static func frame_cell(hero: String, motion: Vector2, distance: float) -> Vector2i:
	var sideways := absf(motion.x) > absf(motion.y)
	var direction_row := 2 if sideways else 1 if motion.y < 0.0 else 0
	var row := int(START_ROWS[hero]) + direction_row
	var step := SIDE_STEP_DISTANCE if sideways else STEP_DISTANCE
	return Vector2i(int(distance / step) % FRAMES_PER_CYCLE, row)


static func draw(canvas: CanvasItem, center: Vector2, hero: String, motion: Vector2,
		distance: float, tint: Color) -> void:
	var cell := frame_cell(hero, motion, distance)
	var flip := Vector2(-1, 1) if absf(motion.x) > absf(motion.y) and motion.x < 0.0 else Vector2.ONE
	canvas.draw_set_transform(center.round(), 0.0, flip)
	canvas.draw_texture_rect_region(ATLAS, Rect2(ORIGIN, FRAME),
		Rect2(Vector2(cell) * FRAME, FRAME), tint)
	canvas.draw_set_transform(Vector2.ZERO)
