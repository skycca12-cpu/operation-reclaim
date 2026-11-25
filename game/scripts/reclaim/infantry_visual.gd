extends RefCounted

const OperatorRun = preload("res://scripts/reclaim/operator_run.gd")

const SHEETS := {
	"tae": preload("res://assets/reclaim/characters/taejun_combat.png"),
	"si": preload("res://assets/reclaim/characters/sihyeok_combat.png"),
}
const SHIELD_CHARGE := preload("res://assets/reclaim/characters/taejun_shield_charge.png")
const FRAME := Vector2(128, 152)
const ORIGIN := Vector2(-64, -86)
const SHOT_TIME := 0.12
const FLASH_TIME := 0.045
const MUZZLES := {
	"tae": [Vector2(-24, 27), Vector2(26, -44), Vector2(53, -10)],
	"si": [Vector2(0, 33), Vector2(1, -44), Vector2(34, -7)],
}

var _distance := 0.0
var _shot_time := 0.0
var _shot_facing := Vector2.DOWN


func update(delta: float, motion: Vector2) -> void:
	var speed := motion.length()
	_distance = _distance + minf(speed, 380.0) * delta if speed > 6.0 else 0.0
	_shot_time = maxf(0.0, _shot_time - delta)


func attack(facing: Vector2) -> void:
	_shot_facing = facing
	_shot_time = SHOT_TIME


func muzzle(kind: String, facing: Vector2) -> Vector2:
	var row := _row(facing)
	var offset: Vector2 = MUZZLES[kind][row]
	if row == 2 and facing.x < 0.0:
		offset.x = -offset.x
	return offset


func _row(facing: Vector2) -> int:
	return 2 if absf(facing.x) > absf(facing.y) else 1 if facing.y < 0.0 else 0


func draw_shield_charge(canvas: CanvasItem, position: Vector2, direction: Vector2, tint: Color, draw_scale := 1.0) -> void:
	var row := _row(direction)
	var flip := Vector2(-1, 1) if row == 2 and direction.x < 0.0 else Vector2.ONE
	canvas.draw_set_transform(position.round(), 0.0, flip * draw_scale)
	canvas.draw_texture_rect_region(SHIELD_CHARGE, Rect2(ORIGIN, FRAME), Rect2(Vector2(row, 0) * FRAME, FRAME), tint)
	canvas.draw_set_transform(Vector2.ZERO)

func draw(canvas: CanvasItem, screen_position: Vector2, kind: String, facing: Vector2, motion: Vector2, dashing: bool, echo := 0.0, draw_scale := 1.0) -> void:
	var position := Vector2.ZERO
	var base := Transform2D(0.0, Vector2.ONE * draw_scale, 0.0, screen_position.round())
	canvas.draw_set_transform_matrix(base)
	var moving := motion.length_squared() > 36.0
	var flash := echo == 0.0 and _shot_time > SHOT_TIME - FLASH_TIME
	var firing := echo == 0.0 and _shot_time > 0.0 and (not moving or flash)
	var direction := _shot_facing if firing else motion if moving else facing
	var row := _row(direction)
	var column := 3 if firing else 0
	var flip := Vector2(-1, 1) if row == 2 and direction.x < 0.0 else Vector2.ONE
	if dashing:
		canvas.draw_circle(position, 24.0, Color("#739de33b"))
	canvas.draw_set_transform_matrix(base * Transform2D(0.0, Vector2(1.0, 0.35), 0.0, Vector2(0, 38)))
	if echo == 0.0:
		canvas.draw_circle(Vector2.ZERO, 16.0, Color("#00000062"))
	var tint := Color(0.33, 0.27, 0.51, echo) if echo > 0.0 else Color.WHITE
	if moving and not firing:
		OperatorRun.draw(canvas, screen_position, kind, motion, _distance, tint, draw_scale)
	else:
		canvas.draw_set_transform_matrix(base * Transform2D(0.0, flip, 0.0, Vector2.ZERO))
		canvas.draw_texture_rect_region(SHEETS[kind], Rect2(ORIGIN, FRAME), Rect2(Vector2(column, row) * FRAME, FRAME), tint)
	canvas.draw_set_transform_matrix(base)
	if flash:
		var beam := Vector2.DOWN if row == 0 else Vector2.UP if row == 1 else Vector2(signf(direction.x), 0)
		var tip := position + muzzle(kind, direction)
		var side := beam.orthogonal()
		var reach := 23.0 if kind == "tae" else 18.0
		canvas.draw_colored_polygon(PackedVector2Array([
			tip, tip + beam * 5.0 + side * 6.0, tip + beam * reach, tip + beam * 5.0 - side * 6.0,
		]), Color("#ffae4a"))
		canvas.draw_line(tip, tip + beam * reach * 0.62, Color("#fff1b4"), 2.0)
	canvas.draw_set_transform(Vector2.ZERO)
