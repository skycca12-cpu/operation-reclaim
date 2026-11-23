extends RefCounted

const SHEETS: Array[Texture2D] = [
	preload("res://assets/reclaim/zombies/zombie_01_male.png"),
	preload("res://assets/reclaim/zombies/zombie_02_female.png"),
	preload("res://assets/reclaim/zombies/zombie_03_office.png"),
	preload("res://assets/reclaim/zombies/zombie_04_hoodie.png"),
	preload("res://assets/reclaim/zombies/zombie_05_worker.png"),
	preload("res://assets/reclaim/zombies/zombie_06_police.png"),
	preload("res://assets/reclaim/zombies/zombie_07_soldier.png"),
	preload("res://assets/reclaim/zombies/zombie_08_elderly.png"),
]
const CELL := 160.0
# 128 opaque pixels become ~50 world pixels. Harin's standing art is 80–86 px.
const SCALE := 0.39
const RADIUS := 14.0
const ATTACK_TIME := 0.6
const HIT_TIME := 0.4
# The supplied last death cell (column 27) is fully transparent in every row.
const DEATH_FRAMES := 5
const DEATH_FPS := 9.0
const DEATH_TIME := float(DEATH_FRAMES) / DEATH_FPS


static func facing_row(motion: Vector2) -> int:
	if absf(motion.x) > absf(motion.y):
		return 1 if motion.x < 0.0 else 2
	return 0 if motion.y >= 0.0 else 3


static func start_attack(enemy: Dictionary, toward: Vector2, now: float) -> void:
	enemy.attack_until = now + ATTACK_TIME
	enemy.attack_direction = toward.normalized() if not toward.is_zero_approx() else Vector2.DOWN


static func draw_alive(canvas: CanvasItem, enemy: Dictionary, center: Vector2, now: float, camera: Transform2D) -> void:
	var phase := now + float(int(enemy.spawn_id) % 31) * 0.063
	if now < float(enemy.attack_until):
		var progress := 1.0 - (float(enemy.attack_until) - now) / ATTACK_TIME
		_draw_attack(canvas, enemy, center, clampf(progress, 0.0, 1.0), camera)
	elif now < float(enemy.hit_until):
		var column := 18 + clampi(int((now + HIT_TIME - float(enemy.hit_until)) * 10.0), 0, 3)
		_draw_frame(canvas, enemy.variant, enemy.row, column, center)
	elif enemy.moving:
		_draw_walk(canvas, enemy, center, phase, camera)
	else:
		_draw_frame(canvas, enemy.variant, enemy.row, int(phase * 5.0) % 4, center)


static func _draw_walk(canvas: CanvasItem, enemy: Dictionary, center: Vector2, phase: float, camera: Transform2D) -> void:
	const LEG_START := 113.0
	var stride := sin(phase * TAU * 2.1)
	var source := Vector2(4 + int(phase * 9.0) % 8, enemy.row) * CELL
	var top_left := -Vector2(80.0, 86.0) * SCALE
	var bob := -absf(stride) * 2.0
	var sheet := SHEETS[enemy.variant]
	var upper_size := Vector2(CELL, LEG_START)
	canvas.draw_set_transform_matrix(camera * Transform2D(stride * 0.042, center + Vector2(stride * 1.2, bob)))
	canvas.draw_texture_rect_region(sheet, Rect2(top_left, upper_size * SCALE), Rect2(source, upper_size))
	var side_view: bool = enemy.row == 1 or enemy.row == 2
	for leg in range(2):
		var step := stride if leg == 0 else -stride
		var left := float(leg) * CELL * 0.5
		var knee := top_left + Vector2(left + CELL * 0.25, LEG_START) * SCALE
		var leg_size := Vector2(CELL * 0.5, CELL - LEG_START)
		var lift := maxf(step, 0.0) * 3.0
		var swing := step * (0.22 if side_view else 0.10)
		canvas.draw_set_transform_matrix(camera * Transform2D(swing, center + knee + Vector2(stride * 1.2, bob - lift)))
		canvas.draw_texture_rect_region(sheet, Rect2(Vector2(-CELL * 0.25 * SCALE, 0.0), leg_size * SCALE),
			Rect2(source + Vector2(left, LEG_START), leg_size))
	canvas.draw_set_transform_matrix(camera)


static func _draw_attack(canvas: CanvasItem, enemy: Dictionary, center: Vector2, progress: float, camera: Transform2D) -> void:
	var direction: Vector2 = enemy.attack_direction
	var strike := 1.0 - smoothstep(0.17, 0.9, progress)
	var advance := 10.0 * strike
	var attack_center := center + direction * advance
	var column := 12 + mini(int(progress * 6.0), 5)
	canvas.draw_set_transform_matrix(camera * Transform2D(direction.x * strike * 0.20,
		Vector2(1.0 + strike * 0.13, 1.0 - strike * 0.06), 0.0, attack_center))
	_draw_frame(canvas, enemy.variant, facing_row(direction), column, Vector2.ZERO)
	canvas.draw_set_transform_matrix(camera)
	if progress < 0.28:
		var swing_center := center + direction * 16.0 + Vector2(0.0, -6.0)
		var angle := direction.angle()
		var opacity := (1.0 - progress / 0.28) * 0.66
		canvas.draw_arc(swing_center, 9.0, angle - 0.78, angle + 0.78, 8, Color(0.88, 0.84, 0.69, opacity), 1.5, true)


static func draw_dead(canvas: CanvasItem, corpse: Dictionary, center: Vector2, now: float) -> void:
	var frame := clampi(int((now - float(corpse.start)) * DEATH_FPS), 0, DEATH_FRAMES - 1)
	_draw_frame(canvas, corpse.variant, corpse.row, 22 + frame, center)


static func _draw_frame(canvas: CanvasItem, variant: int, row: int, column: int, center: Vector2) -> void:
	var source := Rect2(Vector2(column, row) * CELL, Vector2.ONE * CELL)
	var destination := Rect2(center - Vector2(80.0, 86.0) * SCALE, Vector2.ONE * CELL * SCALE)
	canvas.draw_texture_rect_region(SHEETS[variant], destination, source)
