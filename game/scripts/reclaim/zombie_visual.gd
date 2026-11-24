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
const ATTACK_PARTS: Texture2D = preload("res://assets/reclaim/zombies/attack_parts.png")
# Left and right pivots follow each original garment seam.
const SHOULDERS := [
	[Vector2(62, 85), Vector2(98, 85)], [Vector2(62, 87), Vector2(98, 87)],
	[Vector2(60, 87), Vector2(102, 87)], [Vector2(59, 87), Vector2(103, 87)],
	[Vector2(62, 82), Vector2(98, 82)], [Vector2(61, 86), Vector2(101, 86)],
	[Vector2(61, 88), Vector2(102, 88)], [Vector2.ZERO, Vector2(103, 87)],
]
const ELBOWS := [
	[Vector2(56, 103), Vector2(104, 103)], [Vector2(55, 104), Vector2(105, 103)],
	[Vector2(54, 106), Vector2(108, 106)], [Vector2(54, 106), Vector2(108, 106)],
	[Vector2(55, 102), Vector2(104, 102)], [Vector2(54, 105), Vector2(109, 105)],
	[Vector2(53, 105), Vector2(109, 105)], [Vector2.ZERO, Vector2(111, 108)],
]
# Eight beats from the reference: rest, brace, raise, high guard, impact, follow-through, recover, rest.
const POSES := [
	Vector3(0.0, 0.0, 0.0), Vector3(0.28, 0.38, 0.4), Vector3(0.66, 0.57, -0.5),
	Vector3(1.0, 0.32, -2.0), Vector3(0.39, 0.45, 4.0), Vector3(0.47, 0.36, 3.0),
	Vector3(0.18, 0.18, 1.5), Vector3(0.0, 0.0, 0.0),
]
const SPRITE_CENTER := Vector2(80.0, 86.0)
const CELL := 160.0
# The 126 px standing silhouette becomes ~86 world pixels.
const SCALE := 0.68
const RADIUS := 21.0
const ATTACK_TIME := 0.6
const IMPACT_TIME := ATTACK_TIME * 4.0 / 8.0
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


static func draw_alive(canvas: CanvasItem, enemy: Dictionary, center: Vector2, now: float, camera: Transform2D, tint := Color.WHITE, compact := false) -> void:
	var phase := now + float(int(enemy.spawn_id) % 31) * 0.063
	if now < float(enemy.attack_until):
		var progress := 1.0 - (float(enemy.attack_until) - now) / ATTACK_TIME
		_draw_attack(canvas, enemy, center, clampf(progress, 0.0, 1.0), camera, tint)
	elif now < float(enemy.hit_until):
		var column := 18 + clampi(int((now + HIT_TIME - float(enemy.hit_until)) * 10.0), 0, 3)
		var impact := clampf((float(enemy.hit_until) - now - HIT_TIME + 0.09) / 0.09, 0.0, 1.0)
		var hit_tint := tint * Color.WHITE.lerp(Color("#ffb4a3"), impact)
		_draw_frame(canvas, enemy.variant, enemy.row, column, center, hit_tint)
	elif enemy.moving and compact:
		var gait := int(fposmod(float(enemy.walk_distance) / 30.0, 1.0) * 8.0)
		_draw_frame(canvas, enemy.variant, enemy.row, 4 + gait, center, tint)
	elif enemy.moving:
		_draw_walk(canvas, enemy, center, camera, tint)
	else:
		_draw_frame(canvas, enemy.variant, enemy.row, int(phase * 5.0) % 4, center, tint)


static func _draw_walk(canvas: CanvasItem, enemy: Dictionary, center: Vector2, camera: Transform2D, tint: Color) -> void:
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
	canvas.draw_texture_rect_region(sheet, Rect2(top_left, upper_size * SCALE), Rect2(source, upper_size), tint)
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
			Rect2(source + Vector2(left, LEG_START), leg_size), tint)
	canvas.draw_set_transform_matrix(camera)


static func _draw_attack(canvas: CanvasItem, enemy: Dictionary, center: Vector2, progress: float, camera: Transform2D, tint: Color) -> void:
	var direction: Vector2 = enemy.attack_direction
	var variant: int = enemy.variant
	var row := facing_row(direction)
	var mirror := -1.0 if row == 1 else 1.0
	var phase := minf(progress * 8.0, 7.0)
	var pose: Vector3 = POSES[int(phase)].lerp(POSES[mini(int(phase) + 1, 7)], fposmod(phase, 1.0))
	var lean := direction * maxf(0.0, pose.z) * 0.65 + Vector2(0.0, pose.z)
	var compression := 1.0 - maxf(0.0, pose.z) * 0.018
	var body := camera * Transform2D(direction.x * pose.z * 0.012,
		Vector2(mirror, compression), 0.0, center + lean)
	var cell_rect := Rect2(-SPRITE_CENTER * SCALE, Vector2.ONE * CELL * SCALE)
	var source := Rect2(Vector2(variant * CELL, 0.0), Vector2.ONE * CELL)
	if row != 0:
		_draw_attack_arm(canvas, body, variant, 0, direction, mirror, pose, tint)
	canvas.draw_set_transform_matrix(body)
	canvas.draw_texture_rect_region(ATTACK_PARTS, cell_rect, source, tint)
	if row == 0:
		_draw_attack_arm(canvas, body, variant, 0, direction, mirror, pose, tint)
	_draw_attack_arm(canvas, body, variant, 1, direction, mirror, pose, tint)
	canvas.draw_set_transform_matrix(camera)


static func _draw_attack_arm(canvas: CanvasItem, body: Transform2D, variant: int, arm: int,
		direction: Vector2, mirror: float, pose: Vector3, tint: Color) -> void:
	if variant == 7 and arm == 0:
		return
	var shoulder: Vector2 = SHOULDERS[variant][arm]
	var elbow: Vector2 = ELBOWS[variant][arm]
	var side := -1.0 if arm == 0 else 1.0
	var aimed := Vector2(direction.x * mirror, direction.y)
	var aim_angle := angle_difference(PI * 0.5, aimed.angle())
	# Fan both sleeves out around the head during the wind-up, then turn toward impact.
	var raised := -side * (PI - 0.43)
	var lift := smoothstep(0.48, 0.94, pose.x)
	var extension := lerpf(aim_angle, raised, lift)
	var angle := extension * minf(1.0, pose.x * 2.2)
	if absf(direction.y) > absf(direction.x):
		angle += side * pose.y * 1.15 * (1.0 - lift)
	var upper := body * Transform2D(angle, (shoulder - SPRITE_CENTER) * SCALE)
	var lower := upper * Transform2D(side * pose.y * 0.9 * (1.0 - lift),
		Vector2.ONE * (1.0 + maxf(0.0, pose.z) * 0.035), 0.0, (elbow - shoulder) * SCALE)
	var size := Vector2.ONE * CELL * SCALE
	var cell := Vector2.ONE * CELL
	var source := Vector2(variant * CELL, (1 + arm * 2) * CELL)
	canvas.draw_set_transform_matrix(upper)
	canvas.draw_texture_rect_region(ATTACK_PARTS, Rect2(-shoulder * SCALE, size), Rect2(source, cell), tint)
	canvas.draw_set_transform_matrix(lower)
	canvas.draw_texture_rect_region(ATTACK_PARTS, Rect2(-elbow * SCALE, size), Rect2(source + Vector2(0.0, CELL), cell), tint)


static func draw_dead(canvas: CanvasItem, corpse: Dictionary, center: Vector2, now: float) -> void:
	var frame := clampi(int((now - float(corpse.start)) * DEATH_FPS), 0, DEATH_FRAMES - 1)
	_draw_frame(canvas, corpse.variant, corpse.row, 22 + frame, center)


static func _draw_frame(canvas: CanvasItem, variant: int, row: int, column: int, center: Vector2, tint := Color.WHITE) -> void:
	var source := Rect2(Vector2(column, row) * CELL, Vector2.ONE * CELL)
	var destination := Rect2(center - SPRITE_CENTER * SCALE, Vector2.ONE * CELL * SCALE)
	canvas.draw_texture_rect_region(SHEETS[variant], destination, source, tint)
