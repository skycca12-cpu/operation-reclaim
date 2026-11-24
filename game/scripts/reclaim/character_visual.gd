extends RefCounted

const SHEET: Texture2D = preload("res://assets/reclaim/characters/harin_sheet.png")
const FRONT_ATTACK = preload("res://assets/reclaim/characters/harin_front_recoil.png")
const FRONT_FRAME_SIZE := Vector2(112, 112)
const FRONT_FRAME_ORIGIN := Vector2(-56, -54)
const NORTH_ATTACK := preload("res://assets/reclaim/characters/harin_north_recoil.png")
const RUN_ATLAS := preload("res://assets/reclaim/characters/operator_run.png")
const NEW_FRAME := Vector2(128, 152)
const NEW_ORIGIN := Vector2(-64, -86)
const CELL_SIZE := 96.0
const DRAW_SIZE := 96.0
const STRIDE_STEP := 23.0
const MUZZLES := [Vector2(0, 18), Vector2(42, -1), Vector2(6, -42), Vector2(-42, 2)]
const ATTACK_HOLD := 0.16
const HURT_HOLD := 0.22

var walk_distance := 0.0
var attack_timer := 0.0
var shot_facing := Vector2.DOWN
var hurt_timer := 0.0
var last_hp := -1.0


func update(delta: float, motion: Vector2, hp: float, active: bool) -> void:
	if not active:
		return
	var speed := motion.length()
	walk_distance = walk_distance + minf(speed, 380.0) * delta if speed > 6.0 else 0.0
	attack_timer = maxf(0.0, attack_timer - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	if last_hp >= 0.0 and hp < last_hp - 0.01:
		hurt_timer = HURT_HOLD
	last_hp = hp


func trigger_attack(facing: Vector2) -> void:
	shot_facing = facing
	attack_timer = ATTACK_HOLD


func muzzle_offset(facing: Vector2) -> Vector2:
	var row := _facing_row(facing)
	return MUZZLES[row] + _side_recoil(row, 0)


func _front_shot_frame() -> int:
	# Frame zero is the ready pose. Firing starts with the compressed recoil pose.
	return 1 + clampi(int((1.0 - attack_timer / ATTACK_HOLD) * 3.0), 0, 2)


func _side_recoil(row: int, phase: int) -> Vector2:
	if row != 1 and row != 3:
		return Vector2.ZERO
	return Vector2(float(-4 + 2 * mini(phase, 2)) * (1.0 if row == 1 else -1.0), 0.0)


func draw(canvas: CanvasItem, center: Vector2, facing: Vector2, motion: Vector2, dashing: bool, reload_progress: float, echo := 0.0) -> void:
	var running := motion.length_squared() > 36.0
	var attack_row := _facing_row(shot_facing)
	var flash_duration := ATTACK_HOLD / 3.0 if attack_row == 0 or attack_row == 2 else ATTACK_HOLD / 4.0
	var flash := echo == 0.0 and attack_timer > ATTACK_HOLD - flash_duration
	var shooting := echo == 0.0 and attack_timer > 0.0 and (not running or flash)
	var display_facing := shot_facing if shooting else facing
	if running and not shooting:
		display_facing = motion
	var row := _facing_row(display_facing)
	var run_frame := int(walk_distance / STRIDE_STEP) % 4
	var phase := clampi(int((1.0 - attack_timer / ATTACK_HOLD) * 4.0), 0, 3) if shooting else 0
	var tint := Color(0.33, 0.27, 0.51, echo) if echo > 0.0 else Color(1.0, 0.72, 0.72) if hurt_timer > 0.0 else Color.WHITE
	if shooting and row == 0:
		var frame := _front_shot_frame()
		canvas.draw_texture_rect_region(FRONT_ATTACK, Rect2(center + FRONT_FRAME_ORIGIN, FRONT_FRAME_SIZE),
			Rect2(Vector2(frame * FRONT_FRAME_SIZE.x, 0), FRONT_FRAME_SIZE), tint)
	elif shooting and row == 2:
		var frame := _front_shot_frame()
		canvas.draw_texture_rect_region(NORTH_ATTACK, Rect2(center + NEW_ORIGIN, NEW_FRAME),
			Rect2(Vector2(frame * NEW_FRAME.x, 0), NEW_FRAME), tint)
	elif running and not shooting:
		var run_row := 0 if row == 0 else 1 if row == 2 else 2
		var flip := Vector2(-1, 1) if row == 3 else Vector2.ONE
		canvas.draw_set_transform(center.round(), 0.0, flip)
		canvas.draw_texture_rect_region(RUN_ATLAS, Rect2(NEW_ORIGIN, NEW_FRAME),
			Rect2(Vector2(run_frame, run_row) * NEW_FRAME, NEW_FRAME), tint)
		canvas.draw_set_transform(Vector2.ZERO)
	else:
		var column := 5 + phase if shooting else 9 + clampi(int(reload_progress * 4.0), 0, 3) if reload_progress >= 0.0 else 0
		var origin := center - Vector2.ONE * DRAW_SIZE * 0.5
		if shooting:
			origin += _side_recoil(row, phase)
		canvas.draw_texture_rect_region(SHEET, Rect2(origin, Vector2.ONE * DRAW_SIZE),
			Rect2(Vector2(column, row) * CELL_SIZE, Vector2.ONE * CELL_SIZE), tint)
	if flash:
		var flash_direction := [Vector2.DOWN, Vector2.RIGHT, Vector2.UP, Vector2.LEFT][row] as Vector2
		_draw_flash(canvas, center + muzzle_offset(shot_facing), flash_direction, flash_duration)
	if dashing:
		var dash_direction := (motion if running else facing).normalized()
		canvas.draw_line(center - dash_direction * 27.0, center - dash_direction * 11.0, Color("#9dd9e6", 0.7), 2.0)



func _draw_flash(canvas: CanvasItem, muzzle: Vector2, direction: Vector2, duration: float) -> void:
	var normal := direction.orthogonal()
	var age := (ATTACK_HOLD - attack_timer) / duration
	var length := lerpf(30.0, 9.0, age)
	canvas.draw_colored_polygon(PackedVector2Array([
		muzzle - direction * 3.0, muzzle + direction * 5.0 + normal * 7.0,
		muzzle + direction * 8.0 + normal * 2.0, muzzle + direction * length,
		muzzle + direction * 8.0 - normal * 2.0, muzzle + direction * 4.0 - normal * 6.0,
	]), Color("#ff8e28"))
	canvas.draw_colored_polygon(PackedVector2Array([
		muzzle, muzzle + direction * 5.0 + normal * 3.0,
		muzzle + direction * length * 0.7, muzzle + direction * 5.0 - normal * 3.0,
	]), Color("#fff5b4"))

	if age < 0.7:
		for side in [-1.0, 1.0]:
			var spark: Vector2 = muzzle + direction * (13.0 + age * 21.0) + normal * side * (8.0 + age * 8.0)
			canvas.draw_line(spark, spark + direction * 4.0, Color(1.0, 0.68, 0.22, 1.0 - age), 2.0)


func _facing_row(facing: Vector2) -> int:
	if absf(facing.x) > absf(facing.y):
		return 3 if facing.x < 0.0 else 1
	return 0 if facing.y >= 0.0 else 2
