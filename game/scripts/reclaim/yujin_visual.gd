extends RefCounted

const Elements = preload("res://scripts/reclaim/element_visual.gd")

const NORTH_ATTACK := preload("res://assets/characters/yujin/north_attack.png")
const OperatorRun = preload("res://scripts/reclaim/operator_run.gd")
const NEW_FRAME := Vector2(128, 152)
const NEW_ORIGIN := Vector2(-64, -86)
const NORTH_TIPS := [Vector2(0, -68), Vector2(0, -67), Vector2(-1, -78), Vector2(0, -71)]
const FRONT_ATTACK = preload("res://assets/characters/yujin/yujin_front_attack.png")
const FRONT_FRAME_SIZE := Vector2(112, 132)
const FRONT_FOOT_ANCHOR := Vector2(56, 92)
const BACK = preload("res://assets/characters/yujin/up.png")
const IDLE := [
	preload("res://assets/characters/yujin/idle0.png"),
	preload("res://assets/characters/yujin/idle1.png"),
	preload("res://assets/characters/yujin/idle2.png"),
	preload("res://assets/characters/yujin/idle3.png"),
]
const CUT := [
	preload("res://assets/characters/yujin/cut0.png"),
	preload("res://assets/characters/yujin/cut1.png"),
	preload("res://assets/characters/yujin/cut2.png"),
	preload("res://assets/characters/yujin/cut3.png"),
	preload("res://assets/characters/yujin/cut4.png"),
	preload("res://assets/characters/yujin/cut5.png"),
	preload("res://assets/characters/yujin/cut6.png"),
]

# Match the occupied idle-frame heights and foot baseline of Harin's
# 96 px atlas cells. These source textures are cropped to the artwork.
const SIDE_HEIGHT := 80.0
const BACK_HEIGHT := 83.0
const FOOT_OFFSET := 40.0

const CUT_CYCLE := 7.0 / 13.0

var _attack_left := 0.0
var _attack_pose_left := 0.0
var _attack_facing := Vector2.DOWN
var _cut_clock := 0.0
var _clock := 0.0
var _walk_distance := 0.0


func update(delta: float, motion := Vector2.ZERO) -> void:
	_clock += delta
	_attack_pose_left = maxf(0.0, _attack_pose_left - delta)
	var speed := motion.length()
	_walk_distance = _walk_distance + minf(speed, 380.0) * delta if speed > 6.0 else 0.0
	if _attack_left > 0.0:
		_cut_clock += delta
	_attack_left = maxf(0.0, _attack_left - delta)


func attack(interval: float, facing: Vector2) -> void:
	_attack_facing = facing
	_attack_pose_left = minf(0.085, interval * 0.55)
	if _attack_left <= 0.0:
		_cut_clock = 0.0
	_attack_left = maxf(interval + 0.05, CUT_CYCLE - fposmod(_cut_clock, CUT_CYCLE))


func reset() -> void:
	_attack_left = 0.0
	_attack_pose_left = 0.0
	_clock = 0.0
	_walk_distance = 0.0
	_cut_clock = 0.0


func draw(canvas: CanvasItem, position: Vector2, facing: Vector2, motion: Vector2, dashing: bool, echo := 0.0, element_mask := 0, time := 0.0) -> void:
	var running := motion.length_squared() > 36.0
	var attacking := echo == 0.0 and _attack_left > 0.0 and (not running or _attack_pose_left > 0.0)
	facing = _attack_facing if attacking else motion if running else facing
	var tint := Color(0.33, 0.27, 0.51, echo) if echo > 0.0 else Color.WHITE
	var progress := fposmod(_cut_clock / CUT_CYCLE, 1.0) if attacking else 0.0
	var side := absf(facing.x) > absf(facing.y)
	var back := not side and facing.y < 0.0
	var center := position + Vector2(0.0, FOOT_OFFSET)
	var lean := facing * (sin(progress * PI) * 4.0) if attacking else Vector2.ZERO
	if dashing:
		canvas.draw_circle(position, 24.0, Color("#739de33b"))
	canvas.draw_set_transform(position + Vector2(0.0, FOOT_OFFSET - 2.0), 0.0, Vector2(1.0, 0.35))
	if echo == 0.0:
		canvas.draw_circle(Vector2.ZERO, 16.0, Color("#00000062"))
	canvas.draw_set_transform(Vector2.ZERO)
	if running and not attacking:
		OperatorRun.draw(canvas, position, "yujin", motion, _walk_distance, tint)
		return
	if not side and not back:
		var front_frame := _front_cut_frame(progress) if attacking else 0
		var target := center.round() - FRONT_FOOT_ANCHOR
		canvas.draw_texture_rect_region(FRONT_ATTACK, Rect2(target, FRONT_FRAME_SIZE), Rect2(Vector2(front_frame * FRONT_FRAME_SIZE.x, 0), FRONT_FRAME_SIZE), tint)
		if attacking and element_mask != 0:
			_draw_element(canvas, position + Vector2(0, 53), Vector2.DOWN, element_mask, time)
		return
	if back and attacking:
		var north_frame := clampi(int(progress * 4.0), 0, 3)
		canvas.draw_texture_rect_region(NORTH_ATTACK, Rect2(position.round() + NEW_ORIGIN, NEW_FRAME),
			Rect2(Vector2(north_frame * NEW_FRAME.x, 0), NEW_FRAME), tint)
		if element_mask != 0:
			_draw_element(canvas, position + NORTH_TIPS[north_frame], Vector2.UP, element_mask, time)
		if north_frame == 1 or north_frame == 2:
			_draw_north_sparks(canvas, position + NORTH_TIPS[north_frame], progress)
		return
	var frames := CUT if attacking else IDLE
	var frame := int(progress * frames.size()) if attacking else int(_clock * 4.0) % frames.size()
	var sprite: Texture2D = BACK if back else frames[frame]
	var height := BACK_HEIGHT if back else SIDE_HEIGHT
	var size := sprite.get_size() * (height / sprite.get_height())
	var sprite_scale := Vector2(-1, 1) if side and facing.x < 0.0 else Vector2.ONE
	canvas.draw_set_transform((center + lean).round(), 0.0, sprite_scale)
	var anchor_x := size.x * 0.33 if side else size.x * 0.5
	canvas.draw_texture_rect(sprite, Rect2(Vector2(-anchor_x, -size.y), size), false, tint)
	canvas.draw_set_transform(Vector2.ZERO)
	if attacking and element_mask != 0:
		var edge := Vector2(signf(facing.x) * 46.0, 13.0)
		_draw_element(canvas, position + lean + edge, facing.normalized(), element_mask, time)


func _draw_element(canvas: CanvasItem, tip: Vector2, direction: Vector2, mask: int, time: float) -> void:
	Elements.trail(canvas, tip - direction * 22.0, tip, mask, time)


func _front_cut_frame(progress: float) -> int:
	return 1 + clampi(int(progress * 5.0), 0, 4)


func _draw_north_sparks(canvas: CanvasItem, tip: Vector2, progress: float) -> void:
	for index in range(5):
		var angle := lerpf(-0.95, 0.95, float(index) / 4.0)
		var direction := Vector2.UP.rotated(angle)
		var reach := 5.0 + fposmod(progress * 21.0 + float(index) * 2.3, 7.0)
		var spark := tip + direction * reach
		canvas.draw_line(spark, spark + direction * 3.0, Color("#ffc774"), 1.5)
