extends RefCounted
## In-world landing sequence drawn on the real Jeju map, right before control
## is handed to the player:
##   descend → touchdown + dust → operator disembarks → HQ tent is assembled
##   → helicopter lifts off and leaves the screen → finished.
## The helicopter is completely gone before the first controllable frame, so
## the first play frame shows only the military tent HQ (spec requirement).

const HeliArt = preload("res://scripts/reclaim/flow/heli_art.gd")

const T_TOUCHDOWN := 3.0
const T_DISEMBARK := 3.2
const T_WALK_END := 4.4
const T_BUILD_START := 4.0
const T_BUILD_END := 5.0
const T_LIFTOFF := 5.2
const T_END := 7.0

var t := 0.0
var done := false
var lz := Vector2.ZERO
var player_start := Vector2.ZERO
var hq_center := Vector2.ZERO
var exit_dir := Vector2(0.8, -0.6).normalized()
var sfx: Node = null
var _thumped := false
var _build_cues := 0
var operator_line := ""


func setup(landing_zone: Vector2, start_pos: Vector2, hq_world_center: Vector2, sfx_node: Node) -> void:
	t = 0.0
	done = false
	lz = landing_zone
	player_start = start_pos
	hq_center = hq_world_center
	sfx = sfx_node
	_thumped = false
	_build_cues = 0


func skip() -> void:
	t = T_END
	done = true
	if sfx: sfx.set_rotor(0.0)


func update(delta: float) -> void:
	if done:
		return
	t += delta
	if not _thumped and t >= T_TOUCHDOWN:
		_thumped = true
		if sfx: sfx.play("thump", -2.0)
	if t >= lerpf(T_BUILD_START, T_BUILD_END, float(_build_cues) / 3.0) and _build_cues < 3:
		_build_cues += 1
		if sfx: sfx.play("build", -6.0, 1.0 + 0.06 * _build_cues)
	if sfx:
		var level := 1.0
		if t > T_LIFTOFF: level = clampf(1.0 - (t - T_LIFTOFF) / (T_END - T_LIFTOFF), 0.0, 1.0)
		elif t > T_TOUCHDOWN: level = 0.65
		sfx.set_rotor(level, 1.0 if t < T_TOUCHDOWN else 0.92)
	if t >= T_END:
		done = true
		if sfx: sfx.set_rotor(0.0)


func altitude() -> float:
	if t < T_TOUCHDOWN:
		return lerpf(1.6, 0.0, ease(t / T_TOUCHDOWN, 0.45))
	if t < T_LIFTOFF:
		return 0.0
	return lerpf(0.0, 1.8, clampf((t - T_LIFTOFF) / 1.6, 0.0, 1.0))


func heli_world() -> Vector2:
	if t < T_TOUCHDOWN:
		return lz + Vector2(-230, -145) * pow(1.0 - t / T_TOUCHDOWN, 2.0)
	if t < T_LIFTOFF:
		return lz
	var k := clampf((t - T_LIFTOFF) / (T_END - T_LIFTOFF), 0.0, 1.0)
	return lz + exit_dir * (k * k * 1000.0)


func heli_visible() -> bool:
	return not done


func player_visible() -> bool:
	return t >= T_DISEMBARK


## Camera/player position while the cut plays (camera follows player_pos).
func player_world() -> Vector2:
	var door := lz + Vector2(0, 26)
	if t < T_DISEMBARK:
		return door
	var k := clampf((t - T_DISEMBARK) / (T_WALK_END - T_DISEMBARK), 0.0, 1.0)
	return door.lerp(player_start, k)


func player_moving() -> bool:
	return t >= T_DISEMBARK and t < T_WALK_END


func hq_ratio() -> float:
	return clampf((t - T_BUILD_START) / (T_BUILD_END - T_BUILD_START), 0.0, 1.0) if t >= T_BUILD_START - 0.6 else -1.0


func caption() -> String:
	if t < T_TOUCHDOWN: return "LZ ALPHA 하강 중 · 착륙 지점 확보"
	if t < T_BUILD_START: return operator_line if not operator_line.is_empty() else "착륙 완료 · 대원 하차"
	if t < T_BUILD_END: return "지휘본부 군용 텐트 설치 중  %d%%" % int(hq_ratio() * 100.0)
	return "헬기 이탈 · 작전 개시 준비"


func draw(c: CanvasItem, to_screen: Callable) -> void:
	if done:
		return
	var alt := altitude()
	var hp: Vector2 = to_screen.call(heli_world())
	var wash := clampf(1.0 - alt / 0.8, 0.0, 1.0)
	if wash > 0.0:
		HeliArt.draw_clip(c, "wind", t, hp + Vector2(0, 15), Vector2(300, 190), wash * 0.65)
		HeliArt.draw_clip(c, "dust", t - T_TOUCHDOWN, hp + Vector2(0, 28), Vector2.ONE * 360.0, wash)
	c.draw_set_transform(hp + Vector2(0, 13), 0.0, Vector2(1.0, 0.34))
	c.draw_circle(Vector2.ZERO, 94.0 + alt * 17.0, Color(0, 0, 0, 0.31 - alt * 0.10))
	c.draw_set_transform(Vector2.ZERO)
	HeliArt.draw_clip(c, "quarter", t, hp + Vector2(0, -94.0 - alt * 110.0), Vector2.ONE * 310.0)


func draw_overlay(c: CanvasItem, view: Vector2) -> void:
	if done:
		return
	var bar := view.y * 0.08
	c.draw_rect(Rect2(0, 0, view.x, bar), Color(0, 0, 0, 0.85))
	c.draw_rect(Rect2(0, view.y - bar, view.x, bar), Color(0, 0, 0, 0.85))
	var font := ThemeDB.fallback_font
	c.draw_string(font, Vector2(0, view.y - bar * 0.38), caption(), HORIZONTAL_ALIGNMENT_CENTER, view.x, 20, Color(1, 0.92, 0.86))
	c.draw_string(font, Vector2(0, bar * 0.62), "Esc / Space 건너뛰기", HORIZONTAL_ALIGNMENT_RIGHT, view.x - 24, 14, Color(0.8, 0.72, 0.76))


## Stage-by-stage HQ tent assembly (crates → frame → canvas → antenna).
