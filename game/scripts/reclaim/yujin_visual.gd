extends RefCounted

const FRONT_ATTACK = preload("res://assets/characters/yujin/yujin_front_attack.png")
const FRONT_FRAME_SIZE := Vector2(112, 132)
const FRONT_FOOT_ANCHOR := Vector2(56, 92)
const BACK = preload("res://assets/characters/yujin/up.png")
const SAW = preload("res://assets/characters/yujin/weapon.png")
const IDLE := [
	preload("res://assets/characters/yujin/idle0.png"),
	preload("res://assets/characters/yujin/idle1.png"),
	preload("res://assets/characters/yujin/idle2.png"),
	preload("res://assets/characters/yujin/idle3.png"),
]
const WALK := [
	preload("res://assets/characters/yujin/walk0.png"),
	preload("res://assets/characters/yujin/walk1.png"),
	preload("res://assets/characters/yujin/walk2.png"),
	preload("res://assets/characters/yujin/walk3.png"),
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
var _cut_clock := 0.0
var _clock := 0.0
var _walk_distance := 0.0


func update(delta: float, motion := Vector2.ZERO) -> void:
	_clock += delta
	var speed := motion.length()
	_walk_distance = _walk_distance + minf(speed, 380.0) * delta if speed > 6.0 else 0.0
	if _attack_left > 0.0:
		_cut_clock += delta
	_attack_left = maxf(0.0, _attack_left - delta)


func attack(interval: float) -> void:
	if _attack_left <= 0.0:
		_cut_clock = 0.0
	_attack_left = maxf(interval + 0.05, CUT_CYCLE - fposmod(_cut_clock, CUT_CYCLE))


func reset() -> void:
	_attack_left = 0.0
	_clock = 0.0
	_walk_distance = 0.0
	_cut_clock = 0.0


func draw(canvas: CanvasItem, position: Vector2, facing: Vector2, moving: bool, dashing: bool) -> void:
	var attacking := _attack_left > 0.0
	var progress := fposmod(_cut_clock / CUT_CYCLE, 1.0) if attacking else 0.0
	var side := absf(facing.x) > absf(facing.y)
	var back := not side and facing.y < 0.0
	var running := moving or dashing
	var stride := _walk_distance / 22.0
	var bob := -roundf(2.0 * absf(sin(stride * PI * 0.5))) if running and not attacking else 0.0
	var center := position + Vector2(0.0, FOOT_OFFSET + bob)
	var lean := facing * (sin(progress * PI) * 4.0) if attacking else Vector2.ZERO
	if dashing:
		canvas.draw_circle(position, 24.0, Color("#739de33b"))
	canvas.draw_set_transform(position + Vector2(0.0, FOOT_OFFSET - 2.0), 0.0, Vector2(1.0, 0.35))
	canvas.draw_circle(Vector2.ZERO, 16.0, Color("#00000062"))
	canvas.draw_set_transform(Vector2.ZERO)
	if not side and not back:
		var front_frame := _front_cut_frame(progress) if attacking else 0
		var target := center.round() - FRONT_FOOT_ANCHOR
		canvas.draw_texture_rect_region(FRONT_ATTACK, Rect2(target, FRONT_FRAME_SIZE), Rect2(Vector2(front_frame * FRONT_FRAME_SIZE.x, 0), FRONT_FRAME_SIZE))
		return
	if back:
		_draw_saw(canvas, center + lean, facing, progress)
	var frames := CUT if attacking else WALK if running else IDLE
	var frame := int(progress * frames.size()) if attacking else int(stride) % frames.size() if running else int(_clock * 4.0) % frames.size()
	var sprite: Texture2D = BACK if back else frames[frame]
	var height := BACK_HEIGHT if back else SIDE_HEIGHT
	var size := sprite.get_size() * (height / sprite.get_height())
	var sprite_scale := Vector2(-1, 1) if side and facing.x < 0.0 else Vector2.ONE
	canvas.draw_set_transform((center + lean).round(), 0.0, sprite_scale)
	var anchor_x := size.x * 0.33 if side else size.x * 0.5
	canvas.draw_texture_rect(sprite, Rect2(Vector2(-anchor_x, -size.y), size), false)
	canvas.draw_set_transform(Vector2.ZERO)


func _front_cut_frame(progress: float) -> int:
	return 1 + clampi(int(progress * 5.0), 0, 4)


func _draw_saw(canvas: CanvasItem, center: Vector2, direction: Vector2, progress: float) -> void:
	var angle := direction.angle() + deg_to_rad(27.0)
	angle += sin(progress * TAU) * 0.14
	var grip := Vector2(13.0, -32.0)
	canvas.draw_set_transform((center + grip).round(), angle)
	canvas.draw_texture_rect(SAW, Rect2(-18.0, -23.0, 66.0, 43.0), false)
	canvas.draw_set_transform(Vector2.ZERO)
