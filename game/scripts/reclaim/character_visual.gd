extends RefCounted

const SHEET: Texture2D = preload("res://assets/reclaim/characters/harin_sheet.png")
const CELL_SIZE := 96.0
const DRAW_SIZE := 96.0
const WALK_FPS := 7.0
const ATTACK_HOLD := 0.16
const HURT_HOLD := 0.22

var walk_clock := 0.0
var attack_timer := 0.0
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


func trigger_attack() -> void:
	attack_timer = ATTACK_HOLD


func draw(canvas: CanvasItem, center: Vector2, facing: Vector2, moving: bool, dashing: bool, drone_level: int, reload_progress: float) -> void:
	var row := _facing_row(facing)
	var column := 0
	if attack_timer > 0.0:
		var progress := 1.0 - attack_timer / ATTACK_HOLD
		column = 5 + clampi(int(progress * 4.0), 0, 3)
	elif reload_progress >= 0.0:
		column = 9 + clampi(int(reload_progress * 4.0), 0, 3)
	elif moving or dashing:
		var fps := WALK_FPS * 1.8 if dashing else WALK_FPS
		column = 1 + (int(walk_clock * fps) % 4)
	var source := Rect2(float(column) * CELL_SIZE, float(row) * CELL_SIZE, CELL_SIZE, CELL_SIZE)
	var destination := Rect2(center - Vector2(DRAW_SIZE, DRAW_SIZE) * 0.5, Vector2(DRAW_SIZE, DRAW_SIZE))
	var tint := Color(1.0, 0.72, 0.72) if hurt_timer > 0.0 else Color.WHITE
	canvas.draw_texture_rect_region(SHEET, destination, source, tint)
	if dashing:
		canvas.draw_line(center - facing.normalized() * 27.0, center - facing.normalized() * 11.0, Color("#9dd9e6", 0.7), 2.0)
	if drone_level > 0:
		_draw_support_drone(canvas, center, drone_level)


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
