extends RefCounted

const SHEET: Texture2D = preload("res://assets/reclaim/characters/harin_sheet.png")
const CELL_SIZE := 96.0
const DRAW_SIZE := 96.0
const RUN_FPS := 11.0
const FLASH_HOLD := 0.078
const MUZZLES := [Vector2(34, 4), Vector2(42, -1), Vector2(-35, 2), Vector2(-42, 2)]
const ATTACK_HOLD := 0.16
const HURT_HOLD := 0.22

var walk_clock := 0.0
var attack_timer := 0.0
var shot_facing := Vector2.DOWN
var hurt_timer := 0.0
var last_hp := -1.0
var drone_clock := 0.0


func update(delta: float, motion: Vector2, hp: float, active: bool) -> void:
	if not active:
		return
	walk_clock = walk_clock + delta if motion.length_squared() > 36.0 else 0.0
	attack_timer = maxf(0.0, attack_timer - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	drone_clock += delta
	if last_hp >= 0.0 and hp < last_hp - 0.01:
		hurt_timer = HURT_HOLD
	last_hp = hp


func trigger_attack(facing: Vector2) -> void:
	shot_facing = facing
	attack_timer = ATTACK_HOLD


func muzzle_offset(facing: Vector2) -> Vector2:
	var row := _facing_row(facing)
	return MUZZLES[row] + Vector2(0, _run_lift(walk_clock > 0.0))


func _run_lift(running: bool) -> float:
	return -roundf(5.0 * absf(sin(walk_clock * RUN_FPS * PI * 0.5))) if running else 0.0


func draw(canvas: CanvasItem, center: Vector2, facing: Vector2, moving: bool, dashing: bool, drone_level: int, reload_progress: float) -> void:
	var shooting := attack_timer > 0.0
	var row := _facing_row(shot_facing if shooting else facing)
	var running := moving or dashing
	var run_frame := 1 + int(walk_clock * RUN_FPS * (1.45 if dashing else 1.0)) % 4
	var column := run_frame if running else 0
	if shooting:
		column = 5 + clampi(int((1.0 - attack_timer / ATTACK_HOLD) * 4.0), 0, 3)
	elif reload_progress >= 0.0:
		column = 9 + clampi(int(reload_progress * 4.0), 0, 3)
	var origin := center - Vector2.ONE * DRAW_SIZE * 0.5 + Vector2(0, _run_lift(running))
	var source := Rect2(Vector2(column, row) * CELL_SIZE, Vector2.ONE * CELL_SIZE)
	var tint := Color(1.0, 0.72, 0.72) if hurt_timer > 0.0 else Color.WHITE
	if running and shooting:
		# Keep the firing pose above the waist while the stride continues below it.
		const SPLIT := 71.0
		var upper := Vector2(CELL_SIZE, SPLIT)
		var lower := Vector2(CELL_SIZE, CELL_SIZE - SPLIT)
		canvas.draw_texture_rect_region(SHEET, Rect2(origin, upper), Rect2(source.position, upper), tint)
		var lower_offset := Vector2(0, SPLIT)
		canvas.draw_texture_rect_region(SHEET, Rect2(origin + lower_offset, lower), Rect2(Vector2(run_frame, row) * CELL_SIZE + lower_offset, lower), tint)
	else:
		canvas.draw_texture_rect_region(SHEET, Rect2(origin, Vector2.ONE * DRAW_SIZE), source, tint)
	if attack_timer > ATTACK_HOLD - FLASH_HOLD:
		var barrel: Vector2 = MUZZLES[row]
		_draw_flash(canvas, center + Vector2(0, _run_lift(running)) + barrel, Vector2(signf(barrel.x), 0))
	if dashing:
		canvas.draw_line(center - facing.normalized() * 27.0, center - facing.normalized() * 11.0, Color("#9dd9e6", 0.7), 2.0)
	if drone_level > 0:
		_draw_support_drone(canvas, center, drone_level)


func _draw_flash(canvas: CanvasItem, muzzle: Vector2, direction: Vector2) -> void:
	var normal := direction.orthogonal()
	var age := (ATTACK_HOLD - attack_timer) / FLASH_HOLD
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


func _draw_support_drone(canvas: CanvasItem, center: Vector2, level: int) -> void:
	var orbit := Vector2(cos(drone_clock * 2.2), sin(drone_clock * 2.2) * 0.55) * (31.0 + float(level) * 2.0)
	var p := center + orbit + Vector2(0.0, -19.0)
	canvas.draw_rect(Rect2(p - Vector2(4.0, 3.0), Vector2(8.0, 6.0)), Color("#72cbd5"))
	canvas.draw_rect(Rect2(p - Vector2(7.0, 1.0), Vector2(3.0, 2.0)), Color("#d3ebdc"))
	canvas.draw_rect(Rect2(p + Vector2(4.0, -1.0), Vector2(3.0, 2.0)), Color("#d3ebdc"))
