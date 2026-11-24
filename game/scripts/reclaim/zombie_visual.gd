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
		_draw_walk(canvas, enemy, center, camera)
	else:
		_draw_frame(canvas, enemy.variant, enemy.row, int(phase * 5.0) % 4, center)


static func _draw_walk(canvas: CanvasItem, enemy: Dictionary, center: Vector2, camera: Transform2D) -> void:
	const LEG_START := 113.0
	var gait := fposmod(float(enemy.walk_distance) / 30.0 + float(int(enemy.spawn_id) % 13) / 13.0, 1.0)
	var stride := sin(gait * TAU)
	var source := Vector2(4 + int(gait * 8.0), enemy.row) * CELL
	var top_left := -Vector2(80.0, 86.0) * SCALE
	var bob := -absf(stride) * 1.25
	var sheet := SHEETS[enemy.variant]
	var upper_size := Vector2(CELL, LEG_START)
	var body := camera * Transform2D(stride * 0.056, center + Vector2(stride * 1.35, bob))
	canvas.draw_set_transform_matrix(body)
	canvas.draw_texture_rect_region(sheet, Rect2(top_left, upper_size * SCALE), Rect2(source, upper_size))
	var side_view: bool = enemy.row == 1 or enemy.row == 2
	for leg in range(2):
		var step := stride if leg == 0 else -stride
		var left := float(leg) * CELL * 0.5
		var knee := top_left + Vector2(left + CELL * 0.25, LEG_START) * SCALE
		var leg_size := Vector2(CELL * 0.5, CELL - LEG_START)
		var lift := maxf(step, 0.0) * 2.1
		var swing := step * (0.29 if side_view else 0.14)
		canvas.draw_set_transform_matrix(body * Transform2D(swing, knee - Vector2(0.0, lift)))
		canvas.draw_texture_rect_region(sheet, Rect2(Vector2(-CELL * 0.25 * SCALE, 0.0), leg_size * SCALE),
			Rect2(source + Vector2(left, LEG_START), leg_size))
	canvas.draw_set_transform_matrix(camera)


static func _draw_attack(canvas: CanvasItem, enemy: Dictionary, center: Vector2, progress: float, camera: Transform2D) -> void:
	var direction: Vector2 = enemy.attack_direction
	var row := facing_row(direction)
	var strike := 1.0 - smoothstep(0.10, 0.74, progress)
	var column := 12 + mini(int(progress * 6.0), 5)
	canvas.draw_set_transform_matrix(camera * Transform2D(direction.x * strike * 0.055, center))
	_draw_frame(canvas, enemy.variant, row, column, Vector2.ZERO)
	canvas.draw_set_transform_matrix(camera)
	if strike <= 0.02:
		return
	# The temporary sheets keep the arms close to the body. Extend a visible
	# shoulder, elbow, forearm and open hand while the feet stay planted.
	var side := direction.orthogonal()
	if direction.y > 0.0 or direction.x < 0.0:
		side = -side
	var shoulder := center + side * 8.0 - Vector2(0, 5)
	var elbow := shoulder + direction * (3.0 + 6.0 * strike) + side * (4.0 - 2.0 * strike)
	var hand := shoulder + direction * (5.0 + 15.0 * strike) - side * (5.0 * strike)
	var sleeve := Color("#57534e")
	var skin := Color("#a9a68b")
	var outline := Color("#252522")
	canvas.draw_line(shoulder, elbow, outline, 7.0, true)
	canvas.draw_line(elbow, hand, outline, 6.0, true)
	canvas.draw_line(shoulder, elbow, sleeve, 4.0, true)
	canvas.draw_line(elbow, hand, skin.darkened(0.2), 3.5, true)
	canvas.draw_circle(hand, 2.8, skin, true)
	for finger in range(3):
		var spread := float(finger - 1)
		canvas.draw_line(hand + side * spread * 1.3, hand + direction * (3.5 + strike) + side * spread * 2.0,
			skin, 1.2, true)


static func draw_dead(canvas: CanvasItem, corpse: Dictionary, center: Vector2, now: float) -> void:
	var frame := clampi(int((now - float(corpse.start)) * DEATH_FPS), 0, DEATH_FRAMES - 1)
	_draw_frame(canvas, corpse.variant, corpse.row, 22 + frame, center)


static func _draw_frame(canvas: CanvasItem, variant: int, row: int, column: int, center: Vector2) -> void:
	var source := Rect2(Vector2(column, row) * CELL, Vector2.ONE * CELL)
	var destination := Rect2(center - Vector2(80.0, 86.0) * SCALE, Vector2.ONE * CELL * SCALE)
	canvas.draw_texture_rect_region(SHEETS[variant], destination, source)
