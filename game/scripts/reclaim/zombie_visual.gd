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


static func draw_alive(canvas: CanvasItem, enemy: Dictionary, center: Vector2, now: float) -> void:
	var phase := now + float(int(enemy.spawn_id) % 31) * 0.063
	var moving: bool = enemy.moving
	var column := 4 + int(phase * 9.0) % 8 if moving else int(phase * 5.0) % 4
	if now < float(enemy.hit_until):
		column = 18 + clampi(int((now + HIT_TIME - float(enemy.hit_until)) * 10.0), 0, 3)
	elif now < float(enemy.attack_until):
		column = 12 + clampi(int((now + ATTACK_TIME - float(enemy.attack_until)) * 10.0), 0, 5)
	_draw_frame(canvas, enemy.variant, enemy.row, column, center)


static func draw_dead(canvas: CanvasItem, corpse: Dictionary, center: Vector2, now: float) -> void:
	var frame := clampi(int((now - float(corpse.start)) * DEATH_FPS), 0, DEATH_FRAMES - 1)
	_draw_frame(canvas, corpse.variant, corpse.row, 22 + frame, center)


static func _draw_frame(canvas: CanvasItem, variant: int, row: int, column: int, center: Vector2) -> void:
	var source := Rect2(Vector2(column, row) * CELL, Vector2.ONE * CELL)
	var destination := Rect2(center - Vector2(80.0, 86.0) * SCALE, Vector2.ONE * CELL * SCALE)
	canvas.draw_texture_rect_region(SHEETS[variant], destination, source)
