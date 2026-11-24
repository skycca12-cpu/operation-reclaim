extends RefCounted

const NormalVisual = preload("res://scripts/reclaim/normal_zombie_visual.gd")

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
const SPRITE_CENTER := Vector2(80.0, 86.0)
const CELL := 160.0
# The 126 px standing silhouette becomes ~86 world pixels.
const SCALE := 0.68
const RADIUS := 21.0
const ATTACK_TIME := 0.6
const ATTACK_BEATS := 8
const IMPACT_TIME := ATTACK_TIME * 4.0 / ATTACK_BEATS
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
	if enemy.kind == "normal":
		_draw_normal(canvas, enemy, center, now, camera, tint)
		return
	var phase := now + float(int(enemy.spawn_id) % 31) * 0.063
	if now < float(enemy.attack_until):
		_draw_attack(canvas, enemy, center, now, tint)
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


static func _draw_normal(canvas: CanvasItem, enemy: Dictionary, center: Vector2, now: float, camera: Transform2D, tint: Color) -> void:
	var hit_age := now + HIT_TIME - float(enemy.hit_until)
	var being_hit := now < float(enemy.hit_until)
	if now < float(enemy.attack_until):
		_draw_attack(canvas, enemy, center, now,
			NormalVisual.impact_tint(enemy, hit_age, tint) if being_hit else tint)
		return
	var stride := fposmod(float(enemy.walk_distance) / 30.0, 1.0)
	var row := int(enemy.row)
	var walk_column := 39 + row * 4 + int(stride * 4.0)
	if being_hit and row == 0:
		NormalVisual.reaction(canvas, enemy, center, maxf(0.0, hit_age), tint)
		return
	var column := walk_column if enemy.moving or row != 0 else int(now * 5.0 + float(enemy.spawn_id)) % 2
	if being_hit:
		NormalVisual.directional_reaction(canvas, enemy, column, center, camera, hit_age, tint)
	else:
		NormalVisual.frame(canvas, enemy.appearance, column, center, tint)


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


static func _draw_attack(canvas: CanvasItem, enemy: Dictionary, center: Vector2, now: float, tint: Color) -> void:
	var row := facing_row(enemy.attack_direction)
	var progress := 1.0 - (float(enemy.attack_until) - now) / ATTACK_TIME
	var beat := clampi(int(progress * ATTACK_BEATS + 0.00001), 0, ATTACK_BEATS - 1)
	var column := 15 + row * 6 + beat - 1
	if beat == 0 or beat == ATTACK_BEATS - 1:
		column = 0 if row == 0 else 39 + row * 4
	NormalVisual.frame(canvas, int(enemy.get("appearance", enemy.variant)), column, center, tint)


static func draw_dead(canvas: CanvasItem, corpse: Dictionary, center: Vector2, now: float) -> void:
	var frame := clampi(int((now - float(corpse.start)) * DEATH_FPS), 0, DEATH_FRAMES - 1)
	if corpse.has("appearance"):
		NormalVisual.frame(canvas, corpse.appearance, 6 + frame, center, Color.WHITE, corpse.row == 1)
	else:
		_draw_frame(canvas, corpse.variant, corpse.row, 22 + frame, center)


static func _draw_frame(canvas: CanvasItem, variant: int, row: int, column: int, center: Vector2, tint := Color.WHITE) -> void:
	var source := Rect2(Vector2(column, row) * CELL, Vector2.ONE * CELL)
	var destination := Rect2(center - SPRITE_CENTER * SCALE, Vector2.ONE * CELL * SCALE)
	canvas.draw_texture_rect_region(SHEETS[variant], destination, source, tint)
