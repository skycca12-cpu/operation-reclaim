extends RefCounted

const FRONT = preload("res://assets/characters/yujin/down.png")
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
const FRONT_HEIGHT := 86.0
const SIDE_HEIGHT := 80.0
const BACK_HEIGHT := 83.0
const FOOT_OFFSET := 40.0

var _attack_left := 0.0
var _cut_clock := 0.0
var _clock := 0.0


func update(delta: float) -> void:
	_clock += delta
	if _attack_left > 0.0:
		_cut_clock += delta
	_attack_left = maxf(0.0, _attack_left - delta)


func attack(interval: float) -> void:
	if _attack_left <= 0.0:
		_cut_clock = 0.0
	_attack_left = interval + 0.05


func reset() -> void:
	_attack_left = 0.0
	_clock = 0.0


func draw(canvas: CanvasItem, position: Vector2, facing: Vector2, moving: bool, dashing: bool) -> void:
	var attacking := _attack_left > 0.0
	var progress := fposmod(_cut_clock * 13.0 / CUT.size(), 1.0) if attacking else 0.0
	var side := absf(facing.x) > absf(facing.y)
	var back := not side and facing.y < 0.0
	var frames := CUT if attacking else WALK if moving else IDLE
	var frame := mini(int(progress * frames.size()), frames.size() - 1) if attacking else int(_clock * (9.0 if moving else 4.0)) % frames.size()
	var sprite: Texture2D = frames[frame] if side else BACK if back else FRONT
	var bob := -1.5 * absf(sin(_clock * 16.0)) if moving and not side else 0.0
	var height := SIDE_HEIGHT if side else BACK_HEIGHT if back else FRONT_HEIGHT
	var size := sprite.get_size() * (height / sprite.get_height())
	var center := position + Vector2(0.0, FOOT_OFFSET + bob)
	var lean := facing * (sin(progress * PI) * 3.0) if attacking else Vector2.ZERO
	if dashing:
		canvas.draw_circle(position, 24.0, Color("#739de33b"))
	canvas.draw_set_transform(position + Vector2(0.0, FOOT_OFFSET - 2.0), 0.0, Vector2(1.0, 0.35))
	canvas.draw_circle(Vector2.ZERO, 16.0, Color("#00000062"))
	canvas.draw_set_transform(Vector2.ZERO)
	if back:
		_draw_saw(canvas, center + lean, facing, progress)
	var sprite_scale := Vector2(-1, 1) if side and facing.x < 0.0 else Vector2.ONE
	canvas.draw_set_transform((center + lean).round(), 0.0, sprite_scale)
	var anchor_x := size.x * 0.33 if side else size.x * 0.5
	canvas.draw_texture_rect(sprite, Rect2(Vector2(-anchor_x, -size.y), size), false)
	canvas.draw_set_transform(Vector2.ZERO)
	if not side and not back:
		_draw_saw(canvas, center + lean, facing, progress)


func _draw_saw(canvas: CanvasItem, center: Vector2, direction: Vector2, progress: float) -> void:
	var angle := direction.angle() + deg_to_rad(27.0)
	angle += sin(progress * TAU) * 0.14
	var grip := Vector2(18.0, -23.0) if direction.y > 0.0 else Vector2(13.0, -32.0)
	canvas.draw_set_transform((center + grip).round(), angle)
	canvas.draw_texture_rect(SAW, Rect2(-18.0, -23.0, 66.0, 43.0), false)
	canvas.draw_set_transform(Vector2.ZERO)
