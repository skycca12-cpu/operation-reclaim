extends RefCounted

const FRONT = preload("res://assets/characters/yujin/down.png")
const BACK = preload("res://assets/characters/yujin/up.png")
const FRONT_SAW = preload("res://assets/characters/yujin/front_saw.png")
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
var _run_clock := 0.0


func update(delta: float, moving := false) -> void:
	_clock += delta
	_run_clock = _run_clock + delta if moving else 0.0
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
	_run_clock = 0.0


func draw(canvas: CanvasItem, position: Vector2, facing: Vector2, moving: bool, dashing: bool) -> void:
	var attacking := _attack_left > 0.0
	var progress := fposmod(_cut_clock * 13.0 / CUT.size(), 1.0) if attacking else 0.0
	var side := absf(facing.x) > absf(facing.y)
	var back := not side and facing.y < 0.0
	var running := moving or dashing
	var stride := _run_clock * (15.0 if dashing else 11.0)
	var frames := WALK if running else CUT if attacking else IDLE
	var frame := int(stride) % frames.size() if running else int(progress * frames.size()) if attacking else int(_clock * 4.0) % frames.size()
	var sprite: Texture2D = frames[frame] if side else BACK if back else FRONT
	var bob := -roundf(5.0 * absf(sin(stride * PI * 0.5))) if running else 0.0
	var height := SIDE_HEIGHT if side else BACK_HEIGHT if back else FRONT_HEIGHT
	var size := sprite.get_size() * (height / sprite.get_height())
	var center := position + Vector2(0.0, FOOT_OFFSET + bob)
	var lean := facing * (sin(progress * PI) * 4.0) if attacking else Vector2.ZERO
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
		_draw_front_cut(canvas, center + lean, progress)


func _draw_front_cut(canvas: CanvasItem, center: Vector2, progress: float) -> void:
	const TIP_DISTANCE := 51.0
	var grip := (center + Vector2(0.0, -34.0)).round()
	var tilt := _front_cut_tilt(progress)
	if progress > 0.22 and progress < 0.79:
		var points := PackedVector2Array()
		for i in range(10):
			var sample := maxf(0.0, progress - 0.24 * (1.0 - float(i) / 9.0))
			points.append(grip + Vector2.DOWN.rotated(_front_cut_tilt(sample)) * TIP_DISTANCE)
		var opacity := sin(inverse_lerp(0.22, 0.79, progress) * PI)
		canvas.draw_polyline(points, Color(0.74, 0.16, 0.13, opacity * 0.8), 5.0, true)
		canvas.draw_polyline(points, Color(1.0, 0.58, 0.43, opacity * 0.9), 2.0, true)
	canvas.draw_set_transform(grip, tilt)
	canvas.draw_texture_rect(FRONT_SAW, Rect2(-17.0, -4.0, 34.0, 56.0), false)
	canvas.draw_set_transform(Vector2.ZERO)


func _front_cut_tilt(progress: float) -> float:
	# Hold the blade straight, cock it right, sweep left, then settle.
	if progress < 0.22:
		return -0.27 * smoothstep(0.06, 0.22, progress)
	if progress < 0.60:
		return lerpf(-0.27, 0.30, smoothstep(0.22, 0.60, progress))
	return 0.30 * (1.0 - smoothstep(0.60, 0.94, progress))


func _draw_saw(canvas: CanvasItem, center: Vector2, direction: Vector2, progress: float) -> void:
	var angle := direction.angle() + deg_to_rad(27.0)
	angle += sin(progress * TAU) * 0.14
	var grip := Vector2(13.0, -32.0)
	canvas.draw_set_transform((center + grip).round(), angle)
	canvas.draw_texture_rect(SAW, Rect2(-18.0, -23.0, 66.0, 43.0), false)
	canvas.draw_set_transform(Vector2.ZERO)
