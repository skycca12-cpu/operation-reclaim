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
const JEJU_ENEMIES := {
	"S01": preload("res://assets/reclaim/zombies/jeju/S01.png"),
	"S02": preload("res://assets/reclaim/zombies/jeju/S02.png"),
	"S03": preload("res://assets/reclaim/zombies/jeju/S03.png"),
	"S04": preload("res://assets/reclaim/zombies/jeju/S04.png"),
	"S05": preload("res://assets/reclaim/zombies/jeju/S05.png"),
	"S06": preload("res://assets/reclaim/zombies/jeju/S06.png"),
	"S07": preload("res://assets/reclaim/zombies/jeju/S07.png"),
	"S08": preload("res://assets/reclaim/zombies/jeju/S08.png"),
	"S09": preload("res://assets/reclaim/zombies/jeju/S09.png"),
	"S10": preload("res://assets/reclaim/zombies/jeju/S10.png"),
	"S11": preload("res://assets/reclaim/zombies/jeju/S11.png"),
	"S12": preload("res://assets/reclaim/zombies/jeju/S12.png"),
	"S13": preload("res://assets/reclaim/zombies/jeju/S13.png"),
	"S14": preload("res://assets/reclaim/zombies/jeju/S14.png"),
	"S15": preload("res://assets/reclaim/zombies/jeju/S15.png"),
	"S16": preload("res://assets/reclaim/zombies/jeju/S16.png"),
	"S17": preload("res://assets/reclaim/zombies/jeju/S17.png"),
	"S18": preload("res://assets/reclaim/zombies/jeju/S18.png"),
	"S19": preload("res://assets/reclaim/zombies/jeju/S19.png"),
	"S20": preload("res://assets/reclaim/zombies/jeju/S20.png"),
	"boss20": preload("res://assets/reclaim/zombies/jeju/boss20.png"),
	"boss40": preload("res://assets/reclaim/zombies/jeju/boss40.png"),
	"boss60": preload("res://assets/reclaim/zombies/jeju/boss60.png"),
	"boss80": preload("res://assets/reclaim/zombies/jeju/boss80.png"),
	"boss100": preload("res://assets/reclaim/zombies/jeju/boss100.png"),
}
const JEJU_MOTION := {
	"S01": preload("res://assets/reclaim/zombies/jeju/motion/S01.png"),
	"S02": preload("res://assets/reclaim/zombies/jeju/motion/S02.png"),
	"S03": preload("res://assets/reclaim/zombies/jeju/motion/S03.png"),
	"S04": preload("res://assets/reclaim/zombies/jeju/motion/S04.png"),
	"S05": preload("res://assets/reclaim/zombies/jeju/motion/S05.png"),
	"S06": preload("res://assets/reclaim/zombies/jeju/motion/S06.png"),
	"S07": preload("res://assets/reclaim/zombies/jeju/motion/S07.png"),
	"S08": preload("res://assets/reclaim/zombies/jeju/motion/S08.png"),
	"S09": preload("res://assets/reclaim/zombies/jeju/motion/S09.png"),
	"S10": preload("res://assets/reclaim/zombies/jeju/motion/S10.png"),
	"S11": preload("res://assets/reclaim/zombies/jeju/motion/S11.png"),
	"S12": preload("res://assets/reclaim/zombies/jeju/motion/S12.png"),
	"S13": preload("res://assets/reclaim/zombies/jeju/motion/S13.png"),
	"S14": preload("res://assets/reclaim/zombies/jeju/motion/S14.png"),
	"S15": preload("res://assets/reclaim/zombies/jeju/motion/S15.png"),
	"S16": preload("res://assets/reclaim/zombies/jeju/motion/S16.png"),
	"S17": preload("res://assets/reclaim/zombies/jeju/motion/S17.png"),
	"S18": preload("res://assets/reclaim/zombies/jeju/motion/S18.png"),
	"S19": preload("res://assets/reclaim/zombies/jeju/motion/S19.png"),
	"S20": preload("res://assets/reclaim/zombies/jeju/motion/S20.png"),
	"boss20": preload("res://assets/reclaim/zombies/jeju/motion/boss20.png"),
	"boss40": preload("res://assets/reclaim/zombies/jeju/motion/boss40.png"),
	"boss60": preload("res://assets/reclaim/zombies/jeju/motion/boss60.png"),
	"boss80": preload("res://assets/reclaim/zombies/jeju/motion/boss80.png"),
	"boss100": preload("res://assets/reclaim/zombies/jeju/motion/boss100.png"),
}
const SPRITE_CENTER := Vector2(80.0, 86.0)
const CELL := 160.0
# The 126 px standing silhouette becomes ~86 world pixels.
const SCALE := 0.68
const RADIUS := 21.0
const DRAW_SCALE := 0.5
const ATTACK_TIME := 0.6
const ATTACK_BEATS := 8
const IMPACT_BEAT := 4
const IMPACT_TIME := ATTACK_TIME * IMPACT_BEAT / ATTACK_BEATS
const HIT_TIME := 0.4
const RECOIL_TIME := 0.14
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
	if enemy.kind == "S02":
		_draw_armored(canvas, enemy, center, now, tint)
		return
	if enemy.kind == "S11":
		_draw_siege(canvas, enemy, center, now, camera, tint)
		return
	if JEJU_ENEMIES.has(enemy.kind):
		_draw_jeju(canvas, enemy, center, now, camera, tint)
		return
	if enemy.kind == "normal":
		_draw_normal(canvas, enemy, center, now, tint)
		return
	var phase := now + float(int(enemy.spawn_id) % 31) * 0.063
	if now < float(enemy.attack_until):
		_draw_attack(canvas, enemy, center, now, tint)
	elif now < float(enemy.hit_until) - HIT_TIME + RECOIL_TIME:
		NormalVisual.frame(canvas, int(enemy.get("appearance", enemy.variant)), 11 + int(enemy.row), center, tint)
	elif enemy.moving and compact:
		var gait := int(fposmod(float(enemy.walk_distance) / 30.0, 1.0) * 8.0)
		_draw_frame(canvas, enemy.variant, enemy.row, 4 + gait, center, tint)
	elif enemy.moving:
		_draw_walk(canvas, enemy, center, camera, tint)
	else:
		_draw_frame(canvas, enemy.variant, enemy.row, int(phase * 5.0) % 4, center, tint)


const ARMORED_POSES := preload("res://assets/reclaim/zombies/jeju/motion/S02_directional.png")
const ARMORED_CELL := Vector2(352, 192)
const SIEGE_CELL := Vector2(192, 192)
const POSE_SCALE := 82.0 / 154.0
const POSE_FOOT := 178.0


static func _draw_armored(canvas: CanvasItem, enemy: Dictionary, center: Vector2, now: float, tint: Color) -> void:
	var row := int(enemy.row)
	var frame := 0
	var attack_end := float(enemy.attack_until)
	if now < attack_end:
		row = facing_row(enemy.attack_direction)
		if not enemy.has("strike_remaining") and now < attack_end - 0.10:
			frame = 3
	elif enemy.moving:
		const STEPS := [1, 0, 2, 0]
		frame = STEPS[int(fposmod(float(enemy.walk_distance), 26.0) / 6.5)]
	var tier := injury_tier(float(enemy.hp), float(enemy.max_hp))
	_pose_frame(canvas, ARMORED_POSES, ARMORED_CELL, frame, tier * 4 + row, center + Vector2(0, 30), tint)


static func _draw_siege(canvas: CanvasItem, enemy: Dictionary, center: Vector2, now: float, camera: Transform2D, tint: Color) -> void:
	var frame := 0
	var flip := int(enemy.row) == 1
	if now < float(enemy.attack_until):
		flip = enemy.attack_direction.x < -0.1
		if not enemy.has("strike_remaining") and now < float(enemy.attack_until) - 0.10:
			frame = 2
	elif enemy.moving:
		frame = int(fposmod(float(enemy.walk_distance), 24.0) / 12.0)
	var feet := center + Vector2(0, 30)
	if flip:
		canvas.draw_set_transform_matrix(camera * Transform2D(0.0, Vector2(-1, 1), 0.0, Vector2(feet.x * 2.0, 0.0)))
	var tier := injury_tier(float(enemy.hp), float(enemy.max_hp))
	_pose_frame(canvas, JEJU_MOTION.S11, SIEGE_CELL, frame, tier, feet, tint)
	canvas.draw_set_transform_matrix(camera)


static func _pose_frame(canvas: CanvasItem, texture: Texture2D, cell: Vector2, column: int, row: int, feet: Vector2, tint: Color) -> void:
	var extent := cell * POSE_SCALE
	var anchor := Vector2(extent.x * 0.5, POSE_FOOT * POSE_SCALE)
	canvas.draw_texture_rect_region(texture, Rect2(feet - anchor, extent), Rect2(Vector2(column, row) * cell, cell), tint)


static func _draw_jeju(canvas: CanvasItem, enemy: Dictionary, center: Vector2, now: float, camera: Transform2D, tint: Color) -> void:
	var texture: Texture2D = JEJU_MOTION[enemy.kind]
	var phase := float(enemy.walk_distance) / 28.0
	var continuous: bool = bool(enemy.get("air", false))
	if continuous:
		phase = now * 2.7
	var animation_active: bool = (enemy.moving or continuous) and float(enemy.get("frozen_until", 0.0)) <= now
	var gait := int(fposmod(phase, 1.0) * 8.0) if animation_active else 0
	var facing_left := int(enemy.row) == 1
	var bob := -absf(sin(phase * TAU)) * 0.85 if enemy.moving else 0.0
	if enemy.has("leap_target"):
		var origin: Vector2 = enemy.leap_origin
		var landing: Vector2 = enemy.leap_target
		var progress := origin.distance_to(enemy.pos) / maxf(1.0, origin.distance_to(landing))
		bob -= sin(clampf(progress, 0.0, 1.0) * PI) * 24.0
	var tilt := 0.0
	var stretch := Vector2.ONE
	if enemy.has("pattern_pos"):
		stretch = Vector2(1.03, 1.09)
	elif now < float(enemy.attack_until):
		facing_left = enemy.attack_direction.x < -0.1
		var motion := sin(clampf(1.0 - (float(enemy.attack_until) - now) / ATTACK_TIME, 0.0, 1.0) * PI)
		tilt = motion * 0.16 * (-1.0 if facing_left else 1.0)
		stretch = Vector2(1.0 + motion * 0.07, 1.0 - motion * 0.09)
	elif now < float(enemy.hit_until) - HIT_TIME + RECOIL_TIME:
		var hit_direction: Vector2 = enemy.get("hit_direction", Vector2.ZERO)
		tilt = hit_direction.x * 0.12
		tint = tint.lerp(Color(1.0, 0.59, 0.52, tint.a), 0.32)
	var emergence := smoothstep(0.0, 0.42, now - float(enemy.emerged_at)) if enemy.has("emerged_at") else 1.0
	if facing_left:
		stretch.x *= -1.0
	var feet := center + Vector2(0.0, 30.0 + bob)
	canvas.draw_set_transform_matrix(camera * Transform2D(tilt, stretch, 0.0, feet))
	var cell := Vector2(texture.get_width() / 8.0, 110.0)
	var scale := 82.0 / 90.0
	var tier := injury_tier(float(enemy.hp), float(enemy.max_hp))
	var anchor_y := 99.0
	var source := Rect2(Vector2(gait * cell.x, tier * cell.y), cell)
	if emergence < 1.0:
		anchor_y = ceilf(lerpf(16.0, 99.0, emergence))
		source.size.y = anchor_y
	canvas.draw_texture_rect_region(texture, Rect2(Vector2(-cell.x * 0.5, -anchor_y) * scale, source.size * scale), source, tint)
	canvas.draw_set_transform_matrix(camera)


static func injury_tier(hp: float, max_hp: float) -> int:
	var ratio := hp / maxf(max_hp, 1.0)
	return 2 if ratio <= 0.30 else 1 if ratio <= 0.65 else 0


static func _draw_normal(canvas: CanvasItem, enemy: Dictionary, center: Vector2, now: float, tint: Color) -> void:
	if now < float(enemy.attack_until):
		_draw_attack(canvas, enemy, center, now, tint)
		return
	var row := int(enemy.row)
	if now < float(enemy.hit_until) - HIT_TIME + RECOIL_TIME:
		NormalVisual.frame(canvas, enemy.appearance, 11 + row, center, tint)
		return
	var stride := fposmod(float(enemy.walk_distance) / 30.0, 1.0)
	var column := 39 + row * 4 + int(stride * 4.0) if enemy.moving or row != 0 else int(now * 5.0 + float(enemy.spawn_id)) % 2
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
	var base := 15 + row * 6
	var column := 0 if row == 0 else 39 + row * 4
	if beat >= IMPACT_BEAT and beat < IMPACT_BEAT + 2:
		column = base + (2 if enemy.get("attack_is_bite", false) else 1)
	elif beat > 0 and beat < ATTACK_BEATS - 1 and not enemy.get("attack_is_bite", false):
		column = base
	NormalVisual.frame(canvas, int(enemy.get("appearance", enemy.variant)), column, center, tint)


static func death_facing(enemy: Dictionary, now: float) -> int:
	if now < float(enemy.get("attack_until", 0.0)) and enemy.has("attack_direction"):
		return facing_row(enemy.attack_direction)
	return int(enemy.row)


static func draw_dead(canvas: CanvasItem, corpse: Dictionary, center: Vector2, now: float, camera: Transform2D, zoom: float) -> void:
	var age := clampf((now - float(corpse.start)) / DEATH_TIME, 0.0, 1.0)
	var row := int(corpse.row)
	var fallen := smoothstep(0.0, 0.72, age)
	var sideways := row == 1 or row == 2
	var tilt := (-1.0 if row == 1 else 1.0) * fallen * 1.25 if sideways else 0.0
	var squeeze := lerpf(1.0, 0.30 if sideways else 0.18, fallen)
	var sprite_scale := DRAW_SCALE * float(corpse.scale) / zoom
	var feet := center + Vector2(0.0, (30.0 if JEJU_ENEMIES.has(corpse.kind) else 41.0) * sprite_scale)
	feet += [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP][row] * fallen * 6.0 / zoom
	var tint := Color(1, 1, 1, 1.0 - age)
	if JEJU_ENEMIES.has(corpse.kind):
		var flip := -1.0 if row == 1 and corpse.kind != "S02" else 1.0
		canvas.draw_set_transform_matrix(camera * Transform2D(tilt, Vector2(flip, squeeze) * sprite_scale, 0.0, feet))
		if corpse.kind == "S02":
			_pose_frame(canvas, ARMORED_POSES, ARMORED_CELL, 0, 8 + row, Vector2.ZERO, tint)
		elif corpse.kind == "S11":
			_pose_frame(canvas, JEJU_MOTION.S11, SIEGE_CELL, 0, 2, Vector2.ZERO, tint)
		else:
			var texture: Texture2D = JEJU_ENEMIES[corpse.kind]
			var extent := texture.get_size() * (82.0 / texture.get_height())
			canvas.draw_texture_rect(texture, Rect2(Vector2(-extent.x * 0.5, -extent.y), extent), false, tint)
	else:
		canvas.draw_set_transform_matrix(camera * Transform2D(tilt, Vector2(1.0, squeeze) * sprite_scale, 0.0, feet))
		if corpse.has("appearance"):
			NormalVisual.frame(canvas, corpse.appearance, 39 + row * 4, Vector2(0, -41), tint)
		else:
			_draw_frame(canvas, corpse.variant, row, 4, Vector2(0, -41), tint)
	canvas.draw_set_transform_matrix(camera)


static func _draw_frame(canvas: CanvasItem, variant: int, row: int, column: int, center: Vector2, tint := Color.WHITE) -> void:
	var source := Rect2(Vector2(column, row) * CELL, Vector2.ONE * CELL)
	var destination := Rect2(center - SPRITE_CENTER * SCALE, Vector2.ONE * CELL * SCALE)
	canvas.draw_texture_rect_region(SHEETS[variant], destination, source, tint)
